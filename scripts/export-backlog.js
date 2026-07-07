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

    // Load progress history for chart injection
    let progressHistory = [];
    try {
      const histPath = path.join(process.cwd(), 'backlog', 'data', 'progress-history.json');
      progressHistory = JSON.parse(await fs.readFile(histPath, 'utf-8')).history || [];
    } catch (_) { /* optional, skip if missing */ }

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
      // Phase progress history for /statistics chart
      window.__progressHistory = ${JSON.stringify(progressHistory)};

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

        // Inject progress chart into /statistics page
        (function() {
          var PANEL_ID = '__prog_chart_panel';

          function buildPanel() {
            var H = window.__progressHistory;
            if (!H || H.length < 2) return null;
            var last = H[H.length-1], prev = H[H.length-2];
            function delta(k){var d=last[k]-prev[k];return d>0?'+'+d+'%':d<0?d+'%':'—';}
            function deltaClass(k){return last[k]-prev[k]>0?'#34D399':'#8B9AB0';}

            var wrap = document.createElement('div');
            wrap.id = PANEL_ID;
            wrap.style.cssText='margin:24px 0 0;padding:0;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",system-ui,sans-serif';

            wrap.innerHTML = [
              '<div style="border:1px solid var(--border,#e2e8f0);border-radius:4px;overflow:hidden;background:var(--card-bg,#fff)">',
              '<div style="padding:14px 20px 12px;border-bottom:1px solid var(--border,#e2e8f0);display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px">',
              '<div>',
              '<div style="font-size:10px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;color:#94a3b8;margin-bottom:3px">Mycelium Protocol</div>',
              '<div style="font-size:14px;font-weight:600">Phase Progress — Historical Trend</div>',
              '</div>',
              '<div style="display:flex;gap:10px;flex-wrap:wrap">',
              ['p1','Phase 1','#F59E0B','rgba(245,158,11,.12)'],
              ['p2','Phase 2','#22D3EE','rgba(34,211,238,.12)'],
              ['p3','Phase 3','#A78BFA','rgba(167,139,250,.12)']
              ].map(function(p){if(!Array.isArray(p))return p;
                return '<div style="display:flex;align-items:center;gap:6px;padding:4px 10px;border-radius:4px;border:1px solid '+p[2]+'44;background:'+p[3]+'">'+
                  '<div style="width:7px;height:7px;border-radius:50%;background:'+p[2]+'"></div>'+
                  '<span style="font-size:11px;color:#94a3b8">'+p[1]+'</span>'+
                  '<span style="font-size:12px;font-weight:700;color:'+p[2]+';font-variant-numeric:tabular-nums">'+last[p[0]]+'%</span>'+
                  '<span style="font-size:10px;font-variant-numeric:tabular-nums;color:'+deltaClass(p[0])+'">'+delta(p[0])+'</span>'+
                  '</div>';
              }).join('')+
              '</div></div>',
              '<div style="padding:16px 20px 8px;position:relative">',
              '<canvas id="__prog_canvas" style="display:block;width:100%;cursor:crosshair" height="240"></canvas>',
              '<div id="__prog_tip" style="position:absolute;pointer-events:none;background:#1e2433;border:1px solid #2d3a50;border-radius:4px;padding:8px 12px;font-size:12px;white-space:nowrap;display:none;z-index:10;box-shadow:0 4px 16px rgba(0,0,0,.3)">',
              '<div id="__prog_tdate" style="font-size:10px;color:#8b9ab0;margin-bottom:5px"></div>',
              '<div style="display:flex;align-items:center;gap:7px;margin-bottom:2px"><div style="width:6px;height:6px;border-radius:50%;background:#F59E0B"></div><span style="color:#8b9ab0;min-width:48px">Phase 1</span><span id="__prog_tv1" style="font-weight:700;color:#e6edf3;font-variant-numeric:tabular-nums"></span></div>',
              '<div style="display:flex;align-items:center;gap:7px;margin-bottom:2px"><div style="width:6px;height:6px;border-radius:50%;background:#22D3EE"></div><span style="color:#8b9ab0;min-width:48px">Phase 2</span><span id="__prog_tv2" style="font-weight:700;color:#e6edf3;font-variant-numeric:tabular-nums"></span></div>',
              '<div style="display:flex;align-items:center;gap:7px"><div style="width:6px;height:6px;border-radius:50%;background:#A78BFA"></div><span style="color:#8b9ab0;min-width:48px">Phase 3</span><span id="__prog_tv3" style="font-weight:700;color:#e6edf3;font-variant-numeric:tabular-nums"></span></div>',
              '</div>',
              '</div>',
              '<div style="padding:6px 20px 12px;border-top:1px solid var(--border,#e2e8f0);display:flex;justify-content:space-between;flex-wrap:wrap;gap:8px">',
              '<span style="font-size:11px;color:#94a3b8">Done=100%, In Progress=估算值, To Do=0%; Phase 内算术平均</span>',
              '<span style="font-size:11px;color:#94a3b8;font-variant-numeric:tabular-nums">最后扫描: '+last.date+'  |  '+H.length+' 次记录</span>',
              '</div>',
              '</div>'
            ].join('');
            return wrap;
          }

          function drawChart() {
            var cv = document.getElementById('__prog_canvas');
            if (!cv) return;
            var H = window.__progressHistory;
            if (!H || H.length < 2) return;
            var dpr = window.devicePixelRatio||1;
            var W = cv.parentElement.offsetWidth - 40;
            var CH = 240;
            cv.width = W*dpr; cv.height = CH*dpr;
            cv.style.width = W+'px'; cv.style.height = CH+'px';
            var ctx = cv.getContext('2d');
            ctx.scale(dpr, dpr);
            var PAD = {t:16,r:20,b:36,l:40};
            var cW = W-PAD.l-PAD.r, cH = CH-PAD.t-PAD.b;
            function xOf(i){return PAD.l+(i/(H.length-1))*cW}
            function yOf(v){return PAD.t+(1-v/100)*cH}
            // Grid
            [0,25,50,75,100].forEach(function(v){
              var y=yOf(v);
              ctx.strokeStyle='#1d2433';ctx.lineWidth=1;
              ctx.beginPath();ctx.moveTo(PAD.l,y);ctx.lineTo(PAD.l+cW,y);ctx.stroke();
              ctx.fillStyle='#4a5568';ctx.textAlign='right';ctx.textBaseline='middle';
              ctx.font='10px system-ui,sans-serif';ctx.fillText(v+'%',PAD.l-6,y);
            });
            // X labels
            var step=Math.ceil(H.length/5);
            ctx.textAlign='center';ctx.textBaseline='top';ctx.fillStyle='#4a5568';
            H.forEach(function(d,i){
              if(i%step!==0&&i!==H.length-1)return;
              var pts=d.date.split('-'),mo=['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
              ctx.fillText(mo[parseInt(pts[1])]+' '+parseInt(pts[2]),xOf(i),PAD.t+cH+6);
            });
            // Series
            var series=[{k:'p1',c:'#F59E0B'},{k:'p2',c:'#22D3EE'},{k:'p3',c:'#A78BFA'}];
            series.forEach(function(s){
              // Fill
              ctx.beginPath();ctx.moveTo(xOf(0),yOf(H[0][s.k]));
              H.forEach(function(d,i){if(i)ctx.lineTo(xOf(i),yOf(d[s.k]));});
              ctx.lineTo(xOf(H.length-1),yOf(0));ctx.lineTo(xOf(0),yOf(0));ctx.closePath();
              var g=ctx.createLinearGradient(0,PAD.t,0,PAD.t+cH);
              var hx=s.c.replace('#',''),r=parseInt(hx.substr(0,2),16),gr=parseInt(hx.substr(2,2),16),b=parseInt(hx.substr(4,2),16);
              g.addColorStop(0,'rgba('+r+','+gr+','+b+',.13)');g.addColorStop(1,'rgba('+r+','+gr+','+b+',.01)');
              ctx.fillStyle=g;ctx.fill();
              // Line
              ctx.beginPath();ctx.strokeStyle=s.c;ctx.lineWidth=2;ctx.lineJoin='round';ctx.lineCap='round';
              H.forEach(function(d,i){var x=xOf(i),y=yOf(d[s.k]);if(i===0)ctx.moveTo(x,y);else ctx.lineTo(x,y);});ctx.stroke();
              // Last dot
              var lx=xOf(H.length-1),ly=yOf(H[H.length-1][s.k]);
              ctx.beginPath();ctx.arc(lx,ly,4,0,Math.PI*2);ctx.fillStyle=s.c;ctx.fill();
              ctx.strokeStyle='#161b22';ctx.lineWidth=2;ctx.stroke();
            });
            // Hover
            cv._H=H;cv._PAD=PAD;cv._cW=cW;cv._cH=cH;cv._W=W;
          }

          function setupHover(cv) {
            if (!cv || cv._hoverReady) return;
            cv._hoverReady = true;
            var tip=document.getElementById('__prog_tip');
            var td=document.getElementById('__prog_tdate'),tv1=document.getElementById('__prog_tv1'),tv2=document.getElementById('__prog_tv2'),tv3=document.getElementById('__prog_tv3');
            cv.addEventListener('mousemove',function(e){
              var rect=cv.getBoundingClientRect(),H=cv._H,PAD=cv._PAD,cW=cv._cW,cH=cv._cH;
              if(!H)return;
              var mx=e.clientX-rect.left,my=e.clientY-rect.top;
              if(mx<PAD.l||mx>PAD.l+cW||my<PAD.t||my>PAD.t+cH){tip.style.display='none';return;}
              var idx=Math.max(0,Math.min(H.length-1,Math.round((mx-PAD.l)/cW*(H.length-1))));
              var d=H[idx];
              td.textContent=d.date;tv1.textContent=d.p1+'%';tv2.textContent=d.p2+'%';tv3.textContent=d.p3+'%';
              var tx=(mx+PAD.l+48)>(cv._W+40)?mx-180:mx+20;
              tip.style.left=tx+'px';tip.style.top='24px';tip.style.display='block';
            });
            cv.addEventListener('mouseleave',function(){tip.style.display='none';});
          }

          var injected = false;
          function tryInject() {
            if (injected || document.getElementById(PANEL_ID)) { injected=true; return; }
            if (!location.pathname.match(/statistic/i)) return;
            // Find the statistics page main container — try several selectors
            var candidates = Array.from(document.querySelectorAll('main, [class*="content"], [class*="page"], [class*="statistics"], [class*="wrapper"]'));
            var target = null;
            for (var i=0; i<candidates.length; i++) {
              var t=candidates[i], txt=t.textContent.toLowerCase();
              if((txt.includes('statistic')||txt.includes('total task')||txt.includes('complete')||txt.includes('in progress'))&&t.children.length>0){
                target=t; break;
              }
            }
            if (!target) {
              // Fallback: look for any element with numerical content that looks like stats
              var allDivs = document.querySelectorAll('div');
              for(var j=0;j<allDivs.length;j++){
                if(allDivs[j].textContent.match(/\\bstatistic/i)&&allDivs[j].offsetHeight>100){target=allDivs[j];break;}
              }
            }
            if (!target) return; // SPA not rendered yet
            var panel = buildPanel();
            if (!panel) return;
            target.appendChild(panel);
            injected = true;
            setTimeout(function(){drawChart();setupHover(document.getElementById('__prog_canvas'));},50);
          }

          function onRoute() {
            var panel=document.getElementById(PANEL_ID);
            if(panel)panel.remove();
            injected=false;
            if(location.pathname.match(/statistic/i)){
              var tries=0;
              var t=setInterval(function(){tryInject();if(injected||++tries>40)clearInterval(t);},300);
            }
          }

          // Intercept SPA navigation
          var _push=history.pushState,_replace=history.replaceState;
          history.pushState=function(){_push.apply(this,arguments);onRoute();};
          history.replaceState=function(){_replace.apply(this,arguments);onRoute();};
          window.addEventListener('popstate',onRoute);
          // Initial check
          onRoute();
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

    console.log('✨ Static export complete! Saved to dist/');
    console.log('🚀 You can preview it locally by running: npx serve dist');
  } finally {
    console.log('Shutting down local server...');
    server.kill('SIGINT');
  }
}

function generateProgressChartHtml(historyData) {
  const history = historyData.history;
  const last = history[history.length - 1];
  const prev = history[history.length - 2];

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
  const last=HISTORY[HISTORY.length-1],prev=HISTORY[HISTORY.length-2];
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
function xOf(i){return PAD.left+(i/(HISTORY.length-1))*chartW}
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
function nearest(mx){return Math.max(0,Math.min(HISTORY.length-1,Math.round((mx-PAD.left)/chartW*(HISTORY.length-1))))}
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

exportStaticBacklog().catch(console.error);
