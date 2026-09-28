// Install separately: npm install --prefix /tmp/dog-browser playwright
// NODE_PATH=/tmp/dog-browser/node_modules node tools/browser-check.cjs [URL]
const {chromium}=require('playwright');
const assert=require('node:assert/strict');
async function saved(page) {
 return page.evaluate(async()=>{
  const dbs=await indexedDB.databases();
  for(const entry of dbs){
   const values=await new Promise(resolve=>{
    const request=indexedDB.open(entry.name);
    request.onsuccess=()=>{const db=request.result;if(!db.objectStoreNames.contains('FILE_DATA')){db.close();return resolve([])};
     const tx=db.transaction('FILE_DATA');const get=tx.objectStore('FILE_DATA').getAll();
     get.onsuccess=()=>{resolve(get.result);db.close()};get.onerror=()=>resolve([])};
    request.onerror=()=>resolve([]);
   });
   for(const value of values){try{const parsed=JSON.parse(new TextDecoder().decode(value.contents));if(parsed.version===1&&parsed.state)return parsed.state}catch{}}
  }
  return null;
 });
}
async function untilSaved(page,predicate){
 for(let i=0;i<30;i++){const s=await saved(page);if(s&&predicate(s))return s;await page.waitForTimeout(200)}
 throw new Error('Expected saved state not reached');
}
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--no-sandbox','--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 const errors=[];
 const context=await browser.newContext({viewport:{width:1280,height:800}});
 const p=await context.newPage();
 const watch=page=>{page.on('pageerror',e=>errors.push(String(e)));page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});page.on('response',r=>{if(r.status()>=400)errors.push(`${r.status()} ${r.url()}`)})};
 watch(p);
 const base=process.argv[2]||'http://127.0.0.1:8765/build/web/';
 await p.goto(base);await p.waitForTimeout(7000);
 await p.screenshot({path:'/tmp/dog-meadow-verified.png'});
 await p.keyboard.press('4');await p.keyboard.press('Space');await p.waitForTimeout(3000);
 let s=await untilSaved(p,s=>s.stats.paid===1);assert.equal(s.bet,4);assert.equal(s.stats.wagered,4);
 const jackpot=s.jackpot;
 await p.mouse.click(1150,60);await p.waitForTimeout(300);
 await p.mouse.click(550,195);await p.mouse.click(1060,80);await p.waitForTimeout(300);
 s=await untilSaved(p,s=>s.theme===1);assert.equal(s.jackpot,jackpot);
 await p.screenshot({path:'/tmp/dog-snow-verified.png'});
 await p.reload();await p.waitForTimeout(5000);
 s=await saved(p);assert.equal(s.theme,1);assert.equal(s.stats.paid,1);assert.equal(s.jackpot,jackpot);
 await p.keyboard.press('p');await p.waitForTimeout(300);await p.screenshot({path:'/tmp/dog-odds.png'});
 await p.keyboard.press('Escape');
 await p.setViewportSize({width:960,height:600});await p.waitForTimeout(500);await p.screenshot({path:'/tmp/dog-resize.png'});
 const mobile=await browser.newContext({viewport:{width:844,height:390},isMobile:true,hasTouch:true,deviceScaleFactor:1});
 const mp=await mobile.newPage();watch(mp);
 await mp.goto(base);await mp.waitForTimeout(6000);
 await mp.screenshot({path:'/tmp/dog-mobile.png'});
 const box=await mp.locator('canvas').boundingBox();const scale=Math.min(box.width/1280,box.height/800);
 const point=(x,y)=>({x:box.x+(box.width-1280*scale)/2+x*scale,y:box.y+(box.height-800*scale)/2+y*scale});
 const spin=point(630,727);await mp.touchscreen.tap(spin.x,spin.y);
 await mp.waitForTimeout(3000);s=await untilSaved(mp,s=>s.stats.paid===1);assert.equal(s.stats.wagered,1);
 await mp.screenshot({path:'/tmp/dog-mobile-spin.png'});
 if(s.credits<100){const refill=point(110,65);await mp.touchscreen.tap(refill.x,refill.y);s=await untilSaved(mp,s=>s.credits===100);assert.equal(s.stats.refills,1)}
 console.log('Verified browser wager/deduction, spin, theme save/reload, jackpot persistence, resize, touch spin and refill.');
 console.log('Browser errors:',errors);assert.equal(errors.length,0);
 await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
