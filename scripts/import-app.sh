#!/bin/bash
# ============================================================
# import-app.sh
# Imports an APEXlang application to any APEX target.
#
# Usage:
#   ./scripts/import-app.sh              # uses APP_ID from .env
#   ./scripts/import-app.sh 100          # imports specific app ID
#   ./scripts/import-app.sh 100 "user/pass@host:port/svc"
#
# Requires: SQLcl 26.1+
# ============================================================

set -e

# Load .env
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

APP_ID="${1:-${APP_ID:-100}}"
SQLCL="${SQLCL:-sql}"
IMPORT_DIR="./apex/f${APP_ID}/app"

# Use connection passed as argument, then DB_CONNECTION from Makefile,
# then fall back to local defaults
if [ -n "${2}" ]; then
  CONNECTION="${2}"
elif [ -n "${DB_CONNECTION}" ]; then
  CONNECTION="${DB_CONNECTION}"
else
  CONNECTION="${LOCAL_APP_SCHEMA}/${LOCAL_APP_SCHEMA_PASSWORD}@localhost:${LOCAL_ORACLE_PORT}/${LOCAL_SERVICE}"
fi

DISPLAY_USER="${CONNECTION%%/*}"
DISPLAY_HOST="${CONNECTION##*@}"

echo "============================================"
echo "  APEX APEXlang Import"
echo "  App ID:  ${APP_ID}"
echo "  User:    ${DISPLAY_USER}"
echo "  DB:      ${DISPLAY_HOST}"
echo "  Source:  ${IMPORT_DIR}/"
echo "============================================"

# Validate source exists
if [ ! -d "${IMPORT_DIR}" ]; then
  echo ""
  echo "  ERROR: No APEXlang export found at ${IMPORT_DIR}/"
  echo "  Run: make export APP_ID=${APP_ID}"
  exit 1
fi

# Validate before importing
echo ""
echo "[1/2] Validating APEXlang files..."
"${SQLCL}" -s "${CONNECTION}" <<SQLEOF
apex validate -input ${IMPORT_DIR}
exit
SQLEOF

echo ""
echo "[2/2] Importing application..."
"${SQLCL}" -s "${CONNECTION}" <<SQLEOF
apex import -input ${IMPORT_DIR}
exit
SQLEOF

echo ""
echo "============================================"
echo "  Import complete!"
echo "  Open APEX to verify:"
if echo "${DISPLAY_HOST}" | grep -q "localhost"; then
  echo "  http://localhost:${LOCAL_APEX_PORT:-8023}/apex"
else
  echo "  Your OCI APEX URL"
fi
echo "============================================"