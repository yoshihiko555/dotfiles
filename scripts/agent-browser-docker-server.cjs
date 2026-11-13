// Docker 内でのみ実行する Chromium と CDP の中継サーバー。
const fs = require('node:fs');
const net = require('node:net');
const { spawn } = require('node:child_process');

const candidates = fs.readdirSync('/ms-playwright')
  .filter(name => /^chromium-\d+$/.test(name))
  .flatMap(name => ['chrome-linux64', 'chrome-linux'].map(dir => `/ms-playwright/${name}/${dir}/chrome`));
const executable = candidates.find(path => fs.existsSync(path));
if (!executable) throw new Error('Chromium がイメージ内に見つかりません');

const browser = spawn(executable, [
  '--headless', '--no-sandbox', '--no-first-run',
  '--remote-debugging-port=9222', '--user-data-dir=/tmp/agent-browser-profile',
  'about:blank',
], { stdio: 'inherit' });

// Chrome の CDP はコンテナ内の loopback に置き、Docker が公開するポートに中継する。
const proxy = net.createServer(client => {
  const upstream = net.connect(9222, '127.0.0.1');
  client.on('error', () => upstream.destroy());
  upstream.on('error', () => client.destroy());
  client.on('close', () => upstream.destroy());
  upstream.on('close', () => client.destroy());
  client.pipe(upstream).pipe(client);
});
proxy.listen(9223, '0.0.0.0');
proxy.on('error', error => {
  console.error(error);
  browser.kill('SIGTERM');
});
browser.on('error', error => {
  console.error(error);
  process.exit(1);
});
browser.on('exit', code => process.exit(code ?? 1));
for (const signal of ['SIGTERM', 'SIGINT']) {
  process.on(signal, () => browser.kill('SIGTERM'));
}
