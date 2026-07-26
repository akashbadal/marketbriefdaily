#!/bin/bash
# Publishes the daily market briefing to GitHub Pages.
# Runs automatically each morning via ~/Library/LaunchAgents/com.akash.marketbriefing.publish.plist
# Safe to run by hand at any time: bash ~/Documents/market-briefing/publish.sh

set -euo pipefail

REPO="$HOME/Documents/market-briefing"
BRANCH="main"

# launchd starts jobs with a minimal PATH; git and friends need to be findable.
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Everything below is logged to publish.log so you can see what happened.
exec >>"$REPO/publish.log" 2>&1
echo "----- $(date '+%Y-%m-%d %H:%M:%S') -----"

cd "$REPO" || { echo "ERROR: $REPO not found"; exit 1; }

if [ ! -d .git ]; then
  echo "ERROR: not a git repo yet — run the one-time setup in README.md first"
  exit 1
fi

if [ ! -s index.html ]; then
  echo "SKIP: index.html is missing or empty — not publishing a broken page"
  exit 0
fi

# Nothing staged, nothing modified, nothing untracked? Then today's run didn't produce anything new.
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  echo "SKIP: no changes since last publish"
  exit 0
fi

git add -A
git commit -m "Briefing $(date '+%Y-%m-%d')"

if git push origin "$BRANCH"; then
  echo "OK: published $(date '+%Y-%m-%d')"
else
  echo "ERROR: push failed — check that credentials are cached (see README.md)"
  exit 1
fi
