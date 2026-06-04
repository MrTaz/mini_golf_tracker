/**
 * run-tests.js
 *
 * Cross-platform wrapper that:
 *  1. Finds a JDK >= 21 on the machine (without hardcoding paths).
 *  2. Sets JAVA_HOME + prepends it to PATH for this process only.
 *  3. Spawns `firebase emulators:exec` with Jest against the local emulator.
 *
 * Works on Windows, macOS, and Linux.
 * Usage: node run-tests.js  (or npm test)
 */

'use strict';

const { execSync, spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

// ---------------------------------------------------------------------------
// Step 1: Resolve a JAVA_HOME that satisfies Java >= 21
// ---------------------------------------------------------------------------

/**
 * Returns the major version integer from a `java -version` output string,
 * e.g. "21.0.11" → 21, "1.8.0_301" → 8.
 */
function parseMajorVersion(versionOutput) {
  // java -version writes to stderr; match the version string
  const match = versionOutput.match(/version "(\d+)(?:\.(\d+))?/);
  if (!match) return 0;
  const first = parseInt(match[1], 10);
  // Old-style: "1.8" → major is second segment
  return first === 1 ? parseInt(match[2] || '0', 10) : first;
}

function javaVersionAtHome(javaHome) {
  const bin = path.join(javaHome, 'bin', os.platform() === 'win32' ? 'java.exe' : 'java');
  if (!fs.existsSync(bin)) return 0;
  try {
    // java -version outputs to stderr
    const result = spawnSync(bin, ['-version'], { encoding: 'utf8' });
    return parseMajorVersion(result.stderr || result.stdout || '');
  } catch {
    return 0;
  }
}

/**
 * Try to locate a JDK 21+ home directory using several platform-aware strategies.
 * Returns the path string, or null if none found.
 */
function findJava21Home() {
  const isWin = os.platform() === 'win32';
  const isMac = os.platform() === 'darwin';

  // ── Strategy 1: honour JAVA_HOME if already set and >= 21 ──────────────
  if (process.env.JAVA_HOME && javaVersionAtHome(process.env.JAVA_HOME) >= 21) {
    return process.env.JAVA_HOME;
  }

  // ── Strategy 2: macOS – /usr/libexec/java_home -v 21+ ──────────────────
  if (isMac) {
    try {
      const home = execSync('/usr/libexec/java_home -v 21+', { encoding: 'utf8' }).trim();
      if (home && javaVersionAtHome(home) >= 21) return home;
    } catch { /* no JDK 21 registered */ }

    // Also scan common Homebrew / SDKMAN / Temurin locations
    const macRoots = [
      '/Library/Java/JavaVirtualMachines',
      `${os.homedir()}/.sdkman/candidates/java`,
    ];
    for (const root of macRoots) {
      if (!fs.existsSync(root)) continue;
      const entries = fs.readdirSync(root)
        .map(name => ({ name, home: path.join(root, name, 'Contents', 'Home') }))
        .filter(e => fs.existsSync(e.home));
      for (const { home } of entries) {
        if (javaVersionAtHome(home) >= 21) return home;
      }
    }
  }

  // ── Strategy 3: Windows – scan known install roots ──────────────────────
  if (isWin) {
    const winRoots = [
      'C:\\Program Files\\Microsoft',          // Microsoft OpenJDK
      'C:\\Program Files\\Eclipse Adoptium',   // Temurin
      'C:\\Program Files\\Java',               // Oracle
      'C:\\Program Files\\BellSoft',           // Liberica
      'C:\\Program Files\\Azul Systems\\Zulu', // Zulu
    ];
    for (const root of winRoots) {
      if (!fs.existsSync(root)) continue;
      const dirs = fs.readdirSync(root).map(n => path.join(root, n));
      for (const dir of dirs) {
        if (javaVersionAtHome(dir) >= 21) return dir;
      }
    }
  }

  // ── Strategy 4: Linux – scan /usr/lib/jvm ──────────────────────────────
  const linuxRoot = '/usr/lib/jvm';
  if (!isWin && !isMac && fs.existsSync(linuxRoot)) {
    const dirs = fs.readdirSync(linuxRoot).map(n => path.join(linuxRoot, n));
    for (const dir of dirs) {
      if (javaVersionAtHome(dir) >= 21) return dir;
    }
  }

  return null;
}

// ---------------------------------------------------------------------------
// Step 2: Build the environment for the child process
// ---------------------------------------------------------------------------

const java21Home = findJava21Home();

if (!java21Home) {
  console.error(
    '\n[run-tests] ERROR: Could not find a JDK >= 21 installation.\n' +
    '  The Firebase Emulator Suite requires Java 21+.\n' +
    '  Please install JDK 21 and either:\n' +
    '    • Set JAVA_HOME to its path before running npm test, OR\n' +
    '    • Install it in a standard location (C:\\Program Files\\Microsoft,\n' +
    '      /Library/Java/JavaVirtualMachines, /usr/lib/jvm, etc.)\n',
  );
  process.exit(1);
}

const binDir = path.join(java21Home, 'bin');
console.log(`[run-tests] Using JAVA_HOME=${java21Home}`);

const env = {
  ...process.env,
  JAVA_HOME: java21Home,
  // Prepend the JDK 21 bin dir so `java` resolves to the correct version
  // for this process only — does not affect the system PATH.
  PATH: `${binDir}${path.delimiter}${process.env.PATH}`,
};

// ---------------------------------------------------------------------------
// Step 3: Run firebase emulators:exec → jest
// ---------------------------------------------------------------------------

// firebase.json lives one level up from firebase_rules_tests/
const firebaseConfig = path.resolve(__dirname, '..', 'firebase.json');

// Forward any arguments passed to run-tests.js down to Jest.
// This allows Jest VS Code extension and other tools to run/debug specific tests.
const args = process.argv.slice(2);
const escapedArgs = args.map(arg => {
  const escaped = arg.replace(/"/g, '\\"');
  if (/[ &|<>^%#@!*?()'"\s\\]/.test(arg)) {
    return `"${escaped}"`;
  }
  return arg;
});

const jestCmd = ['jest', '--forceExit', ...escapedArgs].join(' ');

// Use npx to invoke firebase-tools without requiring a global install.
const firebaseCmd = [
  'npx',
  '--yes',
  'firebase-tools',
  'emulators:exec',
  `--config "${firebaseConfig}"`,
  '--only firestore,auth',
  '--project demo-mini-golf-tracker',
  `"${jestCmd.replace(/"/g, '\\"')}"`,
].join(' ');

console.log(`[run-tests] Running: ${firebaseCmd}\n`);

try {
  execSync(firebaseCmd, { stdio: 'inherit', env, windowsHide: true });
  process.exit(0);
} catch (err) {
  process.exit(typeof err.status === 'number' ? err.status : 1);
}
