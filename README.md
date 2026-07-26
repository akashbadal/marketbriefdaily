# Daily Market Briefing — auto-publish setup

Every morning the scheduled Cowork task writes a fresh `index.html` here plus a dated copy in
`archive/`. A launchd job then commits and pushes, and GitHub Pages serves it at a stable URL.

**Timing — the page is live before the 09:00 IST pre-open:**

| Time (IST) | What happens |
|---|---|
| 08:24 | Briefing task fires (cron `20 8` + ~4 min scheduler jitter) |
| 08:25–08:40 | Research runs, writes `index.html` + `archive/YYYY-MM-DD.html` |
| 08:45 | `publish.sh` commits and pushes |
| ~08:47 | GitHub Pages finishes building — **live** |
| 08:55 / 09:30 / 10:30 | Retry slots; no-op if already published |

```
market-briefing/
├── index.html          ← the live page (overwritten daily)
├── archive/            ← dated copies, one per day
│   └── 2026-07-26.html
├── publish.sh          ← commits + pushes
├── com.akash.marketbriefing.publish.plist
└── publish.log         ← what happened, per run (gitignored)
```

---

## One-time setup

Run these once. After that it's hands-off.

Repo: https://github.com/akashbadal/marketbriefdaily
Live URL: https://akashbadal.github.io/marketbriefdaily/

### 1. Create the repo on GitHub — DONE

### 2. Wire this folder up to it — DONE

`git init`, the first commit, and the `origin` remote are already in place. Verify with:

```bash
cd ~/Documents/market-briefing && git log --oneline && git remote -v
```

### 3. Push it — YOUR TURN

```bash
cd ~/Documents/market-briefing
git push -u origin main
```

This prompts for credentials. Use a **personal access token** as the password
(GitHub → Settings → Developer settings → Personal access tokens → Fine-grained → give it
Contents: read/write on this repo). Your GitHub password will not work. macOS caches the token
in the keychain, which is what lets the automated daily pushes run later without prompting.

Prefer SSH? Swap the remote and push:

```bash
git remote set-url origin git@github.com:akashbadal/marketbriefdaily.git
git push -u origin main
```

### 4. Turn on GitHub Pages — YOUR TURN

Repo → **Settings** → **Pages** → Source: *Deploy from a branch* → Branch: `main`, folder `/ (root)` → Save.

Live at:

```
https://akashbadal.github.io/marketbriefdaily/
```

First build takes a minute or two. Archived days are reachable directly, e.g.
`https://akashbadal.github.io/marketbriefdaily/archive/2026-07-26.html`.

### 5. Install the daily publish job — YOUR TURN

```bash
chmod +x ~/Documents/market-briefing/publish.sh
cp ~/Documents/market-briefing/com.akash.marketbriefing.publish.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.akash.marketbriefing.publish.plist
```

Done. It runs at 08:45 with retries at 08:55, 09:30 and 10:30 — see the timing table above.

---

## Checking on it

```bash
# Did it run, and what did it do?
tail -20 ~/Documents/market-briefing/publish.log

# Is the job registered?
launchctl list | grep marketbriefing

# Force a publish right now
bash ~/Documents/market-briefing/publish.sh
```

`publish.sh` is safe to run repeatedly. It exits without doing anything if there are no changes,
and refuses to publish if `index.html` is missing or empty — so a failed briefing run leaves
yesterday's page up rather than replacing it with a blank one.

## If something breaks

**"push failed — check that credentials are cached"** — the keychain entry expired or the token
was revoked. Run `git push` manually once from this folder to re-prompt, then it's fine again.

**Job doesn't fire** — launchd skips runs when the Mac is asleep and doesn't retroactively catch
up on `StartCalendarInterval`. There are four fire times (08:45, 08:55, 09:30, 10:30) so a brief
sleep is covered, but if the machine is shut all morning nothing publishes — run `publish.sh` by
hand when you're back, or add more `<dict>` entries to the plist and reload it.

To change the times: edit the plist, then

```bash
launchctl unload ~/Library/LaunchAgents/com.akash.marketbriefing.publish.plist
cp ~/Documents/market-briefing/com.akash.marketbriefing.publish.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.akash.marketbriefing.publish.plist
```

**Page didn't change** — GitHub Pages can take a minute or two to rebuild. Check the Actions tab
in the repo for the deploy status.

## Turning it off

```bash
launchctl unload ~/Library/LaunchAgents/com.akash.marketbriefing.publish.plist
```

---

*The briefings are informational syntheses assembled with AI assistance, not financial advice.
Each page carries its own disclaimer — worth leaving intact, especially on a public URL.*
