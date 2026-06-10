#!/bin/bash
# ============================================================
# validate-app.sh
# Validates APEXlang files without importing.
# Checks for syntax errors before deploying.
#
# Usage:
#   ./scripts/validate-app.sh            # uses APP_ID from .env
#   ./scripts/validate-app.sh 100
# ============================================================

set -e

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

APP_ID="${1:-${APP_ID:-100}}"
SQLCL="${SQLCL:-sql}"
VALIDATE_DIR="./apex/f${APP_ID}/app"

if [ -n "${DB_CONNECTION}" ]; then
  CONNECTION="${DB_CONNECTION}"
else
  CONNECTION="${LOCAL_APP_SCHEMA}/${LOCAL_APP_SCHEMA_PASSWORD}@localhost:${LOCAL_ORACLE_PORT:-8521}/${LOCAL_SERVICE:-FREEPDB1}"
fi

echo "============================================"
echo "  Validating APEXlang: ${VALIDATE_DIR}/"
echo "============================================"

if [ ! -d "${VALIDATE_DIR}" ]; then
  echo "  ERROR: No APEXlang export found at ${VALIDATE_DIR}/"
  echo "  Run: make export APP_ID=${APP_ID}"
  exit 1
fi

"${SQLCL}" -s "${CONNECTION}" <<SQLEOF
apex validate -input ${VALIDATE_DIR}
exit
SQLEOF

echo ""
echo "Validation complete. If no errors shown, safe to import."