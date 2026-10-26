import { mkdir, readFile, writeFile, cp, rm } from 'node:fs/promises';
import { join } from 'node:path';
import { loadTrips, writePublic } from '../services/trips/hub.mjs';
import { readPassword } from './private-trip.mjs';
import { envs, root, run, sha, validImage, state, refresh, installHostTimer } from './trips-host.mjs';

async function build(){
  if(run('git',['status','--porcelain']))throw Error('dirty_worktree');
  run('npm',['test']);run('npm',['run','test:hub']);run('npm',['audit','--audit-level=high']);
  const commit=run('git',['rev-parse','HEAD']);
  const image=(await readFile(join(root,'outputs/private-trip/private-image.txt'),'utf8')).trim();
  if(!validImage(image))throw Error('invalid_image');
  const directory=join(root,'outputs/private-trip/hub-releases',commit);
  await rm(directory,{recursive:true,force:true});await mkdir(join(directory,'bundle/pages'),{recursive:true});
  const trips=await loadTrips(join(root,'services/trips/pages'),readPassword());
  const files=await writePublic(join(directory,'bundle/public'),trips);
  for(const trip of trips)await writeFile(join(directory,'bundle/pages',trip.slug+'.html'),trip.encrypted);
  const manifest={format:1,commit,image,files};
  await writeFile(join(directory,'bundle/manifest.json'),JSON.stringify(manifest,null,2)+'\n');
  run('tar',['--sort=name','--mtime=@0','--owner=0','--group=0','--numeric-owner','-czf',join(directory,'artifact.tar.gz'),'-C',directory,'bundle']);
  const artifact=sha(await readFile(join(directory,'artifact.tar.gz')));
  await writeFile(join(root,'outputs/private-trip/hub-release.json'),JSON.stringify({...manifest,artifact,directory},null,2));
  console.log(JSON.stringify({event:'trips_release_built',commit,artifact,image}));
}
async function deploy(environment){
  if(!envs[environment])throw Error('invalid_environment');
  if(run('git',['status','--porcelain']))throw Error('dirty_worktree');
  if(JSON.parse(run('aws',['sts','get-caller-identity'])).Account!=='062008221187')throw Error('wrong_account');
  const release=JSON.parse(await readFile(join(root,'outputs/private-trip/hub-release.json'),'utf8'));
  if(sha(await readFile(join(release.directory,'artifact.tar.gz')))!==release.artifact)throw Error('artifact_mismatch');
  if(environment==='production'){
    const approval=JSON.parse(await readFile(process.argv[4],'utf8'));
    const tagCommit=run('git',['rev-list','-n','1',approval.releaseTag]);
    if(approval.artifact!==release.artifact||approval.target!=='trips.robertboscacci.com'||tagCommit!==release.commit||!approval.approvedBy||!approval.approvalUrl)throw Error('production_approval_required');
    const dev=JSON.parse(run('aws',['s3','cp',`s3://robertboscacci-com-trips-dev-062008221187/releases/${release.artifact}/verified.json`,'-']));
    if(dev.artifact!==release.artifact||dev.commit!==release.commit)throw Error('dev_verification_required');
  }else if(run('git',['rev-parse','HEAD'])!==release.commit)throw Error('wrong_commit');
  const infra=JSON.parse(run('tofu',['-chdir=infra/trips','output','-json','environments']))[environment];
  if(infra.host!==envs[environment].host||infra.bucket!==`robertboscacci-com-trips-${environment}-062008221187`)throw Error('wrong_target');
  // Deploy only freshly extracted bytes from the immutable archive, never a
  // mutable staging directory beside it.
  const saved=join(state,'releases',release.artifact);await mkdir(saved,{recursive:true,mode:0o700});
  await cp(join(release.directory,'artifact.tar.gz'),join(saved,'artifact.tar.gz'));
  const entries=run('tar',['-tzf',join(saved,'artifact.tar.gz')]).split('\n');
  if(entries.some(name=>!/^bundle\/(?:manifest\.json|pages\/(?:[a-z0-9-]+\.html)?|public\/(?:robots\.txt|404\.html|[a-z0-9-]+\/(?:index\.html)?)?)?$/.test(name)))throw Error('invalid_archive');
  run('tar',['--extract','--gzip','--no-same-owner','--file',join(saved,'artifact.tar.gz'),'--directory',saved]);
  const extracted=JSON.parse(await readFile(join(saved,'bundle/manifest.json'),'utf8'));
  if(extracted.commit!==release.commit||extracted.image!==release.image)throw Error('manifest_mismatch');
  run('aws',['s3','cp',join(release.directory,'artifact.tar.gz'),`s3://${infra.bucket}/releases/${release.artifact}/artifact.tar.gz`,'--region','us-west-2','--metadata',`sha256=${release.artifact},commit=${release.commit}`]);
  run('aws',['s3','sync',join(saved,'bundle/public'),`s3://${infra.bucket}/public/`,'--delete','--cache-control','no-store','--region','us-west-2']);
  run('aws',['cloudfront','create-invalidation','--distribution-id',infra.distribution,'--paths','/*']);
  await mkdir(join(state,environment),{recursive:true,mode:0o700});
  const record={environment,commit:release.commit,artifact:release.artifact,image:release.image};
  await writeFile(join(state,environment,'deployment.json'),JSON.stringify(record),{mode:0o600});
  await refresh();await installHostTimer();
  for(let i=0;i<36;i++){
    try{run('curl',['-fsS','--max-time','5','--resolve',`${infra.host}:${envs[environment].port}:127.0.0.1`,`https://${infra.host}:${envs[environment].port}/healthz`]);break;}catch{if(i===35)throw Error('private_tls_unavailable');await new Promise(r=>setTimeout(r,3000));}
  }
  const rc=join(root,'../rc');
  if(run('git',['-C',rc,'remote','get-url','origin'])!=='git@github.com:boscacci/rc.git'||run('git',['-C',rc,'status','--porcelain']))throw Error('network_checkout_not_clean');
  if(environment==='dev')run('bash',[join(rc,'optiplex/front-door/activate-trips.sh')]);
  run('node',[join(rc,'optiplex/front-door/configure-trips-dns.mjs'),'--apply',...(environment==='production'?['--production']:[])],{cwd:rc});
  run('node',['tests/trips/browser.mjs',environment]);
  const verified={...record,verifiedAt:new Date().toISOString(),url:`https://${infra.host}/`};
  const file=join(release.directory,`${environment}-verified.json`);await writeFile(file,JSON.stringify(verified,null,2));
  run('aws',['s3','cp',file,`s3://${infra.bucket}/releases/${release.artifact}/verified.json`,'--region','us-west-2']);
  console.log(JSON.stringify({event:'trips_deployed_verified',...verified}));
}
try{
  const[command,environment]=process.argv.slice(2);
  if(command==='build')await build();else if(command==='deploy')await deploy(environment);else throw Error('usage_build_or_deploy');
}catch(error){console.error(JSON.stringify({event:'trips_release_failed',reason:/^[a-z_]+$/.test(error.message)?error.message:'command_failed',action:'Inspect validation and infrastructure state; retry the same immutable artifact. Do not print secrets.'}));process.exitCode=1;}
