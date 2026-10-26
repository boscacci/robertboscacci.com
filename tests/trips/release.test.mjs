import {test}from'node:test';
import assert from'node:assert/strict';
import{mkdtemp,readFile,rm}from'node:fs/promises';
import{tmpdir}from'node:os';
import{join}from'node:path';
import{writePrivate,writePublic}from'../../services/trips/hub.mjs';
import{validImage,run}from'../../scripts/trips-host.mjs';
test('artifact byte verification preserves trailing whitespace and binary output',()=>{
 const bytes=run(process.execPath,['-e','process.stdout.write(Buffer.from([0,255,32,10]))'],{encoding:null});
 assert.deepEqual(bytes,Buffer.from([0,255,32,10]));
});
test('private publishing derives the index and never mutates the public encrypted bytes',async()=>{
 const dir=await mkdtemp(join(tmpdir(),'trip-release-'));
 try{
  const trips=[{slug:'test-2027',title:'Private title',dates:'TBD',status:'Proposed',summary:'Private summary',html:'<html><head></head><body>Private article</body></html>',encrypted:'CIPHERTEXT'}];
  const hashes=await writePublic(join(dir,'public'),trips);await writePrivate(join(dir,'private'),trips);
  assert.equal(await readFile(join(dir,'public/test-2027/index.html'),'utf8'),'CIPHERTEXT');
  assert.ok((await readFile(join(dir,'private/index.html'),'utf8')).includes('Private title'));
  assert.ok((await readFile(join(dir,'private/test-2027/index.html'),'utf8')).includes('.public-only{display:none'));
  assert.match(hashes['test-2027/index.html'],/^[a-f0-9]{64}$/);
 }finally{await rm(dir,{recursive:true,force:true});}
});
test('private service accepts only immutable digests from its verified registry',()=>{
 assert.ok(validImage('062008221187.dkr.ecr.us-west-2.amazonaws.com/robertboscacci-trips-private@sha256:'+'a'.repeat(64)));
 for(const image of ['caddy:latest','example.com/caddy@sha256:'+'a'.repeat(64),'062008221187.dkr.ecr.us-west-2.amazonaws.com/robertboscacci-trips-private:latest'])assert.equal(validImage(image),false);
});
