#!/usr/bin/env node
/**
 * ETHGlobal Faucet — 每日自動領取
 *
 * 用法:
 *   node claim.js              日常 headless 領取
 *   node claim.js --dry-run    模擬，不實際點擊
 *   node claim.js --headed     顯示瀏覽器窗口調試
 *   node claim.js --chain sepolia-11155111-eth  只領取指定鏈
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const CONFIG = {
  baseUrl: 'https://ethglobal.com',
  userDataDir: path.join(__dirname, 'browser-profile'),
  claimLogPath: path.join(__dirname, 'claim-log.json'),
  cooldownMs: 23.5 * 60 * 60 * 1000,
  claimTimeoutMs: 90_000,
  pageTimeoutMs: 30_000,
};

const args = process.argv.slice(2);
const DRY_RUN = args.includes('--dry-run');
const HEADED = args.includes('--headed');
const SINGLE_CHAIN = (() => { const i = args.indexOf('--chain'); return i >= 0 ? args[i + 1] : null; })();

function log(msg, lv = 'info') {
  const ts = new Date().toISOString().replace('T', ' ').slice(0, 19);
  const icons = { info: '📋', success: '✅', warn: '⚠️', error: '❌', start: '🚀', skip: '⏭️' };
  console.log(`[${ts}] ${icons[lv] || '  '} ${msg}`);
}

const loadClaimLog = () => {
  try { return fs.existsSync(CONFIG.claimLogPath) ? JSON.parse(fs.readFileSync(CONFIG.claimLogPath, 'utf8')) : {}; }
  catch { return {}; }
};
const saveClaimLog = d => fs.writeFileSync(CONFIG.claimLogPath, JSON.stringify(d, null, 2));
const canClaim = (slug, log) => { const l = log[slug]; return !l || Date.now() - new Date(l).getTime() >= CONFIG.cooldownMs; };
const wait = ms => new Promise(r => setTimeout(r, ms));

async function getAvailableChains(page) {
  await page.goto(`${CONFIG.baseUrl}/faucet/`, { waitUntil: 'networkidle', timeout: CONFIG.pageTimeoutMs });
  await page.waitForTimeout(3000);

  const chains = await page.evaluate(() => {
    const results = [];
    const links = document.querySelectorAll('a[href*="/faucet/"]');
    const seen = new Set();
    for (const link of links) {
      const href = link.getAttribute('href');
      if (!href || href === '/faucet/' || seen.has(href)) continue;
      seen.add(href);
      const parent = link.closest('div, section, article, li') || link.parentElement;
      const text = parent?.textContent || '';
      if (text.includes('Available') || text.includes('available')) {
        const nameEl = parent.querySelector('h2, h3, h4, [class*="name"], [class*="title"]');
        results.push({
          name: (nameEl?.textContent || link.textContent || href.split('/').pop()).trim(),
          url: href.startsWith('http') ? href : `https://ethglobal.com${href}`,
          slug: href.split('/').pop(),
        });
      }
    }
    return results;
  });

  log(`發現 ${chains.length} 條可用鏈`);
  return chains;
}

async function claimChain(context, chain) {
  const page = await context.newPage();
  const result = { chain: chain.slug, name: chain.name, status: 'unknown', detail: '' };

  try {
    log(`處理: ${chain.name}`);
    await page.goto(chain.url, { waitUntil: 'networkidle', timeout: CONFIG.pageTimeoutMs });
    await page.waitForTimeout(3000);

    // 登錄檢查
    const loggedIn = await page.evaluate(() => {
      const b = document.body.textContent || '';
      return !b.includes('Login to access faucet') && !b.includes('Login to ETHGlobal');
    });
    if (!loggedIn) { result.status = 'logged_out'; result.detail = '登錄態過期'; await page.close(); return result; }

    // CD 檢查
    const cd = await page.evaluate(() => {
      const b = document.body.textContent || '';
      const m = b.match(/(come back in \d+h|next claim in \d+h|\d+h \d+m remaining)/i);
      return m ? m[0] : null;
    });
    if (cd) { result.status = 'cooldown'; result.detail = cd; log(`  ${cd}`, 'skip'); await page.close(); return result; }

    // 找按鈕
    const btn = await page.evaluate(() => {
      for (const b of document.querySelectorAll('button')) {
        const t = (b.textContent || '').trim().toLowerCase();
        if ((t === 'claim' || t.startsWith('claim')) && !t.includes('claimed') && !b.disabled) return true;
      }
      return false;
    });
    if (!btn) { result.status = 'no_button'; result.detail = '無可用按鈕'; await page.close(); return result; }

    if (DRY_RUN) { result.status = 'dry_run'; result.detail = 'DRY RUN'; await page.close(); return result; }

    // 點擊
    await page.click('button:has-text("Claim")');
    log('  等待交易...');

    // 等結果
    const outcome = await (async () => {
      const start = Date.now();
      while (Date.now() - start < CONFIG.claimTimeoutMs) {
        await page.waitForTimeout(2000);
        const t = await page.evaluate(() => document.body.textContent || '');
        if (t.includes('successfully sent') || t.includes('View transaction') ||
            t.includes('Transaction submitted') || t.includes('Claimed successfully')) return 'success';
        if (t.includes('Failed') || t.includes('Something went wrong')) return 'fail';
        if (t.includes('come back in') || t.includes('already claimed')) return 'cooldown';
      }
      return 'timeout';
    })();

    result.status = outcome;
    result.detail = outcome === 'success' ? '領取成功' : outcome === 'fail' ? '領取失敗' : '超時';
    log(`  ${outcome === 'success' ? '✅' : outcome === 'fail' ? '❌' : '⏱️'} ${result.detail}`, outcome === 'success' ? 'success' : 'error');
  } catch (err) {
    result.status = 'error'; result.detail = err.message;
  } finally {
    await page.close();
  }
  return result;
}

async function main() {
  log('ETHGlobal Faucet Bot', 'start');

  if (!fs.existsSync(CONFIG.userDataDir)) {
    log('未找到 browser-profile，請先: node setup.js', 'error');
    process.exit(1);
  }

  const claimLog = loadClaimLog();
  const results = [];
  const context = await chromium.launchPersistentContext(CONFIG.userDataDir, {
    headless: !HEADED,
    viewport: { width: 1280, height: 800 },
  });

  try {
    let chains;
    if (SINGLE_CHAIN) {
      chains = [{ name: SINGLE_CHAIN, slug: SINGLE_CHAIN, url: `${CONFIG.baseUrl}/faucet/${SINGLE_CHAIN}` }];
    } else {
      const lp = await context.newPage();
      chains = await getAvailableChains(lp);
      await lp.close();
    }

    const eligible = chains.filter(c => canClaim(c.slug, claimLog));
    const inCD = chains.filter(c => !canClaim(c.slug, claimLog));

    if (inCD.length) log(`${inCD.length} 條鏈仍在 CD`, 'skip');
    if (!eligible.length) { log('無可領取鏈', 'info'); return; }

    log(`準備領取 ${eligible.length} 條鏈`, 'start');

    for (let i = 0; i < eligible.length; i++) {
      log(`[${i + 1}/${eligible.length}]`);
      const r = await claimChain(context, eligible[i]);
      results.push(r);
      if (r.status === 'success') { claimLog[eligible[i].slug] = new Date().toISOString(); saveClaimLog(claimLog); }
      if (r.status === 'logged_out') break;
      if (i < eligible.length - 1) await wait(2000 + Math.random() * 2000);
    }
  } finally {
    await context.close();
  }

  const summary = {
    success: results.filter(r => r.status === 'success').length,
    fail: results.filter(r => r.status === 'fail').length,
    error: results.filter(r => ['error', 'timeout', 'no_button', 'logged_out'].includes(r.status)).length,
  };
  log(`完成: 成功 ${summary.success} | 失敗 ${summary.fail} | 異常 ${summary.error}`, 'info');
}

main().catch(err => { log(err.message, 'error'); console.error(err); process.exit(1); });
