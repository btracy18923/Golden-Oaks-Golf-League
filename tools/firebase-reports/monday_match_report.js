// Monday League match report — pulls every Monday match and produces one
// CSV row per player per match: date, golf course, player, starting SKAT#,
// ending SKAT#, DIFF, money won (SKAT winnings + Closest Pin winnings), and
// number of closest pins won that match.
//
// SETUP (one-time):
//   1. Firebase Console -> gear icon -> Project Settings -> Service Accounts
//      -> "Generate new private key". Save the downloaded file as
//      serviceAccountKey.json in this same folder (tools/firebase-reports).
//      This file grants full read/write access to the database — never
//      share it or commit it to git (it's already in .gitignore).
//
// RUN:
//   node monday_match_report.js
//
// OUTPUT:
//   monday_match_report.csv in this same folder.

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const SERVICE_ACCOUNT_PATH = path.join(__dirname, 'serviceAccountKey.json');
const OUTPUT_PATH = path.join(__dirname, 'monday_match_report.csv');

if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
  console.error(
    'Missing serviceAccountKey.json in this folder.\n' +
    'Get it from: Firebase Console -> Project Settings -> Service Accounts -> Generate new private key.\n' +
    `Save it as: ${SERVICE_ACCOUNT_PATH}`
  );
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(SERVICE_ACCOUNT_PATH)),
});

const db = admin.firestore();

function parseCurrency(value) {
  if (value === null || value === undefined) return 0;
  const num = parseFloat(String(value).replace(/[$,]/g, ''));
  return Number.isFinite(num) ? num : 0;
}

function formatDate(isoDate) {
  // date_played is stored as 'YYYY-MM-DD'
  const parts = String(isoDate).split('-');
  if (parts.length !== 3) return isoDate;
  const [year, month, day] = parts;
  return `${month}/${day}/${year}`;
}

function csvEscape(value) {
  const str = String(value ?? '');
  if (str.includes(',') || str.includes('"') || str.includes('\n')) {
    return '"' + str.replace(/"/g, '""') + '"';
  }
  return str;
}

async function main() {
  console.log('Fetching M_results (for closest pin counts per match)...');
  const resultsSnapshot = await db.collection('M_results').get();

  // Map: date_played -> { playerName -> pinsCount }
  const pinsByDateAndPlayer = {};
  resultsSnapshot.forEach((doc) => {
    const data = doc.data();
    const date = data.date || doc.id;
    const winners = Array.isArray(data.closest_pin_winners) ? data.closest_pin_winners : [];
    const playerPins = {};
    for (const w of winners) {
      if (w && w.name) {
        playerPins[w.name] = w.pins || 0;
      }
    }
    pinsByDateAndPlayer[date] = playerPins;
  });

  console.log('Fetching M_player_scores (one record per player per match)...');
  const scoresSnapshot = await db.collection('M_player_scores').get();

  const rows = [];
  scoresSnapshot.forEach((doc) => {
    const data = doc.data();
    const datePlayed = data.date_played || '';
    const playerName = data.name || '';
    const golfCourse = data.golf_course || '';
    const startingSK = data.S_SK ?? '';
    const endingSK = data.New_SK ?? '';
    const diff = data.DIFF ?? '';
    const skatWinnings = parseCurrency(data['SKAT Winnings']);
    const closePinWinnings = parseCurrency(data['Close Pin Winnings']);
    const moneyWon = skatWinnings + closePinWinnings;
    const pins = (pinsByDateAndPlayer[datePlayed] && pinsByDateAndPlayer[datePlayed][playerName]) || 0;

    rows.push({
      datePlayed,
      golfCourse,
      playerName,
      startingSK,
      endingSK,
      diff,
      moneyWon,
      pins,
    });
  });

  // Sort by date ascending, then player name
  rows.sort((a, b) => {
    if (a.datePlayed !== b.datePlayed) return a.datePlayed < b.datePlayed ? -1 : 1;
    return a.playerName.localeCompare(b.playerName);
  });

  const header = [
    'Date Played',
    'Golf Course',
    'Player',
    'Starting SKAT#',
    'Ending SKAT#',
    'DIFF',
    'Money Won',
    'Closest Pins',
  ];

  const lines = [header.join(',')];
  for (const r of rows) {
    lines.push([
      csvEscape(formatDate(r.datePlayed)),
      csvEscape(r.golfCourse),
      csvEscape(r.playerName),
      csvEscape(r.startingSK),
      csvEscape(r.endingSK),
      csvEscape(r.diff),
      csvEscape(r.moneyWon.toFixed(2)),
      csvEscape(r.pins),
    ].join(','));
  }

  fs.writeFileSync(OUTPUT_PATH, lines.join('\n'), 'utf8');

  const uniqueDates = new Set(rows.map((r) => r.datePlayed)).size;
  console.log(`Done. ${rows.length} rows across ${uniqueDates} matches written to:`);
  console.log(OUTPUT_PATH);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Error generating report:', err);
    process.exit(1);
  });