import { elapsed } from './calendar.mjs';

const counter = document.querySelector('#elapsed');
const since = document.querySelector('#since');
const status = document.querySelector('#counter-status');
const reset = document.querySelector('#reset');
const button = document.querySelector('#reset-button');
const label = document.querySelector('#reset-label');
const hint = document.querySelector('#reset-status');
const dots = [...button.querySelectorAll('.steps i')];
const dateLabel = new Intl.DateTimeFormat('en', { dateStyle: 'full', timeZone: 'UTC' });
const numberLabel = new Intl.NumberFormat('en');
let token = null;
let expiry;
let busy = false;
let refreshing = false;
let version = 0;
let previous;
let apiOrigin;

function display({ start, today, canReset }) {
  status.hidden = true;
  reset.hidden = !canReset;
  if (previous?.start === start && previous.today === today) return;
  previous = { start, today };
  const started = document.createElement('time');
  started.dateTime = start;
  started.textContent = dateLabel.format(new Date(`${start}T00:00:00Z`));
  since.replaceChildren('Since ', started);
  counter.replaceChildren(...elapsed(start, today).map(([value, unit]) => {
    const tile = document.createElement('div');
    tile.className = 'unit';
    const number = document.createElement('strong');
    number.textContent = numberLabel.format(value);
    const name = document.createElement('span');
    name.textContent = value === 1 ? unit : `${unit}s`;
    tile.append(number, name);
    return tile;
  }));
}

function progress(remaining, message) {
  label.textContent = remaining === 1 ? 'Confirm reset' : 'Reset to today';
  button.toggleAttribute('data-final', remaining === 1);
  dots.forEach((dot, index) => dot.toggleAttribute('data-filled', index < 5 - remaining));
  hint.textContent = message;
}

function clearConfirmation(message) {
  clearTimeout(expiry);
  token = null;
  progress(5, message);
}

async function refresh() {
  if (busy || refreshing) return;
  const stamp = version;
  refreshing = true;
  try {
    if (apiOrigin === undefined) {
      const config = await fetch('/runtime.json', { signal: AbortSignal.timeout(6000) });
      if (!config.ok) throw new Error('configuration_unavailable');
      ({ apiOrigin } = await config.json());
    }
    const response = await fetch(`${apiOrigin}/api/counter`, { signal: AbortSignal.timeout(6000) });
    if (!response.ok) throw new Error('counter_unavailable');
    const data = await response.json();
    if (stamp === version) display(data);
  } catch {
    if (stamp !== version) return;
    if (!previous) counter.replaceChildren();
    status.textContent = 'The counter is temporarily unavailable. Retrying shortly.';
    status.hidden = false;
    reset.hidden = true;
  } finally {
    refreshing = false;
  }
}

button.addEventListener('keydown', event => {
  if (event.repeat && (event.key === 'Enter' || event.key === ' ')) event.preventDefault();
});
button.addEventListener('click', async () => {
  if (busy || reset.hidden) return;
  clearTimeout(expiry);
  version++;
  busy = true;
  button.setAttribute('aria-disabled', 'true');
  try {
    const response = await fetch(`${apiOrigin}/api/reset`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token }), signal: AbortSignal.timeout(6000),
    });
    if (response.status === 409) {
      clearConfirmation('Confirmation expired. Click five times to start again.');
    } else if (!response.ok) {
      throw new Error('reset_unavailable');
    } else {
      const data = await response.json();
      if (data.token) {
        token = data.token;
        const remaining = data.remaining;
        progress(remaining, remaining === 1
          ? 'One more click resets the counter for everyone.'
          : `${remaining} more clicks to reset for everyone.`);
        expiry = setTimeout(() => clearConfirmation('Confirmation expired. Click five times to start again.'), 30_000);
      } else {
        display(data);
        clearConfirmation('Counter reset to today for everyone.');
      }
    }
  } catch {
    clearConfirmation('Could not confirm whether the last click went through. Checking the counter.');
  } finally {
    busy = false;
    button.removeAttribute('aria-disabled');
    void refresh();
  }
});

void refresh();
setInterval(() => { if (!document.hidden) void refresh(); }, 10_000);
document.addEventListener('visibilitychange', () => { if (!document.hidden) void refresh(); });
