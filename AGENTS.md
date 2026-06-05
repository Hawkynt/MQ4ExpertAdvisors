# Agent guide — MQ4ExpertAdvisors

Working agreement for **all** coding agents and human contributors working in
this repository. These rules are not optional. The full house spec lives in
the `Hawkynt/project-template` repo (`STANDARD.md`); this file is the
per-repo distillation.

## What this is

**MQL4** trading code for MetaTrader 4: expert advisors (`Experts/`),
indicators (`Indicators/`), shared libraries (`Libraries/`), utility scripts
(`Scripts/`). The MetaEditor compiler is Windows-GUI-only, so CI runs a
structural syntax check (`check-mql.mjs`) instead of a compile — real
compilation and backtesting happen in MetaTrader.

## Commits

- **Group changes semantically/logically** — one EA/indicator/concern per
  commit.
- **Every subject line starts with a prefix**: `+` added · `-` removed ·
  `*` changed · `#` bug fixed · `!` critical todo.
- Never start a subject with "fix"/"bugfix"/"changed"/"modified".
- **No AI traces anywhere**: no `Co-Authored-By` AI lines, no "Generated
  with" footers, no agent mentions in messages, comments, or authorship.

## The loop (always, in this order)

1. **Before committing**: run the structural check locally —
   `node .github/workflows/scripts/check-mql.mjs .` (exactly what CI runs) —
   and compile touched files in MetaEditor where available; strategy changes
   get a Strategy-Tester backtest before they're called done. Update the
   README's configuration/feature tables when inputs change.
2. **Commit** (rules above) and **push**.
3. **Wait for CI** and fix until green. A pushed change isn't done while the
   workflow it triggered is red.

## Code conventions

- MQL4 dialect throughout; shared logic goes into `Libraries/`, indicator
  math into the Universal* indicator family — don't duplicate it in EAs.
- Trading-behavior changes are risk-relevant: describe the strategy impact
  in the commit body, and never alter default inputs silently.
- Guard clauses over deep nesting; every external/global input documented in
  the README's configuration section.

## README & repo conventions

- Standard frame: title → badges (incl. the MetaTrader 4 domain badge) →
  one-line `>` blockquote; fixed emoji mapping for the standard sections
  (`## ✨ Features`, `## 📦 Quick Start`, `## ❤️ Support`, `## 📜 License`);
  repo-specific sections keep their consistent topical emojis.
- License is LGPL-3.0-or-later; the `## ❤️ Support` section and
  `.github/FUNDING.yml` stay intact.
