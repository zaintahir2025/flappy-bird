const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn, execSync } = require('child_process');

const PORT = 8099;
const WEB_DIR = path.resolve(__dirname, '..', 'build', 'web');
const OUTPUT_VIDEO = path.resolve(__dirname, '..', 'flappy_bird_gameplay.mp4');
const FRAMES_DIR = path.resolve(__dirname, '..', '.tmp_frames');
const CHROME_PATH = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const FFMPEG_PATH = 'C:\\Users\\Zain\\AppData\\Local\\Microsoft\\WinGet\\Links\\ffmpeg.exe';
const BGM_PATH = path.resolve(__dirname, '..', 'assets', 'audio', 'bgm.mp3');

const MIME_TYPES = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.mp3': 'audio/mpeg',
  '.css': 'text/css',
};

function startServer() {
  return new Promise((resolve) => {
    const server = http.createServer((req, res) => {
      let p = decodeURI(req.url.split('?')[0]);
      if (p === '/') p = '/index.html';
      const fp = path.join(WEB_DIR, p);
      if (fs.existsSync(fp) && !fs.statSync(fp).isDirectory()) {
        const ext = path.extname(fp).toLowerCase();
        res.writeHead(200, {
          'Content-Type': MIME_TYPES[ext] || 'application/octet-stream',
          'Cross-Origin-Embedder-Policy': 'require-corp',
          'Cross-Origin-Opener-Policy': 'same-origin',
        });
        fs.createReadStream(fp).pipe(res);
      } else {
        res.writeHead(404);
        res.end();
      }
    });

    server.listen(PORT, () => {
      console.log(`[Server] Serving build/web at http://localhost:${PORT}`);
      resolve(server);
    });
  });
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function main() {
  if (fs.existsSync(OUTPUT_VIDEO)) {
    try { fs.unlinkSync(OUTPUT_VIDEO); } catch (_) {}
  }
  if (fs.existsSync(FRAMES_DIR)) {
    fs.rmSync(FRAMES_DIR, { recursive: true, force: true });
  }
  fs.mkdirSync(FRAMES_DIR, { recursive: true });

  const server = await startServer();

  console.log('[Chrome] Launching Chrome headless...');
  const chrome = spawn(CHROME_PATH, [
    '--remote-debugging-port=9230',
    '--headless=new',
    '--window-size=480,854',
    '--no-first-run',
    '--no-default-browser-check',
    '--disable-extensions',
    `http://localhost:${PORT}`,
  ]);

  await sleep(2500);

  const res = await fetch('http://localhost:9230/json');
  const tabs = await res.json();
  const page = tabs.find((t) => t.type === 'page');
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  await new Promise((r) => (ws.onopen = r));

  let msgId = 1;
  const pending = new Map();
  ws.onmessage = (e) => {
    try {
      const msg = JSON.parse(e.data);
      if (msg.id && pending.has(msg.id)) {
        const cb = pending.get(msg.id);
        pending.delete(msg.id);
        cb(msg.result);
      }
    } catch (_) {}
  };

  function call(method, params = {}) {
    return new Promise((resolve) => {
      const id = msgId++;
      pending.set(id, resolve);
      ws.send(JSON.stringify({ id, method, params }));
    });
  }

  await call('Page.enable');
  await call('Emulation.setDeviceMetricsOverride', {
    width: 480,
    height: 854,
    deviceScaleFactor: 1.5,
    mobile: false,
  });

  console.log('[Gameplay] Waiting 4s for Flutter engine & shaders...');
  await sleep(4000);

  async function triggerFlap() {
    call('Input.dispatchKeyEvent', {
      type: 'rawKeyDown',
      key: ' ',
      code: 'Space',
      windowsVirtualKeyCode: 32,
    });
    call('Input.dispatchMouseEvent', {
      type: 'mousePressed',
      x: 240,
      y: 420,
      button: 'left',
      clickCount: 1,
    });
    await sleep(45);
    call('Input.dispatchKeyEvent', {
      type: 'keyUp',
      key: ' ',
      code: 'Space',
      windowsVirtualKeyCode: 32,
    });
    call('Input.dispatchMouseEvent', {
      type: 'mouseReleased',
      x: 240,
      y: 420,
      button: 'left',
      clickCount: 1,
    });
  }

  async function triggerEnter() {
    call('Input.dispatchKeyEvent', {
      type: 'rawKeyDown',
      key: 'Enter',
      code: 'Enter',
      windowsVirtualKeyCode: 13,
    });
    await sleep(40);
    call('Input.dispatchKeyEvent', {
      type: 'keyUp',
      key: 'Enter',
      code: 'Enter',
      windowsVirtualKeyCode: 13,
    });
  }

  console.log('[Recording] Starting real-time frame capture loop...');
  let isRecording = true;
  const frameTimes = [];
  let frameIdx = 0;

  // Background frame grabber
  const capturePromise = (async () => {
    while (isRecording) {
      const t = Date.now();
      try {
        const res = await call('Page.captureScreenshot', {
          format: 'jpeg',
          quality: 85,
        });
        if (res && res.data) {
          const fn = `frame_${String(frameIdx).padStart(5, '0')}.jpg`;
          fs.writeFileSync(path.join(FRAMES_DIR, fn), Buffer.from(res.data, 'base64'));
          frameTimes.push({ file: fn, time: t });
          frameIdx++;
        }
      } catch (_) {}
    }
  })();

  // Choreographed gameplay progression
  console.log('[Gameplay] Scene 1: Ready Screen title & animations (2.5s)...');
  await sleep(2500);

  console.log('[Gameplay] Scene 2: Takeoff jump...');
  await triggerFlap();
  await sleep(500);
  await triggerEnter(); // Dismiss callsign dialog if shown
  await sleep(300);
  await triggerFlap();
  await sleep(450);

  console.log('[Gameplay] Scene 3: Flight navigation through Aero Pylons...');
  const flaps = [
    430, 480, 440, 500, 450, 430, 470, 450, 440, 480, 430, 470, 440, 480,
  ];
  for (let i = 0; i < flaps.length; i++) {
    await triggerFlap();
    console.log(`[Gameplay] Flap ${i + 1}/${flaps.length}`);
    await sleep(flaps[i]);
  }

  console.log('[Gameplay] Scene 4: Descending into obstacle...');
  await sleep(2200);

  console.log('[Gameplay] Scene 5: Game Over scoreboard celebration (3.5s)...');
  await sleep(3500);

  console.log('[Gameplay] Scene 6: Play Again restart...');
  await triggerFlap(); // Taps PLAY AGAIN
  await sleep(1000);
  await triggerFlap(); // New flight jump
  await sleep(500);
  await triggerFlap();
  await sleep(2000);

  console.log('[Recording] Finishing recording...');
  isRecording = false;
  await capturePromise;

  ws.close();
  chrome.kill();
  server.close();

  console.log(`[Recording] Total captured frames: ${frameTimes.length}`);

  if (frameTimes.length < 5) {
    console.error('[Error] Not enough frames captured.');
    process.exit(1);
  }

  // Generate ffconcat manifest with exact durations
  console.log('[FFmpeg] Generating ffconcat timeline with accurate timestamps...');
  const concatLines = ['ffconcat version 1.0'];
  for (let i = 0; i < frameTimes.length; i++) {
    concatLines.push(`file '${frameTimes[i].file}'`);
    if (i < frameTimes.length - 1) {
      const dur = Math.max(0.02, (frameTimes[i + 1].time - frameTimes[i].time) / 1000);
      concatLines.push(`duration ${dur.toFixed(4)}`);
    } else {
      concatLines.push('duration 0.05');
    }
  }
  // Repeat last frame per ffconcat spec
  concatLines.push(`file '${frameTimes[frameTimes.length - 1].file}'`);

  const concatPath = path.join(FRAMES_DIR, 'manifest.txt');
  fs.writeFileSync(concatPath, concatLines.join('\n'));

  // Encode with FFmpeg
  console.log('[FFmpeg] Encoding high-definition MP4 video with arcade background music...');
  const ffmpegCmd = [
    `"${FFMPEG_PATH}"`,
    '-y',
    '-safe', '0',
    '-i', `"${concatPath}"`,
    '-stream_loop', '-1',
    '-i', `"${BGM_PATH}"`,
    '-c:v', 'libx264',
    '-pix_fmt', 'yuv420p',
    '-preset', 'fast',
    '-r', '30',
    '-vf', '"scale=trunc(iw/2)*2:trunc(ih/2)*2"',
    '-c:a', 'aac',
    '-b:a', '192k',
    '-shortest',
    '-movflags', '+faststart',
    `"${OUTPUT_VIDEO}"`,
  ].join(' ');

  console.log(`[FFmpeg] Running command: ${ffmpegCmd}`);
  execSync(ffmpegCmd, { stdio: 'inherit' });

  // Cleanup frame folder
  try {
    fs.rmSync(FRAMES_DIR, { recursive: true, force: true });
  } catch (_) {}

  if (fs.existsSync(OUTPUT_VIDEO)) {
    const stats = fs.statSync(OUTPUT_VIDEO);
    console.log(`\n======================================================`);
    console.log(`SUCCESS! Gameplay MP4 video successfully created!`);
    console.log(`File: ${OUTPUT_VIDEO}`);
    console.log(`Size: ${(stats.size / (1024 * 1024)).toFixed(2)} MB`);
    console.log(`======================================================\n`);
  } else {
    console.error('[Error] Final MP4 video was not created.');
    process.exit(1);
  }
}

main().catch((err) => {
  console.error('[Fatal Error]', err);
  process.exit(1);
});
