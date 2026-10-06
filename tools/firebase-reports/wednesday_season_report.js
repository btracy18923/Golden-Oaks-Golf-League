// Wednesday League season results report — one row per Wednesday member:
// last name, final handicap, rounds played, and that member's season winnings
// (Closest Pin, Individual, Group, and their Total). Sorted by handicap, lowest
// first. Members who didn't play any rounds this season are left out.
//
// Data sources: only dates with a W_results doc count (one doc per date).
// W_results gives who played, Closest Pin and Group money. W_player_scores
// gives IND money, because W_results always saved it as 0. Final HC comes
// from W_player_profile. Only roster members (league 'wednesday' or 'both')
// are listed; guests are left out. The script prints anything it couldn't
// account for.
//
// SETUP (one-time):
//   1. Firebase Console -> gear icon -> Project Settings -> Service Accounts
//      -> "Generate new private key". Save the downloaded file as
//      serviceAccountKey.json in this same folder (tools/firebase-reports).
//      This file grants full read/write access to the database — never
//      share it or commit it to git (it's already in .gitignore).
//
// RUN:
//   node wednesday_season_report.js          (defaults to 2026)
//   node wednesday_season_report.js 2027     (any other season)
//
// OUTPUT (in this same folder):
//   wednesday_<year>_results.html — open in a browser, select all, copy, and
//                                   paste into the body of an email
//   wednesday_<year>_results.csv  — same data for Excel/Sheets

const fs = require('fs');
const path = require('path');
// firebase-admin v14 dropped the old admin.credential namespace; use the
// modular entry points
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const SEASON = process.argv[2] || '2026';
const SERVICE_ACCOUNT_PATH = path.join(__dirname, 'serviceAccountKey.json');
const HTML_PATH = path.join(__dirname, `wednesday_${SEASON}_results.html`);
const CSV_PATH = path.join(__dirname, `wednesday_${SEASON}_results.csv`);
const TITLE = `Goldenoaks Wednesday League ${SEASON} Season Results`;

if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
  console.error(
    'Missing serviceAccountKey.json in this folder.\n' +
    'Get it from: Firebase Console -> Project Settings -> Service Accounts -> Generate new private key.\n' +
    `Save it as: ${SERVICE_ACCOUNT_PATH}`
  );
  process.exit(1);
}

initializeApp({
  credential: cert(require(SERVICE_ACCOUNT_PATH)),
});

const db = getFirestore();

function parseCurrency(value) {
  if (value === null || value === undefined) return 0;
  const num = parseFloat(String(value).replace(/[$,]/g, ''));
  return Number.isFinite(num) ? num : 0;
}

