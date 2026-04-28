"""Download today's images from a Discord channel into ./tmp/."""

import logging
import os
from datetime import datetime, time, timezone
from pathlib import Path

import discord

# --- Configuration (set these as environment variables) ---
TOKEN = os.environ["DISCORD_TOKEN"]
CHANNEL_ID = int(os.environ["DISCORD_CHANNEL_ID"])

OUTPUT_DIR = Path("tmp")
IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".gif", ".webp"}

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
log = logging.getLogger(__name__)


def is_image(filename: str) -> bool:
    return Path(filename).suffix.lower() in IMAGE_EXTENSIONS


async def download_todays_images(channel: discord.abc.Messageable) -> int:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    start_of_day = datetime.combine(
        datetime.now(timezone.utc).date(), time.min, tzinfo=timezone.utc
    )
    log.info("Fetching messages since %s", start_of_day.isoformat())

    count = 0
    async for message in channel.history(after=start_of_day, limit=None):
        for attachment in message.attachments:
            if not is_image(attachment.filename):
                continue

            # Prefix with message ID to avoid overwriting same-named files
            save_path = OUTPUT_DIR / f"{message.id}_{attachment.filename}"
            try:
                await attachment.save(save_path)
                count += 1
                log.info("Saved %s", save_path)
            except (discord.HTTPException, OSError) as e:
                log.warning("Failed to save %s: %s", attachment.filename, e)

    return count


def main() -> None:
    intents = discord.Intents.default()
    intents.message_content = True

    client = discord.Client(intents=intents)

    @client.event
    async def on_ready():
        log.info("Logged in as %s", client.user)
        try:
            channel = client.get_channel(CHANNEL_ID) or await client.fetch_channel(CHANNEL_ID)
            saved = await download_todays_images(channel)
            log.info("Done. Saved %d image(s).", saved)
        finally:
            await client.close()

    client.run(TOKEN, log_handler=None)


if __name__ == "__main__":
    main()
