#!/bin/bash

#
# ./restart.sh [build]
#

set -e

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

build="${1:-}"

# Validate before stopping the running service. Compose reads .env in this directory.
docker compose -f compose.yaml -f compose.huihui.yaml config --quiet

if [ "$build" == "build" ]; then
  docker compose -f compose.yaml -f compose.huihui.yaml build
fi

docker compose -f compose.yaml -f compose.huihui.yaml stop

if [ "$build" == "build" ]; then
  docker compose -f compose.yaml -f compose.huihui.yaml up --remove-orphans --no-build -d
else
  docker compose -f compose.yaml -f compose.huihui.yaml up --remove-orphans -d
fi
docker compose -f compose.yaml -f compose.huihui.yaml logs -f
