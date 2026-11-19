const dayMs = 86_400_000;
export const counterTimeZone = 'America/Los_Angeles';
const pacificCalendar = new Intl.DateTimeFormat('en', {
  timeZone: counterTimeZone, year: 'numeric', month: '2-digit', day: '2-digit',
});

export function calendarDate(instant) {
  const parts = Object.fromEntries(pacificCalendar.formatToParts(instant).map(({ type, value }) => [type, value]));
  return `${parts.year}-${parts.month}-${parts.day}`;
}

function midnight(date) {
  return new Date(`${date}T00:00:00Z`);
}

export function validDate(date) {
  if (typeof date !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(date)) return false;
  const instant = midnight(date);
  return Number.isFinite(instant.getTime()) && instant.toISOString().slice(0, 10) === date;
}

function monthAnniversary(start, months) {
  const last = new Date(start);
  last.setUTCMonth(start.getUTCMonth() + months + 1, 0);
  const result = new Date(start);
  result.setUTCMonth(start.getUTCMonth() + months, Math.min(start.getUTCDate(), last.getUTCDate()));
  return result;
}

export function elapsed(from, to) {
  const start = midnight(from);
  const today = midnight(to);
  if (today <= start) return [[0, 'day']];
  let months = (today.getUTCFullYear() - start.getUTCFullYear()) * 12 + today.getUTCMonth() - start.getUTCMonth();
  if (monthAnniversary(start, months) > today) months--;
  let days = (today - monthAnniversary(start, months)) / dayMs;
  const years = Math.floor(months / 12);
  const weeks = years ? 0 : Math.floor(days / 7);
  if (weeks) days %= 7;
  return [[years, 'year'], [months % 12, 'month'], [weeks, 'week'], [days, 'day']].filter(([count]) => count > 0);
}
