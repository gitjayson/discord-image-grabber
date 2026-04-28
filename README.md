# discord-image-grabber

A small Python utility that downloads today's image attachments from a single
Discord channel into a local `tmp/` folder. Designed to be run on a schedule
(cron, launchd, systemd timer) once a day.

## What it does

On each run, the script:

1. Connects to Discord with a bot token.
2. Fetches every message posted in the configured channel since 00:00 UTC today.
3. Saves any image attachments (`.jpg`, `.jpeg`, `.png`, `.gif`, `.webp`) into
   `./tmp/`, prefixing the filename with the message ID to avoid collisions.
4. Disconnects and exits.

## Requirements

- Python 3.9+
- A Discord bot token with access to the target channel
- The bot needs the **Message Content Intent** enabled (toggle it in the
  Discord Developer Portal under your application's *Bot* tab)

## Setup

```bash
git clone git@github.com:gitjayson/discord-image-grabber.git
cd discord-image-grabber

python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

cp .env.example .env
# edit .env and fill in DISCORD_TOKEN and DISCORD_CHANNEL_ID
```

## Usage

Run via the wrapper script (loads `.env` automatically):

```bash
./grab.sh
```

Or run the Python module directly with the env vars exported:

```bash
export DISCORD_TOKEN=...
export DISCORD_CHANNEL_ID=...
python grabby.py
```

Downloaded images land in `./tmp/`.

## Configuration

| Variable             | Required | Description                                    |
| -------------------- | -------- | ---------------------------------------------- |
| `DISCORD_TOKEN`      | yes      | Discord bot token                              |
| `DISCORD_CHANNEL_ID` | yes      | Numeric ID of the channel to download from     |

## Scheduling (example)

Run once a day at 23:55 local time via cron:

```cron
55 23 * * * /path/to/discord-image-grabber/grab.sh >> /path/to/grab.log 2>&1
```

## License

MIT
