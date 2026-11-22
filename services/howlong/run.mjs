import { chmod } from 'node:fs/promises';
import { createCounter } from './server.mjs';

const {
  HOWLONG_ORIGIN: origin, HOWLONG_OWNER: owner, HOWLONG_STATE: database,
  HOWLONG_SOCKET: socket, HOWLONG_INITIAL_DATE: initialDate, HOWLONG_VIEW_ORIGIN: viewOrigin,
} = process.env;
try {
  if (!socket) throw new Error('missing_socket');
  const counter = await createCounter({ origin, viewOrigin, publicOrigin: process.env.HOWLONG_PUBLIC_ORIGIN, owner, database, initialDate });
  await new Promise((resolve, reject) => {
    counter.server.once('error', reject);
    counter.server.listen(socket, resolve);
  });
  await chmod(socket, 0o600);
  console.log(JSON.stringify({ event: 'howlong_ready' }));
  for (const signal of ['SIGTERM', 'SIGINT']) process.once(signal, () => {
    counter.close().catch(error => {
      console.error(JSON.stringify({ event: 'howlong_shutdown_error', code: error.code ?? 'unexpected_error' }));
      process.exitCode = 1;
    });
  });
} catch (error) {
  console.error(JSON.stringify({ event: 'howlong_startup_failed', code: error.code ?? 'configuration_or_storage', action: 'Check the service environment, private socket and counter database' }));
  process.exit(1);
}
