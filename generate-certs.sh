#!/usr/bin/env bash
# Certificates are generated automatically on the first `docker compose up`
# by the cert-generator service.
#
# Run this script only if you want to FORCE-REGENERATE all certificates
# (e.g. after expiry or a CA change).  It will recreate the certs volume
# and re-run the generator service.
set -eu
docker compose run --rm -e FORCE_REGEN=1 cert-generator
