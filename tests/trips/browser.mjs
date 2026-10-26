import assert from 'node:assert/strict';
import { chromium } from 'playwright';
import { envs, run } from '../../scripts/trips-host.mjs';
import { readPassword } from '../../scripts/private-trip.mjs';
import { readFile } from 'node:fs/promises';

const environment=process.argv[2]||'dev';const cfg=envs[environment];
if(!cfg)throw Error('Invalid environment');
const publicIp=run('dig',['@1.1.1.1',cfg.host,'A','+short']).split('\n').find(v=>/^\d+\.\d+\.\d+\.\d+$/.test(v));
assert.ok(publicIp,'Public DNS must resolve');
const routes=['north-cascades-2027','puerto-vallarta-2027'];
const password=readPassword();
let phase='initial';
try{
  for(const[network,address]of [['public',publicIp],['lan','192.168.1.207'],['tailnet','100.124.5.39']]){
    phase=network;
    const browser=await chromium.launch({args:[`--host-resolver-rules=MAP ${cfg.host} ${address},EXCLUDE localhost`]});
    try{
      const context=await browser.newContext({viewport:{width:390,height:844}});
      const page=await context.newPage();page.setDefaultTimeout(12000);
      const errors=[];page.on('pageerror',()=>errors.push(true));
      const index=await page.goto(`https://${cfg.host}/`);
      if(network==='public'){
        assert.equal(index.status(),404);
        assert.ok(!(await index.text()).includes('Puerto Vallarta'));
        await context.setExtraHTTPHeaders({'X-Forwarded-For':'192.168.1.207','X-Real-IP':'100.124.5.39','X-Tailscale-User-Login':'forged@example.invalid'});
        for(const path of ['/healthz','/manifest.json','/releases/test/artifact.tar.gz']){
          const result=await page.goto(`https://${cfg.host}${path}`);
          assert.equal(result.status(),404);
        }
        await context.setExtraHTTPHeaders({});
      }else{
        assert.equal(index.status(),200);
        assert.equal(await page.locator('article.card').count(),2);
        assert.ok(await page.getByRole('link',{name:'Puerto Vallarta with an infant',exact:true}).isVisible());
      }
      for(const slug of routes){
        phase=network+'_'+slug;
        const response=await page.goto(`https://${cfg.host}/${slug}/`);
        assert.equal(response.status(),200);
        assert.match(response.headers()['cache-control'],/no-store/);
        assert.match(response.headers()['x-robots-tag'],/noindex/);
        if(network==='public'){
          const source=await response.text();assert.ok(!source.includes('trip-metadata'));
          assert.ok(!source.includes(password));assert.ok(source.includes('staticryptEncryptedMsgUniqueVariableName'));
          await page.locator('#staticrypt-password').waitFor({state:'visible'});
          const wrong=page.waitForEvent('dialog');
          await page.locator('#staticrypt-password').fill('incorrect-password');
          await page.getByRole('button',{name:'Open trip plan'}).click();await(await wrong).accept();
          assert.equal(await page.locator('h1').count(),0);
          try{
            await page.locator('#staticrypt-password').fill(password);
            await page.getByRole('button',{name:'Open trip plan'}).click();
            await page.locator('h1').waitFor();
          }catch{throw Error('unlock_failed');}
          assert.equal(await page.getByRole('link',{name:'Trip index',exact:true}).isVisible(),false);
          await page.getByRole('link',{name:'Lock page',exact:true}).click();
          await page.locator('#staticrypt-password').waitFor({state:'visible'});
        }else{
          assert.equal(await page.locator('#staticrypt-password').count(),0);
          assert.ok(await page.locator('h1').isVisible());
          assert.equal(await page.getByRole('link',{name:'Lock page',exact:true}).isVisible(),false);
          assert.ok(await page.getByRole('link',{name:'Trip index',exact:true}).isVisible());
          assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false);
          if(slug==='puerto-vallarta-2027'){
            assert.ok(await page.getByRole('heading',{name:'A week with room to breathe'}).isVisible());
            const sheet=page.getByRole('link',{name:/editable Google Sheets/});
            assert.match(await sheet.getAttribute('href'),/^https:\/\/docs\.google\.com\/spreadsheets\//);
          }
        }
        assert.equal(await page.evaluate(()=>localStorage.length),0);
        assert.equal(await page.evaluate(()=>sessionStorage.length),0);
      }
      assert.equal(errors.length,0);
      console.log(JSON.stringify({event:'trips_browser_passed',environment,network}));
    }finally{await browser.close();}
  }
}catch{
  console.error(JSON.stringify({event:'trips_browser_failed',environment,phase,action:'Inspect route status and TLS. Sensitive browser action details suppressed; do not enable password traces.'}));process.exitCode=1;
}
