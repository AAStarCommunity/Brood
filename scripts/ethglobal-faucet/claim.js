#!/usr/bin/env node
/**
 * ETHGlobal Faucet — 每日自動領取測試幣
 *
 * 前置: node setup.js（只需一次，完整複製 Chrome Profile）
 * 用法:
 *   node claim.js              日常 headless 領取
 *   node claim.js --dry-run    模擬，不點擊
 *   node claim.js --headed     顯示瀏覽器窗口
 *   node claim.js --chain sepolia-11155111-eth  單鏈
 */

const { chromium } = require('playwright-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');
chromium.use(StealthPlugin());
const fs = require('fs');
const path = require('path');

const CONFIG = {
  baseUrl: 'https://ethglobal.com',
  userDataDir: path.join(__dirname, 'browser-profile'),
  claimLogPath: path.join(__dirname, 'claim-log.json'),
  cooldownMs: 23.5 * 60 * 60 * 1000,
  claimTimeoutMs: 120_000,
  chainCooldownMs: 5000,
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
const loadLog = () => { try { return fs.existsSync(CONFIG.claimLogPath) ? JSON.parse(fs.readFileSync(CONFIG.claimLogPath, 'utf8')) : {}; } catch { return {}; } };
const saveLog = d => fs.writeFileSync(CONFIG.claimLogPath, JSON.stringify(d, null, 2));
const canClaim = (slug, log) => { const l = log[slug]; return !l || Date.now() - new Date(l).getTime() >= CONFIG.cooldownMs; };
const wait = ms => new Promise(r => setTimeout(r, ms));

// ── 掃描列表頁 ──
async function scanFaucetList(page) {
  for (const strategy of ['load', 'domcontentloaded']) {
    try { await page.goto(`${CONFIG.baseUrl}/faucet/`, { waitUntil: strategy, timeout: 20000 }); break; }
    catch { if (strategy === 'domcontentloaded') throw new Error('列表頁無法載入'); }
  }
  await page.waitForTimeout(4000);

  const chains = await page.evaluate(() => {
    const results = [];
    const seen = new Set();
    for (const link of document.querySelectorAll('a[href*="/faucet/"]')) {
      const href = link.getAttribute('href');
      if (!href || href === '/faucet/' || href === '/faucet' || seen.has(href)) continue;
      if (href.includes('/auth') || href.includes('/login')) continue;
      if (!/\/faucet\/[a-zA-Z0-9_-]+/.test(href)) continue;
      seen.add(href);

      let node = link, isUnavailable = false;
      for (let i = 0; i < 4 && node && node.tagName !== 'BODY'; i++) {
        if (/Unavailable/i.test(node.textContent || '')) { isUnavailable = true; break; }
        node = node.parentElement;
      }
      if (isUnavailable) continue;

      const rawName = (link.childNodes[0]?.textContent || link.textContent || '').trim();
      const cleanName = rawName.split(/[\n\r]+/)[0].split(',')[0].trim();
      results.push({
        name: cleanName || href.split('/').pop(),
        url: href.startsWith('http') ? href : `https://ethglobal.com${href}`,
        slug: href.split('/').pop(),
      });
    }
    return results;
  });

  log(`列表頁: ${chains.length} 條鏈`);
  for (const c of chains) log(`  ${c.name}`, 'detail');
  return chains;
}

// ── 單鏈 Claim ──
async function claimOne(context, chain) {
  const page = await context.newPage();
  const r = { slug: chain.slug, name: chain.name, status: 'unknown', detail: '' };

  try {
    await page.goto(chain.url, { waitUntil: 'load', timeout: 20000 });
    await page.waitForTimeout(3000);
    const bodyText = await page.evaluate(() => document.body?.textContent || '');

    if (bodyText.includes('Login to access faucet')) {
      r.status = 'logged_out'; r.detail = '需登錄'; log(`  ❌ 未登錄`, 'error'); await page.close(); return r;
    }

    const cd = bodyText.match(/(come back in \d+h|next claim in \d+h|\d+h \d+m remaining)/i);
    if (cd) { r.status = 'cooldown'; r.detail = cd[0]; log(`  ⏭️ ${cd[0]}`, 'skip'); await page.close(); return r; }

    const btn = await page.evaluate(() => {
      for (const b of document.querySelectorAll('button')) {
        const t = (b.textContent || '').trim();
        if (/^Claim$/i.test(t) && !b.disabled && b.offsetParent !== null) return { ok: true, text: t };
      }
      return null;
    });

    if (!btn) { r.status = 'no_button'; r.detail = '無可用按鈕'; log(`  ⚠️ 無按鈕`, 'warn'); await page.close(); return r; }

    if (DRY_RUN) { r.status = 'dry_run'; r.detail = `DRY RUN — "${btn.text}"`; log(`  🔍 ${r.detail}`, 'skip'); await page.close(); return r; }

    await page.click('button:has-text("Claim")');
    log(`  等待交易...`);

    const outcome = await (async () => {
      const deadline = Date.now() + CONFIG.claimTimeoutMs;
      while (Date.now() < deadline) {
        await page.waitForTimeout(3000);
        const t = await page.evaluate(() => document.body?.textContent || '');
        if (/successfully sent|View transaction|Transaction submitted|Claimed successfully/i.test(t)) return 'success';
        if (/Failed|Something went wrong|error occurred/i.test(t)) return 'fail';
        if (/come back in|already claimed|next claim/i.test(t)) return 'cooldown';
      }
      return 'timeout';
    })();

    r.status = outcome;
    r.detail = outcome === 'success' ? '✅ 成功' : outcome === 'fail' ? '❌ 失敗' : '⏱️ 超時';
    log(`  ${r.detail}`, outcome === 'success' ? 'success' : 'warn');

  } catch (err) {
    r.status = 'error'; r.detail = err.message.slice(0, 80);
    log(`  💥 ${r.detail}`, 'error');
  } finally { await page.close(); }
  return r;
}

// ── 主流程 ──
async function main() {
  log('═══════════════════════════════', 'start');
  log(`ETHGlobal Faucet — ${DRY_RUN ? 'DRY RUN' : '正式'}`, 'start');

  if (!fs.existsSync(CONFIG.userDataDir)) {
    log('未找到 browser-profile/，請先: node setup.js', 'error');
    process.exit(1);
  }

  const claimLog = loadLog();
  const results = [];

  const context = await chromium.launchPersistentContext(CONFIG.userDataDir, {
    headless: !HEADED,
    channel: 'chrome',
    viewport: { width: 1280, height: 800 },
  });

  try {
    let chains;
    if (SINGLE_CHAIN) {
      chains = [{ name: SINGLE_CHAIN, slug: SINGLE_CHAIN, url: `${CONFIG.baseUrl}/faucet/${SINGLE_CHAIN}` }];
    } else {
      const listPage = await context.newPage();
      chains = await scanFaucetList(listPage);
      await listPage.close();
    }

    if (!chains.length) { log('沒有鏈', 'warn'); return; }

    const eligible = [], inCD = [];
    for (const c of chains) {
      (canClaim(c.slug, claimLog) ? eligible : inCD).push(c);
    }
    for (const c of inCD) {
      const next = new Date(new Date(claimLog[c.slug]).getTime() + CONFIG.cooldownMs);
      log(`⏭️ ${c.name}: ${next.toISOString().slice(0, 16)}`, 'skip');
    }
    if (!eligible.length) { log('全部 CD', 'info'); return; }

    log(`\n── 領取 ${eligible.length} 條鏈 ──`, 'start');
    for (let i = 0; i < eligible.length; i++) {
      log(`[${i + 1}/${eligible.length}] ${eligible[i].name}`);
      const r = await claimOne(context, eligible[i]);
      results.push(r);
      if (r.status === 'success') { claimLog[eligible[i].slug] = new Date().toISOString(); saveLog(claimLog); }
      if (r.status === 'logged_out') break;
      if (i < eligible.length - 1) await wait(CONFIG.chainCooldownMs + Math.random() * 3000);
    }
  } finally { await context.close(); }

  log('\n── 總結 ──', 'info');
  const icons = { success: '✅', fail: '❌', cooldown: '⏭️', timeout: '⏱️', dry_run: '🔍', error: '💥', logged_out: '🚫', no_button: '👻' };
  for (const r of results) console.log(`  ${icons[r.status] || '❓'} ${(r.name || r.slug).padEnd(30)} ${r.detail}`);
  const s = { success: 0, fail: 0, cd: 0, timeout: 0, err: 0 };
  for (const r of results) {
    if (r.status === 'success') s.success++;
    else if (r.status === 'fail') s.fail++;
    else if (r.status === 'cooldown') s.cd++;
    else if (r.status === 'timeout') s.timeout++;
    else if (r.status !== 'dry_run') s.err++;
  }
  log(`成功 ${s.success} | 失敗 ${s.fail} | CD ${s.cd} | 超時 ${s.timeout} | 異常 ${s.err}`, 'info');
}

main().catch(err => { log(err.message, 'error'); process.exit(1); });
