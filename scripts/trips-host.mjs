import { execFileSync } from 'node:child_process';
import { mkdir, readFile, writeFile, readdir, symlink, rename, rm } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { loadTrips, writePrivate } from '../services/trips/hub.mjs';
import { readPassword } from './private-trip.mjs';

export const root=fileURLToPath(new URL('../',import.meta.url));
export const state=join(homedir(),'.local/share/trips');
export const runtime=join(process.env.XDG_RUNTIME_DIR||`/run/user/${process.getuid()}`,'trips');
export const envs={dev:{host:'trips-dev.robertboscacci.com',port:9451,health:19451},production:{host:'trips.robertboscacci.com',port:9450,health:19450}};
export const run=(command,args,options={})=>execFileSync(command,args,{cwd:root,encoding:'utf8',timeout:180000,stdio:['ignore','pipe','pipe'],...options}).trim();
export const sha=(bytes)=>createHash('sha256').update(bytes).digest('hex');
export function validImage(image){return /^062008221187\.dkr\.ecr\.us-west-2\.amazonaws\.com\/robertboscacci-trips-private@sha256:[0-9a-f]{64}$/.test(image);}

async function credentials(){
  await mkdir(join(runtime,'aws'),{recursive:true,mode:0o700});
  const result=JSON.parse(run('aws',['sts','assume-role','--role-arn','arn:aws:iam::062008221187:role/robertboscacci-trips-certificates','--role-session-name','trips-certificates','--duration-seconds','3600']));
  const c=result.Credentials;
  const file=join(runtime,'aws/credentials');
  await writeFile(file+'.tmp',`[trips-dns]\naws_access_key_id=${c.AccessKeyId}\naws_secret_access_key=${c.SecretAccessKey}\naws_session_token=${c.SessionToken}\n`,{mode:0o600});
  await rename(file+'.tmp',file);
}
async function start(env,record){
  if(!envs[env]||!validImage(record.image)||!/^[a-f0-9]{64}$/.test(record.artifact))throw Error('invalid_release');
  const local=join(state,'releases',record.artifact);
  if(sha(await readFile(join(local,'artifact.tar.gz')))!==record.artifact)throw Error('artifact_mismatch');
  const manifest=JSON.parse(await readFile(join(local,'bundle/manifest.json'),'utf8'));
  if(manifest.image!==record.image||manifest.commit!==record.commit)throw Error('manifest_mismatch');
  for(const[file,hash]of Object.entries(manifest.files))if(sha(await readFile(join(local,'bundle/public',file)))!==hash)throw Error('file_mismatch');
  const trips=await loadTrips(join(local,'bundle/pages'),readPassword());
  for(const trip of trips)if(manifest.files[`${trip.slug}/index.html`]!==sha(trip.encrypted))throw Error('private_public_mismatch');
  const runtimeSite=join(runtime,env,'site');
  await mkdir(runtimeSite,{recursive:true,mode:0o700});
  await writePrivate(join(runtimeSite,record.artifact),trips);
  await rm(join(runtimeSite,'next'),{force:true});
  await symlink(record.artifact,join(runtimeSite,'next'));
  await rename(join(runtimeSite,'next'),join(runtimeSite,'current'));
  for(const dir of await readdir(runtimeSite))if(![record.artifact,'current'].includes(dir))await rm(join(runtimeSite,dir),{recursive:true,force:true});
  for(const dir of ['caddy-data','caddy-config'])await mkdir(join(state,env,dir),{recursive:true,mode:0o700});
  const cfg=envs[env];
  let present=false;
  try{present=run('docker',['inspect',`trips-${env}-private`,'--format','{{.Config.Image}} {{.State.Running}}'])===record.image+' true';}catch{}
  if(!present){
    const auth=join(runtime,'docker-auth');await mkdir(auth,{recursive:true,mode:0o700});
    const dockerEnv={...process.env,DOCKER_CONFIG:auth,TRIPS_IMAGE:record.image,TRIPS_ENV:env,TRIPS_HOST:cfg.host,TRIPS_PORT:String(cfg.port),HEALTH_PORT:String(cfg.health),TRIPS_RUNTIME:join(runtime,env),TRIPS_SECRETS:join(runtime,'aws'),TRIPS_STATE:join(state,env)};
    try{
      const password=run('aws',['ecr','get-login-password','--region','us-west-2']);
      run('docker',['login','--username','AWS','--password-stdin','062008221187.dkr.ecr.us-west-2.amazonaws.com'],{input:password,stdio:['pipe','pipe','pipe'],env:dockerEnv});
      run('docker',['compose','--project-name',`trips-${env}`,'--file',join(root,'services/trips/compose.yaml'),'up','--detach','--pull','always'],{env:dockerEnv});
    }finally{await rm(auth,{recursive:true,force:true});}
  }
  console.log(JSON.stringify({event:'trips_private_ready',environment:env,commit:record.commit}));
}
export async function refresh(){
  await credentials();
  for(const env of Object.keys(envs)){
    let record;try{record=JSON.parse(await readFile(join(state,env,'deployment.json'),'utf8'));}catch(e){if(e.code==='ENOENT')continue;throw e;}
    await start(env,record);
  }
}
export async function installHostTimer(){
  const units=join(homedir(),'.config/systemd/user');await mkdir(units,{recursive:true});
  const quote=s=>'"'+s.replaceAll('\\','\\\\').replaceAll('"','\\"')+'"';
  await writeFile(join(units,'trips-refresh.service'),`[Unit]\nDescription=Refresh private trips and scoped certificate credentials\nAfter=network-online.target\n[Service]\nType=oneshot\nExecStart=${quote(process.execPath)} ${quote(join(root,'scripts/trips-host.mjs'))}\nTimeoutStartSec=180\nUMask=0077\n`);
  await writeFile(join(units,'trips-refresh.timer'),'[Unit]\nDescription=Keep private trips and certificate credentials available\n[Timer]\nOnBootSec=45s\nOnUnitActiveSec=15min\nPersistent=true\n[Install]\nWantedBy=timers.target\n');
  run('systemctl',['--user','daemon-reload']);run('systemctl',['--user','enable','--now','trips-refresh.timer']);
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  refresh().catch(()=>{console.error(JSON.stringify({event:'trips_private_refresh_failed',action:'Check AWS session, runtime directories and container health; retry the refresh service. Do not log credentials.'}));process.exitCode=1;});
}
