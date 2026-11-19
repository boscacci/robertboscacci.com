import { elapsed } from './calendar.mjs';

const counter = document.querySelector('#elapsed');
const since = document.querySelector('#since');
const status = document.querySelector('#counter-status');
const reset = document.querySelector('#reset');
const button = document.querySelector('#reset-button');
const label = document.querySelector('#reset-label');
const hint = document.querySelector('#reset-status');
const history = document.querySelector('#reset-history');
const historyRecent = document.querySelector('#reset-recent');
const historyTotal = document.querySelector('#reset-total');
const historyNote = document.querySelector('#history-note');
const dots = [...button.querySelectorAll('.steps i')];
const motion = matchMedia('(prefers-reduced-motion: reduce)');
const dateLabel = new Intl.DateTimeFormat('en', { dateStyle: 'full', timeZone: 'UTC' });
const numberLabel = new Intl.NumberFormat('en');
let token = null;
let expiry;
let remaining = dots.length;
let queued = 0;
let busy = false;
let refreshing = false;
let version = 0;
let previous;
let apiOrigin;

function display({ start, today, canReset, resetHistory }) {
  status.hidden = true;
  reset.hidden = !canReset;
  history.hidden = !canReset || !resetHistory;
  if (!history.hidden) {
    historyRecent.textContent = numberLabel.format(resetHistory.past30Days);
    historyTotal.textContent = numberLabel.format(resetHistory.total);
    historyNote.hidden = !resetHistory.hasUndatedResets;
  }
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

function progress(left, message) {
  label.textContent = left === 0 ? 'Resetting…' : left === 1 ? 'Confirm reset' : 'Reset to today';
  button.toggleAttribute('data-final', left <= 1);
  button.setAttribute('aria-disabled', String(left === 0));
  dots.forEach((dot, index) => dot.toggleAttribute('data-filled', index < dots.length - left));
  hint.textContent = message;
}

function clearConfirmation(message) {
  clearTimeout(expiry);
  token = null;
  remaining = dots.length;
  queued = 0;
  progress(remaining, message);
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
    history.hidden = true;
  } finally {
    refreshing = false;
  }
}

async function sendConfirmations() {
  busy = true;
  try {
    // Each confirmation consumes the token returned by the previous one.
    while (queued) {
      const response = await fetch(`${apiOrigin}/api/reset`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ token }), signal: AbortSignal.timeout(6000),
      });
      if (response.status === 409) {
        clearConfirmation('Confirmation expired. Click five times to start again.');
        return;
      }
      if (!response.ok) throw new Error('reset_unavailable');
      const data = await response.json();
      if (!data.token) {
        display(data);
        clearConfirmation('Counter reset to today for everyone.');
        return;
      }
      token = data.token;
      remaining = data.remaining;
      queued--;
    }
    expiry = setTimeout(() => clearConfirmation('Confirmation expired. Click five times to start again.'), 30_000);
  } catch {
    clearConfirmation('Connection interrupted. Checking the counter.');
  } finally {
    busy = false;
    void refresh();
  }
}

button.addEventListener('keydown', event => {
  if (event.repeat && (event.key === 'Enter' || event.key === ' ')) event.preventDefault();
});
button.addEventListener('click', event => {
  if (reset.hidden || queued >= remaining) return;
  clearTimeout(expiry);
  version++;
  const left = remaining - ++queued;
  progress(left, left === 0 ? 'Saving the reset…' : left === 1
    ? 'One more click resets the counter for everyone.'
    : `${left} more clicks to reset for everyone.`);
  if (!busy) void sendConfirmations();
  if (event.pointerType === 'touch') navigator.vibrate?.(left === 0 ? 28 : 12);
  if (!motion.matches) dots[dots.length - left - 1].animate?.(
    [{ transform: 'scale(.6)' }, { transform: 'scale(1.22)', offset: .55 }, { transform: 'scale(1)' }],
    { duration: 155, easing: 'ease-out' },
  );
});

void refresh();
setInterval(() => { if (!document.hidden) void refresh(); }, 10_000);
document.addEventListener('visibilitychange', () => { if (!document.hidden) void refresh(); });
