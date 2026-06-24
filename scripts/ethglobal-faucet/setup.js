#!/usr/bin/env node
/**
 * ETHGlobal Faucet — 環境設置（30 秒，只需一次）
 *
 * 完整複製你的 Chrome Default Profile → Playwright 用此 profile 操作
 * 包含所有 cookies、IndexedDB、localStorage、session token
 */

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execSync } = require('child_process');

const SRC = path.join(os.homedir(), 'Library/Application Support/Google/Chrome/Default');
const DST = path.join(__dirname, 'browser-profile');
const STORAGE_FILE = path.join(DST, 'storage-state.json');

function log(msg, ok = true) { console.log(`${ok ? '✅' : '❌'} ${msg}`); }
const sleep = ms => new Promise(r => setTimeout(r, ms));

async function main() {
  console.log('\n═══ ETHGlobal Faucet — 環境設置 ═══\n');

  // 1. 關 Chrome
  let wasRunning = false;
  try { execSync('pgrep -x "Google Chrome"', { encoding: 'utf8' }); wasRunning = true; } catch {}
  if (wasRunning) {
    console.log('步驟 1/4: 關閉 Chrome (解鎖 profile)...');
    execSync('pkill -x "Google Chrome" 2>/dev/null; sleep 2', { encoding: 'utf8' });
    log('Chrome 已關閉');
  } else {
    log('Chrome 未在運行');
  }

  // 2. 完整複製 profile
  console.log('\n步驟 2/4: 完整複製 Chrome Profile...');
  if (fs.existsSync(DST)) fs.rmSync(DST, { recursive: true, force: true });
  fs.mkdirSync(DST, { recursive: true });

  // 複製所有關鍵文件
  const toCopy = [
    'Cookies', 'Cookies-journal',
    'Local Storage', 'Session Storage',
    'IndexedDB',
    'Network', 'Preferences',
    'Login Data', 'Login Data For Account', 'Login Data-journal',
    'Web Data', 'Web Data-journal',
    'Extension Cookies', 'Extension Cookies-journal',
    'Service Worker',
    'shared_proto_db',
  ];

  for (const f of toCopy) {
    const src = path.join(SRC, f);
    const dst = path.join(DST, f);
    try {
      if (!fs.existsSync(src)) continue;
      if (fs.statSync(src).isDirectory()) {
        execSync(`cp -R "${src}" "${dst}" 2>/dev/null`, { encoding: 'utf8' });
      } else {
        fs.copyFileSync(src, dst);
      }
    } catch { /* 跳過不存在的文件 */ }
  }
  log('Profile 已完整複製');

  // 3. 用 Playwright 打開驗證
  console.log('\n步驟 3/4: 驗證登錄態（打開 ETHGlobal detail 頁）...');
  const { chromium } = require('playwright-extra');
  const StealthPlugin = require('puppeteer-extra-plugin-stealth');
  chromium.use(StealthPlugin());

  const context = await chromium.launchPersistentContext(DST, {
    headless: false,
    channel: 'chrome',
    viewport: { width: 1280, height: 800 },
    args: ['--no-first-run', '--no-default-browser-check', '--disable-features=Translate'],
  });

  const page = await context.newPage();
  // 關鍵：不要只看列表頁，要驗證 detail 頁
  await page.goto('https://ethglobal.com/faucet/sepolia-11155111-eth', { waitUntil: 'load', timeout: 20000 });
  await page.waitForTimeout(5000);

  const body = await page.evaluate(() => document.body?.textContent || '');
  const isLoggedIn = !body.includes('Login to access faucet') && !body.includes('Login to ETHGlobal');

  if (isLoggedIn) {
    log('ETHGlobal detail 頁面驗證通過 — 已登錄！');
  } else {
    // 等待用戶手動登錄
    console.log('\n⚠️  Profile 中未檢測到登錄態');
    console.log('   請在打開的瀏覽器中手動登錄 ETHGlobal');
    console.log('   登錄後按 Enter 繼續...\n');
    const readline = require('readline');
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
    await new Promise(r => rl.question('按 Enter...', () => rl.close()));

    // 再次驗證
    await page.goto('https://ethglobal.com/faucet/sepolia-11155111-eth', { waitUntil: 'load', timeout: 20000 });
    await page.waitForTimeout(3000);
    const body2 = await page.evaluate(() => document.body?.textContent || '');
    if (body2.includes('Login to access faucet')) {
      log('仍未登錄，請檢查；或重跑 setup.js', false);
      await context.close();
      process.exit(1);
    }
    log('登錄成功！');
  }

  // 4. 導出 storage state（給未來備用）
  console.log('\n步驟 4/4: 保存 storage state...');
  const state = await context.storageState();
  fs.writeFileSync(STORAGE_FILE, JSON.stringify(state, null, 2));
  log(`Session 已保存 (${state.cookies.length} cookies)`);

  await context.close();

  // 重新打開 Chrome
  if (wasRunning) {
    execSync('open -a "Google Chrome"', { stdio: 'ignore' });
  }

  console.log('\n═══════════════════════════════════');
  console.log('  ✅ 設置完成！\n');
  console.log('  測試:  node claim.js --dry-run');
  console.log('  領取:  node claim.js');
  console.log('═══════════════════════════════════\n');
}

main().catch(err => {
  console.error('❌', err.message);
  try { execSync('open -a "Google Chrome"', { stdio: 'ignore' }); } catch {}
  process.exit(1);
});
