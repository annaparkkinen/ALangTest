#!/bin/bash
# ============================================================
# generate-app.sh
# Generates a new starter APEXlang application from scratch.
#
# Usage:
#   ./scripts/generate-app.sh "My App" myapp 103
#   Arguments: <app-name> <alias> <app-id>
#
# apex generate creates: apex/f103/<alias>/
# This script moves it to: apex/f103/app/
# so it always matches what apex export produces.
# ============================================================

set -e

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

APP_NAME="${1:-My APEX App}"
APP_ALIAS="${2:-myapp}"
APP_ID="${3:-${APP_ID:-100}}"
SQLCL="${SQLCL:-sql}"

# apex generate output before normalization
RAW_DIR="./apex/f${APP_ID}"
ALIAS_DIR="${RAW_DIR}/${APP_ALIAS}"
# Where we want it to end up — matches apex export
FINAL_DIR="${RAW_DIR}/app"

if [ -n "${DB_CONNECTION}" ]; then
  CONNECTION="${DB_CONNECTION}"
else
  CONNECTION="${LOCAL_APP_SCHEMA}/${LOCAL_APP_SCHEMA_PASSWORD}@localhost:${LOCAL_ORACLE_PORT}/${LOCAL_SERVICE}"
fi

echo "============================================"
echo "  Generating new APEXlang app"
echo "  Name:   ${APP_NAME}"
echo "  Alias:  ${APP_ALIAS}"
echo "  App ID: ${APP_ID}"
echo "  Schema: ${APP_SCHEMA:-MYAPP}"
echo "============================================"

mkdir -p "${RAW_DIR}"

# Generate into the parent folder — apex creates the alias subfolder itself
"${SQLCL}" -s "${CONNECTION}" <<SQLEOF
apex generate -name "${APP_NAME}" -alias ${APP_ALIAS} -id ${APP_ID} -schema ${APP_SCHEMA} -dir ${RAW_DIR}
exit
SQLEOF

# Normalize: rename alias folder to app/
# so structure matches apex export output
if [ -d "${ALIAS_DIR}" ] && [ ! -d "${FINAL_DIR}" ]; then
  mv "${ALIAS_DIR}" "${FINAL_DIR}"
  echo ""
  echo "  Normalized: ${ALIAS_DIR}/ -> ${FINAL_DIR}/"
elif [ -d "${ALIAS_DIR}" ] && [ -d "${FINAL_DIR}" ]; then
  echo ""
  echo "  WARNING: ${FINAL_DIR}/ already exists."
  echo "  Generated files are in: ${ALIAS_DIR}/"
  echo "  Merge manually or delete ${FINAL_DIR}/ first."
  exit 1
fi

echo ""
echo "============================================"
echo "  Generated! Files are in: ${FINAL_DIR}/"
echo ""
echo "  Next steps:"
echo "    1. make validate   -- check for errors"
echo "    2. Edit .apx files in VS Code with AI"
echo "    3. make validate   -- check AI edits"
echo "    4. make import     -- deploy to APEX"
echo "    5. git add apex/ && git commit"
echo "============================================"