function csvEscape(value) {
  const str = String(value ?? '');
  if (str.includes(',') || str.includes('"') || str.includes('\n')) {
    return '"' + str.replace(/"/g, '""') + '"';
  }
  return str;
}

function htmlEscape(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

function money(amount) {
  return '$' + amount.toFixed(2);
}

// Names are matched case-insensitively with surrounding spaces ignored
function key(name) {
  return String(name ?? '').trim().toLowerCase();
}

// Misspelled names in saved data -> the roster's last name
const NAME_FIXES = {
  rolphing: 'Rohlfing',
};

async function main() {
  // --- Members (league 'wednesday' or 'both') ---
  console.log('Fetching W_player_profile...');
  const profileSnapshot = await db.collection('W_player_profile').get();

  const players = {}; // key(last) -> player
  function getPlayer(rawName) {
    const fixed = NAME_FIXES[key(rawName)] || rawName;
    const k = key(fixed);
    if (!players[k]) {
      players[k] = {
        name: String(fixed).trim(),
        hc: null,
        member: false,
        rounds: {}, // date -> { pin, ind, group, inResults, inScores }
      };
    }
    return players[k];
  }
  function getRound(rawName, date) {
    const p = getPlayer(rawName);
    if (!p.rounds[date]) p.rounds[date] = { pin: 0, ind: 0, group: 0, inResults: false, inScores: false };
    return p.rounds[date];
  }

  profileSnapshot.forEach((doc) => {
    const data = doc.data();
    const league = String(data.league || '').toLowerCase();
    if (league !== 'wednesday' && league !== 'both') return;
    if (!data.last) return;
    const p = getPlayer(data.last);
    p.member = true;
    const hc = parseFloat(data.HC);
    p.hc = Number.isFinite(hc) ? hc : null;
  });

  // --- W_results: one doc per date. Source for who played, Closest Pin and
  // Group money. Its individual_winnings is always saved as 0, so IND comes
  // from W_player_scores instead. ---
  console.log(`Fetching W_results for ${SEASON}...`);
  const resultsSnapshot = await db.collection('W_results').get();
  const resultDates = new Set();

  resultsSnapshot.forEach((doc) => {
    const data = doc.data();
    const date = String(data.date || doc.id).slice(0, 10);
    if (!date.startsWith(SEASON)) return;
    resultDates.add(date);

    // individual_results lists every player that night, winners or not
    for (const r of data.individual_results || []) {
      if (r && r.name) getRound(r.name, date).inResults = true;
    }
    for (const w of data.closest_pin_winners || []) {
      if (!w || !w.name) continue;
      const round = getRound(w.name, date);
      round.inResults = true;
      round.pin += parseCurrency(w.amount);
    }
    // group_winnings is the per-player prize; a wildcard in several groups
    // collects from each
    for (const g of data.group_results || []) {
      if (!g) continue;
      const perPlayer = parseCurrency(g.group_winnings);
      for (const name of g.players || []) {
        if (!name) continue;
        const round = getRound(name, date);
        round.inResults = true;
        round.group += perPlayer;
      }
    }
  });

  // --- W_player_scores: one doc per player per date. Source for IND money
  // only, and only on dates that have a W_results doc (dates without one,
  // like the 5/20 opener and the 7/22 rainout, aren't counted). Capped at 15
  // rounds per player, so a regular's earliest rounds may be gone. ---
  console.log('Fetching W_player_scores...');
  const scoresSnapshot = await db.collection('W_player_scores').get();
  const skippedDates = new Set();
  scoresSnapshot.forEach((doc) => {
    const data = doc.data();
    const date = String(data.date_played || '').slice(0, 10);
    if (!date.startsWith(SEASON) || !data.name) return;
    if (!resultDates.has(date)) {
      skippedDates.add(date);
      return;
    }
    const round = getRound(data.name, date);
    round.inScores = true;
    round.ind = parseCurrency(data.single_winnings);
  });
  const seasonDates = resultDates.size;

  // --- Things to double-check ---
  const warnings = [];
  if (skippedDates.size) {
    warnings.push(`Not counted (no weekly results saved): ${[...skippedDates].sort().join(', ')}`);
  }
  for (const p of Object.values(players)) {
    if (!p.member) {
      warnings.push(`${p.name}: played in ${SEASON} but is not a Wednesday member — left out of the report`);
      continue;
    }
    const lost = Object.entries(p.rounds).filter(([, r]) => r.inResults && !r.inScores).map(([d]) => d);
    if (lost.length) warnings.push(`${p.name}: score row deleted (15-round cap) for ${lost.sort().join(', ')} — IND money for that round is not included`);
  }

  // --- Build rows for roster members who played at least one round, lowest
  // handicap first (no HC sorts last) ---
  const rows = Object.values(players).filter((p) => p.member && Object.keys(p.rounds).length > 0).map((p) => {
    const rounds = Object.values(p.rounds);
    const sum = (field) => rounds.reduce((t, r) => t + r[field], 0);
    const pin = sum('pin');
    const ind = sum('ind');
    const group = sum('group');
    return { name: p.name, hc: p.hc, played: rounds.length, pin, ind, group, total: pin + ind + group };
  });
  rows.sort((a, b) => {
    if (a.hc === null && b.hc !== null) return 1;
    if (b.hc === null && a.hc !== null) return -1;
    if (a.hc !== b.hc) return a.hc - b.hc;
    return a.name.localeCompare(b.name);
  });

  const totals = rows.reduce(
    (t, r) => ({ pin: t.pin + r.pin, ind: t.ind + r.ind, group: t.group + r.group, total: t.total + r.total }),
    { pin: 0, ind: 0, group: 0, total: 0 }
  );

  // --- CSV ---
  const header = ['Name', 'Final HC', '# Played', 'ClosestPin $$', 'IND $$', 'Group $$', 'Total $$'];
  const csvLines = [header.join(',')];
  for (const r of rows) {
    csvLines.push([
      csvEscape(r.name),
      r.hc === null ? '' : r.hc.toFixed(1),
      r.played,
      r.pin.toFixed(2),
      r.ind.toFixed(2),
      r.group.toFixed(2),
      r.total.toFixed(2),
    ].join(','));
  }
  fs.writeFileSync(CSV_PATH, csvLines.join('\n'), 'utf8');

  // --- HTML (inline styles so it survives pasting into an email) ---
  // Width and padding are repeated as HTML attributes (width, cellpadding)
  // because email programs often strip CSS when the table is pasted in
  const th = (w) => `style="background:#2e5e2e;color:#ffffff;padding:8px 12px;border:1px solid #999;text-align:center;width:${w}px;white-space:nowrap;"`;
  const tdL = 'padding:8px 12px;white-space:nowrap;border:1px solid #ccc;text-align:left;';
  const tdR = 'padding:8px 12px;white-space:nowrap;border:1px solid #ccc;text-align:right;';
  const bodyRows = rows.map((r, i) => {
    const bg = i % 2 ? 'background:#f2f7f2;' : 'background:#ffffff;';
    return `    <tr>
      <td style="${tdL}${bg}">${htmlEscape(r.name)}</td>
      <td style="${tdR}${bg}">${r.hc === null ? '' : r.hc.toFixed(1)}</td>
      <td style="${tdR}${bg}">${r.played}</td>
      <td style="${tdR}${bg}">${money(r.pin)}</td>
      <td style="${tdR}${bg}">${money(r.ind)}</td>
      <td style="${tdR}${bg}">${money(r.group)}</td>
      <td style="${tdR}${bg}font-weight:bold;">${money(r.total)}</td>
    </tr>`;
  }).join('\n');

  const html = `<!doctype html>
<html>
<head><meta charset="utf-8"><title>${htmlEscape(TITLE)}</title></head>
<body style="font-family:Arial,Helvetica,sans-serif;font-size:14px;color:#222;">
  <div style="font-size:28px;font-weight:bold;color:#2e5e2e;">${htmlEscape(TITLE)}</div>
  <br>
  <table cellpadding="8" cellspacing="0" border="1" width="760" style="border-collapse:collapse;font-size:14px;width:760px;border-color:#999;">
    <tr>
      <th width="140" ${th(140)}>Name</th>
      <th width="90" ${th(90)}>Final HC</th>
      <th width="90" ${th(90)}># Played</th>
      <th width="120" ${th(120)}>ClosestPin $$</th>
      <th width="100" ${th(100)}>IND $$</th>
      <th width="100" ${th(100)}>Group $$</th>
      <th width="120" ${th(120)}>Total $$</th>
    </tr>
${bodyRows}
  </table>
</body>
</html>
`;
  fs.writeFileSync(HTML_PATH, html, 'utf8');

  console.log(`\nDone. ${rows.length} players, ${seasonDates} Wednesday dates in ${SEASON}.`);
  console.log(`Season payouts: ${money(totals.total)} (Pin ${money(totals.pin)}, IND ${money(totals.ind)}, Group ${money(totals.group)})`);
  console.log(HTML_PATH);
  console.log(CSV_PATH);
  if (warnings.length) {
    console.log(`\nCHECK THESE (${warnings.length}):`);
    for (const w of warnings) console.log('  - ' + w);
  }
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Error generating report:', err);
    process.exit(1);
  });
