#!/usr/bin/env node
// Cross-platform dispatcher for the Claude Code Telegram hooks.
//
// Picks the OS-native implementation of a hook script and runs it, forwarding
// the hook's stdin/stdout untouched. Node is used as the entry point because a
// single `node ...` command works on both macOS and Windows — sidestepping the
// "powershell missing on macOS / bash missing on Windows" problem, so the plugin
// hooks.json needs only one command string for every platform.
//
// Usage (from a plugin hook `command`):
//   node "${CLAUDE_PLUGIN_ROOT}/scripts/dispatch.js" <base>
//   <base> — script file name without extension, e.g. `telegram-notify`.
//            Resolves to `<base>.ps1` on Windows, `<base>.sh` elsewhere.

'use strict';

const { spawn } = require('node:child_process');
const path = require('node:path');

/// Emit a pass-through verdict so a hook failure never blocks Claude.
function passThrough() {
  process.stdout.write('{"continue":true}');
  process.exit(0);
}

const base = process.argv[2];
if (!base) passThrough();

const isWindows = process.platform === 'win32';
const scriptPath = path.join(__dirname, `${base}${isWindows ? '.ps1' : '.sh'}`);

const command = isWindows ? 'powershell' : 'bash';
const args = isWindows
  ? ['-ExecutionPolicy', 'Bypass', '-File', scriptPath]
  : [scriptPath];

let child;
try {
  // stdin/stdout inherited: the child reads the hook payload and writes the
  // verdict directly. stderr is captured rather than dropped, so a healthy run
  // stays quiet while a genuine failure can still be reported on exit.
  child = spawn(command, args, { stdio: ['inherit', 'inherit', 'pipe'] });
} catch (_) {
  passThrough();
}

// Bounded: a script failing in a loop must not grow this without limit.
const stderrChunks = [];
child.stderr.on('data', (chunk) => {
  if (stderrChunks.length < 32) stderrChunks.push(chunk);
});

// Spawn failure (e.g. interpreter not found) — pass through instead of erroring.
child.on('error', passThrough);

// 'close' rather than 'exit': it fires once the captured stderr has drained, so a
// fast failure can never be reported with half of its message missing.
child.on('close', (code) => {
  if (!code) return;
  // A non-zero exit means the hook script itself broke — a syntax error, a
  // missing dependency. Say so: swallowing this output once hid a parser error
  // that silently disabled the Windows notifications altogether.
  const detail = Buffer.concat(stderrChunks).toString('utf8').trim();
  const name = path.basename(scriptPath);
  // Set the code and let Node drain and exit by itself rather than calling
  // process.exit(): a write to a pipe is asynchronous on macOS, so exiting
  // outright would truncate the very report this exists to deliver. 1 and never
  // 2 — 2 is what Claude Code reads as a blocking hook failure.
  process.exitCode = 1;
  process.stderr.write(`${name} failed${detail ? `:\n${detail}` : ` with exit code ${code}`}\n`);
});
