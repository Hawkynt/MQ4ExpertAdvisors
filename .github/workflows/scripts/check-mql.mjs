// Structural syntax check for MQL4/MQL5 sources.
//
// The MetaEditor compiler is Windows-GUI-only, so CI cannot compile. This is
// the minimum-viable verification instead (STANDARD.md §4): every brace,
// parenthesis and bracket must balance, with strings ("…" and '…', \-escapes)
// and comments (// and /* … */) tokenised away first so delimiters inside
// literals never confuse the checker. Also flags an unterminated block
// comment or string at end of file.
//
// Usage: node check-mql.mjs [dir]      (default: repo root, *.mq4/*.mq5/*.mqh)
// Exit:  0 = all clean, 1 = structural errors found.

import fs from 'node:fs';
import path from 'node:path';

const ROOT = process.argv[2] || '.';
const EXT = /\.(mq4|mq5|mqh)$/i;

export function checkSource(text, file) {
    const errors = [];
    const stack = [];                   // { ch, line }
    const PAIRS = { '}': '{', ')': '(', ']': '[' };
    let line = 1, inLineComment = false, inBlockComment = false, inString = null;

    for (let i = 0; i < text.length; i++) {
        const c = text[i], n = text[i + 1];
        if (c === '\n') { line++; inLineComment = false; if (inString) { errors.push(`${file}:${line - 1}: unterminated string literal`); inString = null; } continue; }
        if (inLineComment) continue;
        if (inBlockComment) { if (c === '*' && n === '/') { inBlockComment = false; i++; } continue; }
        if (inString) {
            if (c === '\\') { i++; continue; }              // skip escaped char
            if (c === inString) inString = null;
            continue;
        }
        if (c === '/' && n === '/') { inLineComment = true; i++; continue; }
        if (c === '/' && n === '*') { inBlockComment = true; i++; continue; }
        if (c === '"' || c === "'") { inString = c; continue; }
        if (c === '{' || c === '(' || c === '[') { stack.push({ ch: c, line }); continue; }
        if (c === '}' || c === ')' || c === ']') {
            const top = stack[stack.length - 1];
            if (!top || top.ch !== PAIRS[c]) {
                errors.push(`${file}:${line}: unmatched '${c}'` + (top ? ` (innermost open '${top.ch}' from line ${top.line})` : ''));
                continue;                                   // don't pop a mismatch
            }
            stack.pop();
        }
    }
    if (inBlockComment) errors.push(`${file}:${line}: unterminated block comment`);
    for (const open of stack) errors.push(`${file}:${open.line}: unclosed '${open.ch}' at end of file`);
    return errors;
}

function* walk(dir) {
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
        if (e.name === '.git' || e.name === 'node_modules') continue;
        const p = path.join(dir, e.name);
        if (e.isDirectory()) yield* walk(p);
        else if (EXT.test(e.name)) yield p;
    }
}

const files = [...walk(ROOT)].sort();
if (files.length === 0) {
    console.error('error: no MQL sources (*.mq4/*.mq5/*.mqh) found — nothing was checked.');
    process.exit(1);                          // a green no-op CI is forbidden
}
let all = [];
for (const f of files)
    all = all.concat(checkSource(fs.readFileSync(f, 'utf8'), f));
for (const e of all) console.error(e);
console.log(`${files.length} file(s) checked, ${all.length} structural error(s).`);
process.exit(all.length ? 1 : 0);
