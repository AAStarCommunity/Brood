import fs from 'node:fs/promises';
import path from 'node:path';
import { spawn } from 'node:child_process';
import http from 'node:http';

const distDir = path.join(process.cwd(), 'dist');
const apiDir = path.join(distDir, 'api');
const PORT = 8422;

// Compute weighted milestone progress from task markdown files.
// Rules: Done=100%, In Progress=use 预估进度 (default 10%), To Do=0%.
// Returns { 'm-1': N, 'm-2': N, 'm-3': N, 'm-r': N }
async function computeMilestoneProgress() {
  const tasksDir = path.join(process.cwd(), 'backlog', 'tasks');
  const files = await fs.readdir(tasksDir).catch(() => []);
  const byMilestone = {};

  for (const file of files) {
    if (!file.endsWith('.md')) continue;
    const content = await fs.readFile(path.join(tasksDir, file), 'utf-8');
    const fmMatch = content.match(/^---\n([\s\S]*?)\n---/);
    if (!fmMatch) continue;
    const fm = fmMatch[1];

    const getField = (key) => {
      const m = fm.match(new RegExp(`^${key}:\\s*(.+)$`, 'm'));
      return m ? m[1].replace(/^['"]|['"]$/g, '').trim() : '';
    };

    const status = getField('status').replace(/^["']|["']$/g, '').trim().toLowerCase();
    const milestone = getField('milestone').replace(/^["']|["']$/g, '').trim();
    if (!milestone) continue;

    // Normalize milestone to canonical key
    const ml = milestone.toLowerCase();
    let key;
    if (ml === 'm-1' || ml.includes('phase 1') || ml.includes('genesis')) key = 'm-1';
    else if (ml === 'm-2' || ml.includes('phase 2') || ml.includes('community')) key = 'm-2';
    else if (ml === 'm-3' || ml.includes('phase 3') || ml.includes('ecosystem')) key = 'm-3';
    else if (ml === 'm-r' || ml.includes('research')) key = 'm-r';
    else key = milestone; // keep as-is for unknown milestones

    // Compute task progress
    let progress;
    if (status === 'done') {
      progress = 100;
    } else if (status === 'in progress') {
      const m = content.match(/预估进度:\s*(\d+)%/);
      progress = m ? parseInt(m[1]) : 10;
    } else {
      progress = 0;
    }

    if (!byMilestone[key]) byMilestone[key] = [];
    byMilestone[key].push(progress);
  }

  const result = {};
  for (const [key, list] of Object.entries(byMilestone)) {
    const val = Math.round(list.reduce((a, b) => a + b, 0) / list.length);
    result[key] = val;
    // The task list right-panel uses "lane:milestone:<key>" as keys (from ra() function)
    result[`lane:milestone:${key}`] = val;
  }
  return result;
}

// Strip machine-specific data out of the CLI's API payloads before they are written to dist/.
//
// The backlog.md REST API returns absolute filesystem paths (`filePath`, `projectPath`,
// `rootConfigPath` — e.g. "/Users/jason/Dev/Brood/backlog/tasks/…") and mtime-derived
// `lastModified` stamps. Two separate problems, one root cause:
//
//   1. dist/ is committed and diffed against a fresh build to prove it is reproducible. Those
//      fields can never match across machines — a CI runner checks out at /home/runner/work/… —
//      so 49/49 tasks differ and the guard is red on every PR forever. A permanently-red guard
//      gets bypassed, which is worse than having no guard.
//   2. dist/ is uploaded verbatim to a public site, so those paths publish the maintainer's home
//      directory layout to anyone who fetches /api/status.json.
//
// Fixing this by excluding more files from the diff is NOT acceptable: all four contaminated files
// are the ones that carry the actual content, so excluding them would leave the guard watching
// only index.html and hashed assets — green while shipping exactly the stale data it exists to
// catch. Sanitize at the source instead: paths become repo-relative, mtimes are dropped.
const REPO_ROOT = process.cwd();

function sanitizeApiPayload(text) {
  let data;
  try {
    data = JSON.parse(text);
  } catch {
    return text;                       // not JSON (or already a string blob) — leave untouched
  }

  const walk = (node) => {
    if (Array.isArray(node)) return node.map(walk);
    if (!node || typeof node !== 'object') return node;
    const out = {};
    for (const [key, value] of Object.entries(node)) {
      // Drop mtime-derived stamps outright: they change on every checkout and carry no meaning
      // for a static export (git already records when content changed).
      if (key === 'lastModified') continue;
      if (typeof value === 'string' && (key === 'filePath' || key === 'projectPath' || key === 'rootConfigPath')) {
        out[key] = value.startsWith(REPO_ROOT)
          ? (value.slice(REPO_ROOT.length).replace(/^\/+/, '') || '.')
          : value;
        continue;
      }
      out[key] = walk(value);
    }
    return out;
  };

  return JSON.stringify(walk(data));
}

async function fetchFromLocal(endpoint, retries = 5) {
  let lastStatus = 0;
  for (let i = 0; i < retries; i++) {
    try {
      const res = await fetch(`http://localhost:${PORT}${endpoint}`);
      if (res.ok) {
        return await res.text();
      }
      lastStatus = res.status;
      console.log(`Retry ${i+1}/${retries} for ${endpoint} - Status: ${res.status}`);
    } catch (err) {
      console.log(`Retry ${i+1}/${retries} for ${endpoint} - Error: ${err.message}`);
      if (i === retries - 1) throw err;
    }
    
    if (i < retries - 1) {
      await new Promise(resolve => setTimeout(resolve, 500));
      continue;
    }
    
    throw new Error(`HTTP error ${lastStatus} for ${endpoint}`);
  }
}

// Refuse to scrape a server we did not start. PORT is fixed, `spawn` used stdio:'ignore' with no
// error handler, and the only readiness check was a blind 4s sleep — so when something else already
// held the port, our spawn failed silently and every fetch below hit the STRANGER. That happened
// for real: a `backlog browser` left running since 2026-07-07 answered the whole export from a
// month-old cached index, and its data was committed into dist/ and deployed verbatim.
async function assertPortFree(port) {
  const inUse = await new Promise(resolve => {
    const probe = http.get({ host: '127.0.0.1', port, path: '/', timeout: 1500 }, res => {
      res.resume();
      resolve(true);
    });
    probe.on('error', () => resolve(false));
    probe.on('timeout', () => { probe.destroy(); resolve(false); });
  });
  if (inUse) {
    throw new Error(
      `Port ${port} is already serving something. Refusing to export — the scrape would read that\n` +
      `process's data, not this checkout's. Find and stop it first:\n` +
      `  lsof -nP -iTCP:${port} -sTCP:LISTEN\n` +
      `(a stale \`backlog browser\` from an earlier session is the usual culprit)`
    );
  }
}

// Fail the build rather than commit a self-contradicting snapshot. dist/ is committed and deployed
// verbatim (no CI build step), so anything wrong here ships straight to the live site. Two checks:
//   1. the three "how many tasks" numbers must agree — they diverged (39 / 37 / 40) when a foreign
//      server answered the export, and nothing downstream noticed;
//   2. no task may carry a blank id/title — invalid YAML frontmatter (e.g. an unquoted `: ` inside
//      a title) makes the parser emit an empty record that still carries the full rawContent, which
//      then ships into the public search index.
async function assertExportConsistent() {
  const read = async name => JSON.parse(await fs.readFile(path.join(apiDir, name), 'utf8'));
  const [stats, tasks, search] = await Promise.all([
    read('statistics.json'), read('tasks.json'), read('search.json'),
  ]);
  // search.json wraps each hit as {type, score, task:{...}} — read through the `task` key, or every
  // record looks blank and the check "fails" for the wrong reason.
  const searchTasks = (Array.isArray(search) ? search : search.results || [])
    .filter(x => x && x.type === 'task')
    .map(x => x.task || x);

  const problems = [];
  if (!(stats.totalTasks === tasks.length && tasks.length === searchTasks.length)) {
    problems.push(
      `task counts disagree: statistics.totalTasks=${stats.totalTasks} ` +
      `tasks.json=${tasks.length} search.json(type=task)=${searchTasks.length}`
    );
  }
  const malformed = [...tasks, ...searchTasks].filter(t => !t.id || t.id === 'TASK-' || !t.title);
  if (malformed.length) {
    problems.push(
      `${malformed.length} task record(s) with blank id/title — check the YAML frontmatter of the ` +
      `matching backlog/tasks/*.md (an unquoted ':' in the title breaks parsing): ` +
      malformed.slice(0, 5).map(t => JSON.stringify(t.id ?? null)).join(', ')
    );
  }
  if (problems.length) {
    throw new Error('Export consistency check FAILED — refusing to ship dist/:\n  - ' + problems.join('\n  - '));
  }
  console.log(`✅ Consistency check passed (${tasks.length} tasks, ids and titles all present)`);
}

// A committed, deployed-verbatim dist/ must be a pure function of THIS tree. `check_active_branches`
// makes the CLI also index tasks from other recent git branches, so the same commit exports
// differently depending on which branches happen to exist locally — and it pulled a task from `main`
// that this branch doesn't have, including main's still-broken YAML, into the shipped search index.
// Flip it off for the duration of the export only; the interactive kanban keeps the cross-branch
// view the setting exists for.
const configPath = path.join(process.cwd(), 'backlog', 'config.yml');

async function withDeterministicConfig(fn) {
  let original = null;
  try {
    original = await fs.readFile(configPath, 'utf8');
  } catch {
    return fn();                       // no config file — nothing to neutralize
  }
  const patched = original.replace(/^check_active_branches:[ \t]*true[ \t]*$/m,
                                   'check_active_branches: false');
  const changed = patched !== original;
  if (changed) {
    await fs.writeFile(configPath, patched);
    console.log('Temporarily set check_active_branches=false so the export reflects only this tree');
  }
  try {
    return await fn();
  } finally {
    // Always restore, including on failure — leaving the repo's config edited would be a silent
    // side effect of a build, and would show up as an unexplained diff in the next commit.
    if (changed) {
      await fs.writeFile(configPath, original);
      console.log('Restored backlog/config.yml');
    }
  }
}

async function exportStaticBacklog() {
  await assertPortFree(PORT);

  console.log('Starting local backlog server for export...');
  const server = spawn('npx', ['backlog', 'browser', '--no-open', '-p', PORT.toString()], {
    stdio: 'ignore'
  });
  // Surface spawn/exit failures instead of sleeping through them and scraping nothing (or worse,
  // scraping whatever else answers). A server that exits before we finish is always a hard error.
  let serverExited = null;
  server.on('error', err => { serverExited = `failed to spawn: ${err.message}`; });
  server.on('exit', (code, signal) => {
    if (signal !== 'SIGTERM') serverExited = `exited early (code=${code} signal=${signal})`;
  });

  // Give it a few seconds to start
  await new Promise(r => setTimeout(r, 4000));
  if (serverExited) throw new Error(`Local backlog server ${serverExited}`);

  try {
    // Prove the server actually answers BEFORE destroying the existing dist/. Wiping first means a
    // failed run leaves an empty dist/ — and since dist/ is committed and deployed verbatim, anyone
    // who then commits "what the build produced" wipes the live site. Fetching index.html first
    // costs one request and converts that outage into a plain error with dist/ untouched.
    console.log('Fetching index.html...');
    const indexBuffer = await fetchFromLocal('/');

    await fs.rm(distDir, { recursive: true, force: true });
    await fs.mkdir(apiDir, { recursive: true });
    let indexHtml = indexBuffer.toString('utf-8');

    // Parse static assets loaded in index.html (CSS, JS, icons)
    const assetRegex = /(?:href|src)="(\/?[^"]+\.(?:css|js|png|jpg|svg))"/g;
    const assets = [];
    let match;
    while ((match = assetRegex.exec(indexHtml)) !== null) {
      let assetPath = match[1];
      if (assetPath.startsWith('/')) assetPath = assetPath.slice(1);
      if (assetPath.startsWith('./')) assetPath = assetPath.slice(2);
      if (assetPath && !assets.includes(assetPath)) {
        assets.push(assetPath);
      }
    }

    // Compute weighted milestone progress before downloading assets
    const milestoneProgress = await computeMilestoneProgress();
    console.log('Milestone weighted progress:', milestoneProgress);

    console.log('Downloading assets:', assets);
    for (const asset of assets) {
      const assetData = await fetchFromLocal(`/${asset}`);
      const targetPath = path.join(distDir, asset);
      await fs.mkdir(path.dirname(targetPath), { recursive: true });
      await fs.writeFile(targetPath, assetData);
    }

    // Patch JS bundle: replace doneCount/total formula with weighted progress lookup
    // Both patches MUST apply, otherwise the kanban UI falls back to simple doneCount/total
    // counting and Phase progress on the live site will be wrong (e.g. 46/0/0 instead of 67/7/9).
    // See 2026-05-12 incident: backlog.md v1.45 changed minified variable names and the
    // literal-string patches silently failed, displaying wrong progress until manually noticed.
    let kanbanPatched = false;
    let rightPanelPatched = false;

    for (const asset of assets.filter(a => a.endsWith('.js'))) {
      const jsPath = path.join(distDir, asset);
      let js = await fs.readFile(jsPath, 'utf-8');
      let patched = false;

      // Patch 1: Kanban column progress bar — regex matches any minified variable names.
      // Pattern: `let X=Y.total>0?Math.round(Y.doneCount/Y.total*100):0,`
      const RE1 = /let (\w+)=(\w+)\.total>0\?Math\.round\(\2\.doneCount\/\2\.total\*100\):0,/;
      const m1 = js.match(RE1);
      if (m1) {
        const [full, x, y] = m1;
        const replacement = `let ${x}=window.__milestoneProgress&&window.__milestoneProgress[${y}.key]!==undefined?window.__milestoneProgress[${y}.key]:(${y}.total>0?Math.round(${y}.doneCount/${y}.total*100):0),`;
        js = js.replace(full, replacement);
        patched = true;
        kanbanPatched = true;
        console.log(`✅ Patched Kanban column progress formula in ${asset} (vars: ${x},${y})`);
      }

      // Patch 2: Right-side milestone panel — regex captures minified callbacks.
      // Pattern: `a=(H0)=>{let B0=p(H0);if(B0===0)return 0;let U0=n(H0);return Math.round(U0/B0*100)},G0=...useMemo`
      const RE2 = /(\w+)=\((\w+)\)=>\{let (\w+)=(\w+)\(\2\);if\(\3===0\)return 0;let (\w+)=(\w+)\(\2\);return Math\.round\(\5\/\3\*100\)\}/;
      const m2 = js.match(RE2);
      if (m2) {
        const [full, a, arg, b, p, u, n] = m2;
        const replacement = `${a}=(${arg})=>{if(window.__milestoneProgress&&window.__milestoneProgress[${arg}]!==undefined)return window.__milestoneProgress[${arg}];let ${b}=${p}(${arg});if(${b}===0)return 0;let ${u}=${n}(${arg});return Math.round(${u}/${b}*100)}`;
        js = js.replace(full, replacement);
        patched = true;
        rightPanelPatched = true;
        console.log(`✅ Patched right-panel milestone progress formula in ${asset} (vars: ${a},${arg},${b},${p},${u},${n})`);
      }

      if (patched) {
        await fs.writeFile(jsPath, js);
      }
    }

    // Fail the build if either patch didn't apply — silent failures here caused the
    // 2026-05-12 incident where kanban displayed 46/0/0 instead of the real 67/7/9.
    if (!kanbanPatched || !rightPanelPatched) {
      const missing = [];
      if (!kanbanPatched) missing.push('Kanban column progress formula');
      if (!rightPanelPatched) missing.push('right-panel milestone progress formula');
      console.error(`\n❌ BUILD ABORTED: failed to patch ${missing.join(' + ')} in JS bundle.`);
      console.error(`   This means backlog.md changed its minified output and our regex patterns no longer match.`);
      console.error(`   Without these patches, kanban progress bars fall back to doneCount/total simple counting.`);
      console.error(`   Inspect the JS chunk in dist/ and update the regex patterns in scripts/export-backlog.js.\n`);
      throw new Error(`Patch failure: ${missing.join(', ')}`);
    }

    // Rewrite index.html to inject Read-Only interception logic
    const injectedScript = `
    <script>
      // Weighted milestone progress: Done=100%, InProgress=estimate, ToDo=0%
      window.__milestoneProgress = ${JSON.stringify(milestoneProgress)};

      window.originalFetch = window.fetch;
      window.fetch = async function(resource, init) {
        let method = 'GET';
        if (init && init.method) {
          method = init.method.toUpperCase();
        } else if (resource && typeof resource === 'object' && resource.method) {
          method = resource.method.toUpperCase();
        }
        
        // Intercept any write operations
        if (['POST', 'PUT', 'DELETE', 'PATCH'].includes(method)) {
          showReadOnlyToast();
          // Provide a fake successful response to avoid UI errors/crashes
          return new Response(JSON.stringify({ success: true, message: "Read-only mode" }), {
            status: 200,
            headers: { 'Content-Type': 'application/json' }
          });
        }
        // Append .json to bypass Unix folder/file collision in dist/
        if (typeof resource === 'string' && resource.includes('/api/')) {
          let urlParts = resource.split('?');
          if (!urlParts[0].endsWith('.json')) {
            urlParts[0] = urlParts[0] + '.json';
          }
          arguments[0] = urlParts.join('?');
          resource = arguments[0];
        }
        
        // Let GET requests pass through
        return window.originalFetch.apply(this, arguments).then(res => {
          // If the request was for an API but Cloudflare returned HTML (SPA fallback)
          // or if the status is not ok (404 etc), we spoof an empty JSON response.
          const isApiRequest = typeof resource === 'string' && resource.includes('/api/');
          const isHtmlResponse = res.headers.get('content-type') && res.headers.get('content-type').includes('text/html');
          
          if (!res.ok || (isApiRequest && isHtmlResponse)) {
            console.warn("Intercepted failed or HTML-fallback static fetch:", resource);
            return new Response(JSON.stringify([]), {
              status: 200,
              headers: { 'Content-Type': 'application/json' }
            });
          }
          return res;
        }).catch(err => {
          return new Response(JSON.stringify([]), {
              status: 200,
              headers: { 'Content-Type': 'application/json' }
          });
        });
      };
      
      // Mock EventSource to prevent "Server disconnected" UI errors
      class MockEventSource {
        constructor() {
          this.readyState = 1; // OPEN
          setTimeout(() => {
            if (this.onopen) this.onopen(new Event('open'));
          }, 100);
        }
        close() {}
        addEventListener() {}
        removeEventListener() {}
      }
      window.EventSource = MockEventSource;

      // Mock WebSocket for the same reason
      class MockWebSocket {
        constructor() {
          this.readyState = 1; // OPEN
          setTimeout(() => {
            if (this.onopen) this.onopen(new Event('open'));
          }, 100);
        }
        send() {}
        close() {}
      }
      window.WebSocket = MockWebSocket;

      function showReadOnlyToast() {
        let t = document.getElementById('ro-toast');
        if (!t) {
          t = document.createElement('div');
          t.id = 'ro-toast';
          t.style.cssText = 'position:fixed;top:24px;left:50%;transform:translate(-50%, -20px);background:rgba(17,24,39,0.9);color:white;padding:12px 24px;border-radius:30px;box-shadow:0 10px 15px -3px rgba(0,0,0,0.2), 0 4px 6px -2px rgba(0,0,0,0.1);z-index:99999;font-family:system-ui,-apple-system,sans-serif;transition:opacity 0.4s cubic-bezier(0.16, 1, 0.3, 1), transform 0.4s cubic-bezier(0.16, 1, 0.3, 1);font-size:14px;pointer-events:none;display:flex;align-items:center;gap:10px;backdrop-filter:blur(8px);border:1px solid rgba(255,255,255,0.1);opacity:0;';
          t.innerHTML = '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#60A5FA" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path></svg> <span>只读展示模式：无法修改或删除项目数据</span>';
          document.body.appendChild(t);
        }
        
        // Force reflow
        void t.offsetWidth;
        
        t.style.opacity = '1';
        t.style.transform = 'translate(-50%, 0)';
        
        if (window.toastTimeout) clearTimeout(window.toastTimeout);
        window.toastTimeout = setTimeout(() => { 
          t.style.opacity = '0'; 
          t.style.transform = 'translate(-50%, -10px)';
        }, 3000);
      }
      
      // Inject CSS to hide some destructive UI elements gracefully
      document.addEventListener('DOMContentLoaded', () => {
        const style = document.createElement('style');
        style.innerHTML = 'button[title*="Delete"], button[aria-label*="Delete"] { display: none !important; }';
        document.head.appendChild(style);

        // Add progress chart link to left sidebar nav
        (function() {
          var DONE = false;
          var tries = 0;
          var t = setInterval(function() {
            if (DONE || ++tries > 40) { clearInterval(t); return; }
            var navLinks = document.querySelectorAll('nav a, aside a');
            if (!navLinks.length) return;
            var parent = navLinks[0].closest('ul') || navLinks[0].parentElement;
            if (!parent) return;
            clearInterval(t);
            DONE = true;
            var el = document.createElement(parent.tagName === 'UL' ? 'li' : 'div');
            el.id = '__prog_nav_link';
            el.style.cssText = 'list-style:none;margin-top:4px;border-top:1px solid rgba(128,128,128,0.15);padding-top:4px';
            el.innerHTML = '<a href="/progress-chart.html" target="_blank" rel="noopener" style="display:flex;align-items:center;gap:8px;padding:6px 12px;text-decoration:none;color:inherit;font-size:13px;opacity:0.75;border-radius:4px;transition:opacity .15s">📈 <span>Progress Chart</span></a>';
            el.querySelector('a').addEventListener('mouseenter', function(){this.style.opacity='1';this.style.background='rgba(128,128,128,0.1)';});
            el.querySelector('a').addEventListener('mouseleave', function(){this.style.opacity='0.75';this.style.background='';});
            parent.appendChild(el);
          }, 400);
        })();
      });
    </script>
    `;

    indexHtml = indexHtml.replace('</head>', injectedScript + '</head>');
    await fs.writeFile(path.join(distDir, 'index.html'), indexHtml);

    // Download initial API data
    const apiEndpoints = [
      'tasks', 'config', 'milestones', 'docs',
      'decisions', 'drafts', 'statistics', 'status', 'statuses', 'version',
      'search', 'milestones/archived'
    ];

    console.log('Downloading API endpoints...');
    for (const ep of apiEndpoints) {
      try {
        const data = await fetchFromLocal('/api/' + ep);
        const targetPath = path.join(apiDir, ep + '.json');
        await fs.mkdir(path.dirname(targetPath), { recursive: true });
        await fs.writeFile(targetPath, sanitizeApiPayload(data));
      } catch (err) {
        console.warn('Warning: could not fetch /api/' + ep);
      }
    }

    // Merge completed tasks into tasks.json (backlog CLI only serves active tasks)
    try {
      const completedDir = path.join(process.cwd(), 'backlog', 'completed');
      const completedFiles = await fs.readdir(completedDir).catch(() => []);
      const taskFiles = completedFiles.filter(f => f.startsWith('task-') && f.endsWith('.md'));

      if (taskFiles.length > 0) {
        const tasksJsonPath = path.join(apiDir, 'tasks.json');
        const tasksData = JSON.parse(await fs.readFile(tasksJsonPath, 'utf-8'));

        for (const file of taskFiles) {
          const content = await fs.readFile(path.join(completedDir, file), 'utf-8');
          // Parse YAML frontmatter
          const fmMatch = content.match(/^---\n([\s\S]*?)\n---/);
          if (!fmMatch) continue;

          const fm = fmMatch[1];
          const get = (key) => {
            const m = fm.match(new RegExp(`^${key}:\\s*(.+)$`, 'm'));
            return m ? m[1].replace(/^['"]|['"]$/g, '').trim() : '';
          };
          const getArray = (key) => {
            const lines = fm.split('\n');
            const idx = lines.findIndex(l => l.match(new RegExp(`^${key}:`)));
            if (idx === -1) return [];
            const arr = [];
            for (let i = idx + 1; i < lines.length; i++) {
              const item = lines[i].match(/^\s+-\s+(.+)/);
              if (!item) break;
              arr.push(item[1].replace(/^['"]|['"]$/g, '').trim());
            }
            return arr;
          };

          // Extract description from body
          const bodyMatch = content.match(/---\n[\s\S]*?\n---\n([\s\S]*)/);
          const body = bodyMatch ? bodyMatch[1].trim() : '';
          const descMatch = body.match(/<!-- SECTION:DESCRIPTION:BEGIN -->\n([\s\S]*?)\n<!-- SECTION:DESCRIPTION:END -->/);
          const description = descMatch ? descMatch[1].trim() : body.split('\n## ')[0].replace(/^## Description\n*/, '').trim();

          const task = {
            id: get('id'),
            title: get('title'),
            status: get('status') || 'Done',
            assignee: getArray('assignee'),
            createdDate: get('created_date'),
            updatedDate: get('updated_date'),
            labels: getArray('labels'),
            milestone: get('milestone'),
            dependencies: getArray('dependencies'),
            references: getArray('references'),
            documentation: [],
            rawContent: body,
            acceptanceCriteriaItems: [],
            definitionOfDoneItems: [],
            description: description,
            priority: get('priority') || 'medium',
            filePath: path.join(completedDir, file),
            lastModified: new Date().toISOString(),
            source: 'local'
          };

          // Avoid duplicates
          if (!tasksData.find(t => t.id === task.id)) {
            tasksData.push(task);
            console.log(`  + Merged completed task: ${task.id} (${task.title})`);
          }
        }

        await fs.writeFile(tasksJsonPath, JSON.stringify(tasksData));
      }
    } catch (err) {
      console.warn('Warning: could not merge completed tasks:', err.message);
    }

    // Wait a brief moment to ensure Backlog has fully indexed documents and decisions
    // The backlog CLI needs time to parse the markdown files from the filesystem
    console.log('Waiting 2 seconds for Backlog server to index documents...');
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Download individual documents
    try {
      console.log('Fetching individual documents...');
      const docsJson = await fs.readFile(path.join(apiDir, 'docs.json'), 'utf-8');
      const docs = JSON.parse(docsJson);
      for (const d of docs) {
        if (d.id) {
          try {
             // The ID is strictly the string like "doc-1"
             const docId = String(d.id);
             const data = await fetchFromLocal('/api/docs/' + docId);
             
             const targetPath = path.join(apiDir, 'docs', docId + '.json');
             await fs.mkdir(path.dirname(targetPath), { recursive: true });
             await fs.writeFile(targetPath, data);
             console.log(`  - Saved document: ${docId}`);
          } catch(e) {
             console.warn(`  ! Could not fetch /api/docs/${d.id}`);
          }
        }
      }
    } catch(err) {
      console.warn("Error processing documents array: " + err.message);
    }

    // Download individual decisions
    try {
      console.log('Fetching individual decisions...');
      const decisionsJson = await fs.readFile(path.join(apiDir, 'decisions.json'), 'utf-8');
      const decisions = JSON.parse(decisionsJson);
      for (const d of decisions) {
        if (d.id) {
          try {
             const decId = String(d.id);
             const data = await fetchFromLocal('/api/decisions/' + decId);
             
             const targetPath = path.join(apiDir, 'decisions', decId + '.json');
             await fs.mkdir(path.dirname(targetPath), { recursive: true });
             await fs.writeFile(targetPath, data);
             console.log(`  - Saved decision: ${decId}`);
          } catch(e) {
             console.warn(`  ! Could not fetch /api/decisions/${d.id}`);
          }
        }
      }
    } catch(err) {
       console.warn("Error processing decisions array: " + err.message);
    }

    // Download individual milestones
    try {
      console.log('Fetching individual milestones...');
      const milestonesJson = await fs.readFile(path.join(apiDir, 'milestones.json'), 'utf-8');
      const milestones = JSON.parse(milestonesJson);
      for (const m of milestones) {
        if (m.title) {
          try {
             const encodedId = encodeURIComponent(m.title);
             const data = await fetchFromLocal('/api/milestones/' + encodedId);
             const targetPath = path.join(apiDir, 'milestones', encodedId + '.json');
             await fs.mkdir(path.dirname(targetPath), { recursive: true });
             await fs.writeFile(targetPath, data);
          } catch(e) {}
        }
      }
    } catch(err) {}

    // Write _headers for Cloudflare Pages (ensures API files return JSON content-type)
    const headersContent = "/api/*\n  Content-Type: application/json\n";
    await fs.writeFile(path.join(distDir, '_headers'), headersContent.trim());

    // Write vercel.json for Vercel deployment (ensures API files return JSON content-type and handles SPA routing)
    const vercelContent = {
      "headers": [
        {
          "source": "/api/(.*)",
          "headers": [
            {
              "key": "Content-Type",
              "value": "application/json"
            }
          ]
        }
      ],
      "rewrites": [
        {
           "source": "/(.*)",
           "destination": "/index.html"
        }
      ]
    };
    await fs.writeFile(path.join(distDir, 'vercel.json'), JSON.stringify(vercelContent, null, 2));

    // Create Cloudflare/Vercel routing fallback files
    await fs.writeFile(path.join(distDir, '_routes.json'), JSON.stringify({
      version: 1,
      include: ["/*"],
      exclude: ["/api/*"]
    }));
    await fs.writeFile(path.join(distDir, '_redirects'), '/api/* /api/:splat 200\n/* /index.html 200');

    // Copy static HTML pages from docs/ to dist/docs/
    const staticDocsDir = path.join(process.cwd(), 'docs');
    const distDocsDir = path.join(distDir, 'docs');
    await fs.mkdir(distDocsDir, { recursive: true });
    const staticDocFiles = await fs.readdir(staticDocsDir);
    for (const file of staticDocFiles) {
      if (file.endsWith('.html')) {
        await fs.copyFile(path.join(staticDocsDir, file), path.join(distDocsDir, file));
        console.log(`  Copied docs/${file} → dist/docs/${file}`);
      }
    }

    // Generate progress-chart.html from backlog/data/progress-history.json
    try {
      const historyPath = path.join(process.cwd(), 'backlog', 'data', 'progress-history.json');
      const historyData = JSON.parse(await fs.readFile(historyPath, 'utf-8'));
      // Also copy to dist/api/ for programmatic access
      await fs.writeFile(path.join(apiDir, 'progress-history.json'), JSON.stringify(historyData));

      const chartHtml = generateProgressChartHtml(historyData);
      await fs.writeFile(path.join(distDir, 'progress-chart.html'), chartHtml);
      console.log('✅ Generated dist/progress-chart.html');
    } catch (err) {
      console.warn('Warning: could not generate progress-chart.html:', err.message);
    }

    await assertExportConsistent();

    console.log('✨ Static export complete! Saved to dist/');
    console.log('🚀 You can preview it locally by running: npx serve dist');
  } finally {
    console.log('Shutting down local server...');
    // `server` is the `npx` wrapper, not the backlog process it execs. Signalling only the wrapper
    // leaves the real server listening — which is how a build from 2026-07-07 was still holding
    // port 8422 a month later and silently answering later exports with its stale cached index.
    // Kill the wrapper, then make sure the port is actually free and escalate if it isn't.
    server.kill('SIGINT');
    await new Promise(r => setTimeout(r, 800));
    try {
      const { execSync } = await import('node:child_process');
      const held = execSync(`lsof -t -nP -iTCP:${PORT} -sTCP:LISTEN || true`, { encoding: 'utf8' })
        .split('\n').map(s => s.trim()).filter(Boolean);
      for (const pid of held) {
        process.kill(Number(pid), 'SIGTERM');
        console.log(`Reaped leftover server on port ${PORT} (pid ${pid})`);
      }
    } catch (err) {
      console.warn(`Warning: could not verify port ${PORT} was released:`, err.message);
    }
  }
}

function generateProgressChartHtml(historyData) {
  const history = (historyData && historyData.history) || [];
  // Empty history -> static placeholder (no canvas to render).
  // Single-entry history is handled client-side: buildSummary falls back prev->last (delta 0),
  // and xOf/nearest guard against the length-1===0 division that would produce NaN.
  if (history.length === 0) {
    return `<!DOCTYPE html>\n<html lang="zh"><head><meta charset="UTF-8"><title>Mycelium Protocol — Phase Progress History</title></head>\n<body style="font-family:-apple-system,system-ui,sans-serif;padding:24px;color:#8B9AB0;background:#0D1117">暂无进度历史数据。</body></html>`;
  }

  return `<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Mycelium Protocol — Phase Progress History</title>
<style>
:root{--bg:#0D1117;--card-bg:#161B22;--border:#21293A;--grid:#1D2433;--text-primary:#E6EDF3;--text-secondary:#8B9AB0;--text-muted:#4A5568;--p1:#F59E0B;--p2:#22D3EE;--p3:#A78BFA;--p1-bg:rgba(245,158,11,0.10);--p2-bg:rgba(34,211,238,0.10);--p3-bg:rgba(167,139,250,0.10);--chip-border:#2D3748;--tooltip-bg:#1E2433;--tooltip-border:#2D3A50}
@media(prefers-color-scheme:light){:root{--bg:#F6F8FA;--card-bg:#FFFFFF;--border:#D0D7DE;--grid:#E8EDF4;--text-primary:#1F2937;--text-secondary:#576070;--text-muted:#9CA3AF;--p1:#D97706;--p2:#0891B2;--p3:#7C3AED;--p1-bg:rgba(217,119,6,0.08);--p2-bg:rgba(8,145,178,0.08);--p3-bg:rgba(124,58,237,0.08);--chip-border:#E5E7EB;--tooltip-bg:#FFFFFF;--tooltip-border:#D0D7DE}}
:root[data-theme="light"]{--bg:#F6F8FA;--card-bg:#FFFFFF;--border:#D0D7DE;--grid:#E8EDF4;--text-primary:#1F2937;--text-secondary:#576070;--text-muted:#9CA3AF;--p1:#D97706;--p2:#0891B2;--p3:#7C3AED;--p1-bg:rgba(217,119,6,0.08);--p2-bg:rgba(8,145,178,0.08);--p3-bg:rgba(124,58,237,0.08);--chip-border:#E5E7EB;--tooltip-bg:#FFFFFF;--tooltip-border:#D0D7DE}
:root[data-theme="dark"]{--bg:#0D1117;--card-bg:#161B22;--border:#21293A;--grid:#1D2433;--text-primary:#E6EDF3;--text-secondary:#8B9AB0;--text-muted:#4A5568;--p1:#F59E0B;--p2:#22D3EE;--p3:#A78BFA;--p1-bg:rgba(245,158,11,0.10);--p2-bg:rgba(34,211,238,0.10);--p3-bg:rgba(167,139,250,0.10);--chip-border:#2D3748;--tooltip-bg:#1E2433;--tooltip-border:#2D3A50}
*{box-sizing:border-box;margin:0;padding:0}
body{background:var(--bg);color:var(--text-primary);font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',system-ui,sans-serif;font-size:14px;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px 16px;transition:background 0.2s,color 0.2s}
.card{background:var(--card-bg);border:1px solid var(--border);border-radius:4px;width:100%;max-width:820px;overflow:hidden}
.card-header{padding:20px 24px 16px;border-bottom:1px solid var(--border);display:flex;align-items:flex-start;justify-content:space-between;gap:16px;flex-wrap:wrap}
.card-eyebrow{font-size:11px;font-weight:600;letter-spacing:0.08em;text-transform:uppercase;color:var(--text-muted);margin-bottom:4px}
.card-title{font-size:16px;font-weight:600;color:var(--text-primary)}
.summary-row{display:flex;gap:12px;flex-wrap:wrap;align-items:center}
.phase-chip{display:flex;align-items:center;gap:7px;padding:5px 10px;border-radius:4px;border:1px solid var(--chip-border)}
.phase-chip.p1{background:var(--p1-bg);border-color:rgba(245,158,11,0.25)}
.phase-chip.p2{background:var(--p2-bg);border-color:rgba(34,211,238,0.25)}
.phase-chip.p3{background:var(--p3-bg);border-color:rgba(167,139,250,0.25)}
.chip-dot{width:8px;height:8px;border-radius:50%;flex-shrink:0}
.p1 .chip-dot{background:var(--p1)}.p2 .chip-dot{background:var(--p2)}.p3 .chip-dot{background:var(--p3)}
.chip-label{font-size:11px;color:var(--text-secondary);white-space:nowrap}
.chip-value{font-size:13px;font-weight:700;font-variant-numeric:tabular-nums;letter-spacing:-0.01em}
.p1 .chip-value{color:var(--p1)}.p2 .chip-value{color:var(--p2)}.p3 .chip-value{color:var(--p3)}
.chip-delta{font-size:10px;font-variant-numeric:tabular-nums;color:var(--text-muted)}
.chip-delta.up{color:#34D399}
.chart-wrap{position:relative;padding:20px 24px 8px}
canvas{display:block;width:100%;cursor:crosshair}
.tooltip{position:absolute;pointer-events:none;background:var(--tooltip-bg);border:1px solid var(--tooltip-border);border-radius:4px;padding:10px 12px;font-size:12px;white-space:nowrap;display:none;z-index:10;box-shadow:0 4px 16px rgba(0,0,0,0.3)}
.tooltip.visible{display:block}
.tooltip-date{font-size:11px;color:var(--text-muted);margin-bottom:6px;letter-spacing:0.03em}
.tooltip-row{display:flex;align-items:center;gap:8px;margin-bottom:3px;font-variant-numeric:tabular-nums}
.tooltip-row:last-child{margin-bottom:0}
.tooltip-dot{width:7px;height:7px;border-radius:50%;flex-shrink:0}
.tooltip-name{color:var(--text-secondary);min-width:52px}
.tooltip-val{font-weight:700;color:var(--text-primary)}
.card-footer{padding:10px 24px 16px;display:flex;gap:16px;align-items:center;flex-wrap:wrap;border-top:1px solid var(--border)}
.footer-note{font-size:11px;color:var(--text-muted);flex:1}
.footer-scan{font-size:11px;color:var(--text-muted);font-variant-numeric:tabular-nums}
.back-link{position:fixed;top:16px;left:16px;font-size:12px;color:var(--text-muted);text-decoration:none;padding:6px 10px;border:1px solid var(--border);border-radius:4px;background:var(--card-bg)}
.back-link:hover{color:var(--text-primary)}
</style>
</head>
<body>
<a class="back-link" href="/">← Dashboard</a>
<div class="card">
  <div class="card-header">
    <div>
      <div class="card-eyebrow">Mycelium Protocol</div>
      <div class="card-title">Phase Progress — Historical Trend</div>
    </div>
    <div class="summary-row" id="summaryRow"></div>
  </div>
  <div class="chart-wrap">
    <canvas id="chart" height="300"></canvas>
    <div class="tooltip" id="tooltip">
      <div class="tooltip-date" id="tipDate"></div>
      <div class="tooltip-row"><div class="tooltip-dot" style="background:var(--p1)"></div><span class="tooltip-name">Phase 1</span><span class="tooltip-val" id="tipP1"></span></div>
      <div class="tooltip-row"><div class="tooltip-dot" style="background:var(--p2)"></div><span class="tooltip-name">Phase 2</span><span class="tooltip-val" id="tipP2"></span></div>
      <div class="tooltip-row"><div class="tooltip-dot" style="background:var(--p3)"></div><span class="tooltip-name">Phase 3</span><span class="tooltip-val" id="tipP3"></span></div>
    </div>
  </div>
  <div class="card-footer">
    <span class="footer-note">进度算法：Done=100%，In Progress=实际估算值，To Do=0%，取 Phase 内所有任务算术平均</span>
    <span class="footer-scan" id="footerScan"></span>
  </div>
</div>
<script>
const HISTORY=${JSON.stringify(history)};
const PAD={top:20,right:24,bottom:40,left:44};
const MAX_Y=100;
function css(v){return getComputedStyle(document.documentElement).getPropertyValue(v).trim()}
function buildSummary(){
  const last=HISTORY[HISTORY.length-1],prev=HISTORY[HISTORY.length-2]||last;
  const row=document.getElementById('summaryRow');
  [{key:'p1',cls:'p1',label:'Phase 1'},{key:'p2',cls:'p2',label:'Phase 2'},{key:'p3',cls:'p3',label:'Phase 3'}].forEach(p=>{
    const val=last[p.key],diff=val-prev[p.key];
    row.innerHTML+=\`<div class="phase-chip \${p.cls}"><div class="chip-dot"></div><span class="chip-label">\${p.label}</span><span class="chip-value">\${val}%</span><span class="chip-delta \${diff>0?'up':'same'}">\${diff>0?'+'+diff+'%':diff<0?diff+'%':'—'}</span></div>\`;
  });
}
document.getElementById('footerScan').textContent='最后扫描: '+HISTORY[HISTORY.length-1].date+'  |  '+HISTORY.length+' 次记录';
const canvas=document.getElementById('chart'),ctx=canvas.getContext('2d');
const tooltip=document.getElementById('tooltip');
let W,H,chartW,chartH,activeIdx=-1;
function resize(){
  const rect=canvas.parentElement.getBoundingClientRect(),dpr=window.devicePixelRatio||1;
  W=rect.width-48;H=300;
  canvas.width=W*dpr;canvas.height=H*dpr;
  canvas.style.width=W+'px';canvas.style.height=H+'px';
  ctx.scale(dpr,dpr);chartW=W-PAD.left-PAD.right;chartH=H-PAD.top-PAD.bottom;draw();
}
function xOf(i){return PAD.left+(HISTORY.length>1?i/(HISTORY.length-1):0)*chartW}
function yOf(v){return PAD.top+(1-v/MAX_Y)*chartH}
function fmtDate(d){const[y,m,day]=d.split('-');const mo=['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];return mo[parseInt(m)]+' '+parseInt(day)+', '+y}
function draw(){
  ctx.clearRect(0,0,W,H);
  const c={p1:css('--p1'),p2:css('--p2'),p3:css('--p3'),grid:css('--grid'),tm:css('--text-muted'),border:css('--border'),cbg:css('--card-bg')};
  [0,20,40,60,80,100].forEach(v=>{
    const y=yOf(v);ctx.strokeStyle=c.grid;ctx.lineWidth=1;ctx.beginPath();ctx.moveTo(PAD.left,y);ctx.lineTo(PAD.left+chartW,y);ctx.stroke();
    ctx.textAlign='right';ctx.textBaseline='middle';ctx.font='11px system-ui,sans-serif';ctx.fillStyle=c.tm;ctx.fillText(v+'%',PAD.left-8,y);
  });
  ctx.textAlign='center';ctx.textBaseline='top';ctx.fillStyle=c.tm;
  const step=Math.ceil(HISTORY.length/5);
  HISTORY.forEach((d,i)=>{if(i%step!==0&&i!==HISTORY.length-1)return;const[,m,day]=d.date.split('-');const mo=['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];ctx.fillText(mo[parseInt(m)]+' '+parseInt(day),xOf(i),PAD.top+chartH+8);});
  [{key:'p1',color:c.p1},{key:'p2',color:c.p2},{key:'p3',color:c.p3}].forEach(s=>{
    ctx.beginPath();ctx.moveTo(xOf(0),yOf(HISTORY[0][s.key]));HISTORY.forEach((d,i)=>{if(i)ctx.lineTo(xOf(i),yOf(d[s.key]));});ctx.lineTo(xOf(HISTORY.length-1),yOf(0));ctx.lineTo(xOf(0),yOf(0));ctx.closePath();
    const g=ctx.createLinearGradient(0,PAD.top,0,PAD.top+chartH);const h=s.color.replace('#','');const r=parseInt(h.substr(0,2),16),gr=parseInt(h.substr(2,2),16),b=parseInt(h.substr(4,2),16);
    g.addColorStop(0,'rgba('+r+','+gr+','+b+',0.12)');g.addColorStop(1,'rgba('+r+','+gr+','+b+',0.01)');ctx.fillStyle=g;ctx.fill();
  });
  [{key:'p1',color:c.p1},{key:'p2',color:c.p2},{key:'p3',color:c.p3}].forEach(s=>{
    ctx.beginPath();ctx.strokeStyle=s.color;ctx.lineWidth=2;ctx.lineJoin='round';ctx.lineCap='round';
    HISTORY.forEach((d,i)=>{const x=xOf(i),y=yOf(d[s.key]);if(i===0)ctx.moveTo(x,y);else ctx.lineTo(x,y);});ctx.stroke();
    const di=[HISTORY.length-1];if(activeIdx>=0&&activeIdx!==HISTORY.length-1)di.push(activeIdx);
    di.forEach(i=>{ctx.beginPath();ctx.arc(xOf(i),yOf(HISTORY[i][s.key]),activeIdx===i?5:4,0,Math.PI*2);ctx.fillStyle=s.color;ctx.fill();ctx.strokeStyle=c.cbg;ctx.lineWidth=2;ctx.stroke();});
  });
  if(activeIdx>=0){ctx.strokeStyle=c.border;ctx.lineWidth=1;ctx.setLineDash([4,3]);ctx.beginPath();ctx.moveTo(xOf(activeIdx),PAD.top);ctx.lineTo(xOf(activeIdx),PAD.top+chartH);ctx.stroke();ctx.setLineDash([]);}
}
function nearest(mx){if(HISTORY.length<2)return 0;return Math.max(0,Math.min(HISTORY.length-1,Math.round((mx-PAD.left)/chartW*(HISTORY.length-1))))}
canvas.addEventListener('mousemove',e=>{
  const rect=canvas.getBoundingClientRect(),mx=e.clientX-rect.left,my=e.clientY-rect.top;
  if(mx<PAD.left||mx>PAD.left+chartW||my<PAD.top||my>PAD.top+chartH){activeIdx=-1;tooltip.classList.remove('visible');draw();return;}
  activeIdx=nearest(mx);const d=HISTORY[activeIdx];
  document.getElementById('tipDate').textContent=fmtDate(d.date);
  document.getElementById('tipP1').textContent=d.p1+'%';document.getElementById('tipP2').textContent=d.p2+'%';document.getElementById('tipP3').textContent=d.p3+'%';
  const tx=xOf(activeIdx)+48,tipW=180,left=(tx+tipW>W+48)?tx-tipW-16:tx;
  tooltip.style.left=left+'px';tooltip.style.top=(PAD.top+8)+'px';tooltip.classList.add('visible');draw();
});
canvas.addEventListener('mouseleave',()=>{activeIdx=-1;tooltip.classList.remove('visible');draw();});
buildSummary();resize();
window.addEventListener('resize',()=>{ctx.resetTransform();resize();});
new MutationObserver(()=>draw()).observe(document.documentElement,{attributes:true,attributeFilter:['data-theme']});
window.matchMedia('(prefers-color-scheme:dark)').addEventListener('change',()=>draw());
<\/script>
</body>
</html>`;
}

// Exit non-zero on failure — `pnpm run build` must not report success when the export threw
// (the consistency check is worthless if a failing build still looks green).
withDeterministicConfig(exportStaticBacklog).catch(err => {
  console.error(err);
  process.exitCode = 1;
});
