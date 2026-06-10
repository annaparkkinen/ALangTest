#!/bin/bash
# ============================================================
# export-app.sh
# Exports an APEX application in APEXlang format (.apx files)
#
# apex export -exptype APEXLANG creates: apex/f103/<alias>/
# This script moves it to: apex/f103/app/
# so structure is always consistent.
#
# Usage:
#   ./scripts/export-app.sh              # uses APP_ID from .env
#   ./scripts/export-app.sh 103          # exports specific app ID
# ============================================================

set -e

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

APP_ID="${1:-${APP_ID:-100}}"
APP_SCHEMA="${APP_SCHEMA}"
SQLCL="${SQLCL:-sql}"

# apex export output container — apex creates alias subfolder inside here
CONTAINER_DIR="./apex/f${APP_ID}"
# Where we want the final files
FINAL_DIR="${CONTAINER_DIR}/app"

if [ -n "${DB_CONNECTION}" ]; then
  CONNECTION="${DB_CONNECTION}"
else
  CONNECTION="${LOCAL_APP_SCHEMA}/${LOCAL_APP_SCHEMA_PASSWORD}@localhost:${LOCAL_ORACLE_PORT:-8521}/${LOCAL_SERVICE:-FREEPDB1}"
fi

DISPLAY_USER="${CONNECTION%%/*}"
DISPLAY_HOST="${CONNECTION##*@}"

echo "============================================"
echo "  APEX APEXlang Export"
echo "  App ID:  ${APP_ID}"
echo "  User:    ${DISPLAY_USER}"
echo "  DB:      ${DISPLAY_HOST}"
echo "  Output:  ${FINAL_DIR}/"
echo "============================================"

mkdir -p "${CONTAINER_DIR}"

# Remove existing app/ folder so we get a clean export
if [ -d "${FINAL_DIR}" ]; then
  rm -rf "${FINAL_DIR}"
fi

# Run export — apex creates its own subfolder named after the app alias
"${SQLCL}" -s "${CONNECTION}" <<SQLEOF
apex export -applicationid ${APP_ID} -exptype APEXLANG -dir ${CONTAINER_DIR} -force
exit
SQLEOF

# Find whatever subfolder apex just created (the alias folder)
# It will be the only subfolder in CONTAINER_DIR
ALIAS_DIR=$(find "${CONTAINER_DIR}" -mindepth 1 -maxdepth 1 -type d | head -1)

if [ -z "${ALIAS_DIR}" ]; then
  echo "ERROR: Export produced no subfolder in ${CONTAINER_DIR}/"
  echo "Check your connection and App ID."
  exit 1
fi

# Normalize to app/
mv "${ALIAS_DIR}" "${FINAL_DIR}"
echo ""
echo "  Normalized: $(basename ${ALIAS_DIR})/ -> app/"

echo ""
echo "============================================"
echo "  Export complete: ${FINAL_DIR}/"
echo ""
echo "  To validate:  make validate"
echo "  To import:    make import"
echo "  To commit:    git add apex/ && git commit"
echo "============================================"