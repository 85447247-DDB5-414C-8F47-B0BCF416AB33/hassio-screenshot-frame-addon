#!/usr/bin/env bash
set -e

# Ensure screenshot data dir
mkdir -p /data

if [ ! -f /data/art.jpg ]; then
  touch /data/art.jpg
fi

# Load options from /data/options.json and export as environment variables
if [ -f /data/options.json ]; then
  eval "$(python - <<'PY'
import json
opts = json.load(open('/data/options.json'))
for k,v in opts.items():
    key = k.upper()
    # escape double quotes
    if isinstance(v, bool):
        v = str(v).lower()
    print(f'export {key}="{v}"')
PY
)"
fi

exec python /app/main.py
