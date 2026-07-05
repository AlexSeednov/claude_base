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
  // verdict directly. stderr is dropped so a missing tool stays silent.
  child = spawn(command, args, { stdio: ['inherit', 'inherit', 'ignore'] });
} catch (_) {
  passThrough();
}

// Spawn failure (e.g. interpreter not found) — pass through instead of erroring.
child.on('error', passThrough);
child.on('exit', (code) => process.exit(code == null ? 0 : code));
