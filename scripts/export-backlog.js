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
    result[key] = Math.round(list.reduce((a, b) => a + b, 0) / list.length);
  }
  return result;
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

async function exportStaticBacklog() {
  console.log('Starting local backlog server for export...');
  const server = spawn('npx', ['backlog', 'browser', '--no-open', '-p', PORT.toString()], {
    stdio: 'ignore'
  });

  // Give it a few seconds to start
  await new Promise(r => setTimeout(r, 4000));

  try {
    await fs.rm(distDir, { recursive: true, force: true });
    await fs.mkdir(apiDir, { recursive: true });

    console.log('Fetching index.html...');
    const indexBuffer = await fetchFromLocal('/');
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
    for (const asset of assets.filter(a => a.endsWith('.js'))) {
      const jsPath = path.join(distDir, asset);
      let js = await fs.readFile(jsPath, 'utf-8');
      let patched = false;

      // Patch 1: Kanban column progress bar (J0 component)
      const OLD1 = 'let s0=m0.total>0?Math.round(m0.doneCount/m0.total*100):0,';
      const NEW1 = 'let s0=window.__milestoneProgress&&window.__milestoneProgress[m0.key]!==undefined?window.__milestoneProgress[m0.key]:(m0.total>0?Math.round(m0.doneCount/m0.total*100):0),';
      if (js.includes(OLD1)) {
        js = js.replace(OLD1, NEW1);
        patched = true;
        console.log(`✅ Patched Kanban column progress formula in ${asset}`);
      } else {
        console.warn(`⚠️  Could not find Kanban column progress formula in ${asset}`);
      }

      // Patch 2: Right-side milestone panel (a function in task list view)
      const OLD2 = 'a=(H0)=>{let B0=p(H0);if(B0===0)return 0;let U0=n(H0);return Math.round(U0/B0*100)},G0=N5.useMemo';
      const NEW2 = 'a=(H0)=>{if(window.__milestoneProgress&&window.__milestoneProgress[H0]!==undefined)return window.__milestoneProgress[H0];let B0=p(H0);if(B0===0)return 0;let U0=n(H0);return Math.round(U0/B0*100)},G0=N5.useMemo';
      if (js.includes(OLD2)) {
        js = js.replace(OLD2, NEW2);
        patched = true;
        console.log(`✅ Patched right-panel milestone progress formula in ${asset}`);
      } else {
        console.warn(`⚠️  Could not find right-panel milestone progress formula in ${asset}`);
      }

      if (patched) {
        await fs.writeFile(jsPath, js);
      }
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
        await fs.writeFile(targetPath, data);
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
    const headersContent = "/api/*\\n  Content-Type: application/json\\n";
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

    console.log('✨ Static export complete! Saved to dist/');
    console.log('🚀 You can preview it locally by running: npx serve dist');
  } finally {
    console.log('Shutting down local server...');
    server.kill('SIGINT');
  }
}

exportStaticBacklog().catch(console.error);
