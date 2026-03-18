#!/usr/bin/env node
/**
 * serve-dist.js
 * Simple static file server for dist/
 * Serves on PORT (default 6420), SPA fallback to index.html
 */
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const PORT     = parseInt(process.env.PORT ?? '6420', 10);
const DIST_DIR = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', 'dist');

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js':   'application/javascript',
  '.css':  'text/css',
  '.json': 'application/json',
  '.png':  'image/png',
  '.svg':  'image/svg+xml',
  '.ico':  'image/x-icon',
};

http.createServer((req, res) => {
  let urlPath = req.url.split('?')[0];
  if (urlPath === '/') urlPath = '/index.html';

  let filePath = path.join(DIST_DIR, urlPath);

  const tryFile = (fp) => {
    try {
      const data = fs.readFileSync(fp);
      const ext  = path.extname(fp);
      res.writeHead(200, { 'Content-Type': MIME[ext] ?? 'application/octet-stream' });
      res.end(data);
      return true;
    } catch { return false; }
  };

  if (!tryFile(filePath)) {
    // SPA fallback
    tryFile(path.join(DIST_DIR, 'index.html'));
  }
}).listen(PORT, '127.0.0.1', () => {
  console.log(`Serving dist/ at http://localhost:${PORT}`);
});
