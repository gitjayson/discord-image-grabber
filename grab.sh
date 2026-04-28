#!/usr/bin/env bash
#
# Wrapper to run grabby.py with environment variables from .env
#

set -euo pipefail

# Move to the script's directory so relative paths (.env, tmp/) work
# regardless of where this is called from.
cd "$(dirname "$(readlink -f "$0")")"

# Load .env if present
if [[ -f .env ]]; then
    set -a          # auto-export all variables defined below
    # shellcheck disable=SC1091
    source .env
    set +a
else
    echo "Warning: .env file not found in $(pwd)" >&2
fi

# Sanity-check required vars
: "${DISCORD_TOKEN:?DISCORD_TOKEN is not set}"
: "${DISCORD_CHANNEL_ID:?DISCORD_CHANNEL_ID is not set}"

# Use the project's virtualenv if one exists, otherwise system python3
if [[ -x .venv/bin/python ]]; then
    PYTHON=.venv/bin/python
else
    PYTHON=python3
fi

exec "$PYTHON" grabby.py
