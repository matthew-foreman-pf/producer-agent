# Producer Agent Supervisor

A watchdog agent for [Claude Desktop](https://claude.ai/download) that monitors your scheduled tasks, cowork sessions, and app health — then alerts you via Slack when things need attention.

## What It Does

Runs as a Claude scheduled task on a configurable interval (default: every 5 minutes) and checks three things:

### 1. Scheduled Task Health
Compares each task's `lastRunAt` against its cron schedule to detect missed or overdue runs. Understands weekday-only and weekly schedules so it won't false-alarm on weekends.

### 2. Cowork Session Deep Inspection
Reads each session's conversation audit log to determine its actual state:
- **Waiting for you** — The agent asked a question and is blocked on your response. Includes the actual question so you can triage from Slack.
- **Has unfinished work** — The agent finished a step but flagged remaining tasks or handoffs that never got picked up.
- **Possibly stalled** — The agent may have crashed mid-task.
- **Completed** — No alert needed.

### 3. Claude.app Process Monitoring
Verifies the main Electron process is running. If Claude.app is down:
- Sends an immediate Slack alert
- Attempts to auto-restart
- Confirms recovery

### 4. Reboot Recovery
Detects when Claude.app was recently restarted and sends a recovery checklist of sessions that were active before the reboot, so you can resume them.

## Alert Policy

- **Silence = healthy.** You only hear from it when something is wrong.
- **Smart cooldowns.** Won't nag about the same issue repeatedly — alerts once, then backs off (4h for questions, 8h for pending work, 30min for task failures).
- **Severity-based.** Critical issues (app down, repeated task failures) alert immediately. Warnings (missed runs, stalled sessions) alert once. Info-level observations are logged silently.

## Prerequisites

- **macOS** (uses `ps`, `open -a` for process management)
- **Claude Desktop** with Cowork mode enabled
- **Slack MCP** configured in Claude (for sending DM alerts)
- **Scheduled Tasks** enabled in Claude Desktop
- At least one cowork session created (so the session directory exists)

## Setup

```bash
git clone <this-repo>
cd producer-agent
chmod +x setup.sh
./setup.sh
```

The setup script will:
1. Auto-detect your Claude session directory
2. Ask for your Slack user ID (for alert DMs)
3. Ask for your preferred check interval
4. Generate a configured `SKILL.md` and install it to `~/.claude/scheduled-tasks/producer-agent-supervisor/`

Then open Claude Desktop and create the scheduled task:

> Create a scheduled task called `producer-agent-supervisor` with cron `*/5 * * * *` using the SKILL.md already at `~/.claude/scheduled-tasks/producer-agent-supervisor/SKILL.md`

## How It Works

The supervisor reads two data sources that Claude Desktop maintains on disk:

**Session metadata** (`local_*.json`) — Contains title, last activity timestamp, archived status, and working directory for each cowork session.

**Audit logs** (`audit.jsonl`) — Contains the full conversation transcript for each session. The supervisor reads the last 20 entries to determine whether the agent is waiting for input, has pending work, or completed its task.

**Breadcrumb files** (`/tmp/producer-agent-*.json`) — Tracks alert history to prevent over-alerting. These are ephemeral and reset on system reboot.

## Customization

Edit `SKILL.template.md` to adjust:
- **Detection phrases** — The lists of phrases used to detect questions (`wait_phrases`) and pending work (`action_phrases`) in session transcripts
- **Time thresholds** — How long before a session is considered stalled (default: 4h), abandoned (7d), etc.
- **Alert format** — The Slack message templates
- **Severity rules** — What triggers a Critical vs Warning vs Info classification

Re-run `setup.sh` after editing the template to regenerate the installed SKILL.md.

## File Structure

```
producer-agent/
├── README.md              # This file
├── setup.sh               # Interactive setup script
├── SKILL.template.md      # Parameterized skill definition (edit this)
└── .gitignore
```

## Limitations

- **macOS only** — Process detection uses `ps aux | grep "[/]MacOS/Claude$"`. Would need adaptation for Linux/Windows.
- **Can't send messages into sessions** — The supervisor can detect that a session is stalled, but it can't directly type into another session. It alerts you via Slack so you can manually resume.
- **Requires Slack MCP** — Alerts are sent via Slack DM. If you don't have Slack configured, you could adapt the alert step to use another notification method.
- **Session directory UUIDs** — The path to session data contains installation-specific UUIDs. The setup script auto-detects these, but they may change if you reinstall Claude.

## License

MIT
