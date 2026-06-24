#!/usr/bin/env node
/**
 * ETHGlobal Faucet — 初次登錄設置（只需運行一次）
 *
 * 打開 Chrome 瀏覽器 → 手動登錄 ETHGlobal → 保存 session
 * 之後 claim.js 會復用此 session 每天自動領取
 */

const { chromium } = require('playwright');
const path = require('path');
const readline = require('readline');

const USER_DATA_DIR = path.join(__dirname, 'browser-profile');

function ask(q) {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  return new Promise(resolve => rl.question(q, ans => { rl.close(); resolve(ans); }));
}

async function main() {
  console.log('\n═══════════════════════════════════════════');
  console.log('  ETHGlobal Faucet — 初次登錄設置');
  console.log('═══════════════════════════════════════════\n');
  console.log('會打開 Chrome，請手動登錄 ETHGlobal（Email/GitHub/Google/錢包）');
  console.log('登錄後確認頁面能看到鏈列表 → 回到終端按 Enter\n');

  const context = await chromium.launchPersistentContext(USER_DATA_DIR, {
    headless: false,
    channel: 'chrome',
    viewport: { width: 1280, height: 800 },
  });

  const page = await context.newPage();
  await page.goto('https://ethglobal.com/faucet/', { waitUntil: 'networkidle' });
  await page.waitForTimeout(2000);

  console.log('🚀 瀏覽器已打開\n');
  console.log('─────────────────────────────────────────');
  console.log('  👆 請在瀏覽器中完成登錄');
  console.log('  確認能看到鏈列表和 Available/Claim 按鈕');
  console.log('  然後回到這裡按 Enter 保存 session');
  console.log('───────────────────────────────��─────────');

  await ask('\n按 Enter 保存登錄態並關閉瀏覽器...');

  await page.goto('https://ethglobal.com/faucet/', { waitUntil: 'networkidle' });
  await page.waitForTimeout(2000);

  const ok = await page.evaluate(() => {
    const body = document.body.textContent || '';
    return !body.includes('Login to access faucet');
  });

  if (ok) {
    console.log('✅ 登錄態有效！已保存到 browser-profile/\n');
    console.log('接下來:');
    console.log('  node claim.js --dry-run   模擬跑一遍');
    console.log('  node claim.js             正式領取');
    console.log('\n定時任務:');
    console.log('  crontab -e');
    console.log(`  1 10 * * * cd ${__dirname} && bash daily-claim.sh\n`);
  } else {
    console.log('⚠️  可能未登錄成功，請重跑 setup.js\n');
  }

  await context.close();
  console.log('👋 完成');
}

main().catch(err => { console.error(err); process.exit(1); });
