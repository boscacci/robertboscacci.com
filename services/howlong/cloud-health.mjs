import { get } from 'node:http';

process.exitCode = 1;
const host = new URL(process.env.HOWLONG_ORIGIN).host;
const request = get({ socketPath: process.env.HOWLONG_SOCKET, path: '/healthz', headers: { Host: host }, timeout: 3000 }, response => {
  let body = '';
  response.setEncoding('utf8');
  response.on('data', chunk => { body += chunk; });
  response.on('end', () => { if (response.statusCode === 200 && body === 'howlong-ok\n') process.exitCode = 0; });
});
request.on('timeout', () => request.destroy());
request.on('error', () => {});
