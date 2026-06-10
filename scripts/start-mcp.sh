#!/bin/bash
# ============================================================
# start-mcp.sh
# Starts the SQLcl MCP server for AI agent database access.
#
# The MCP server lets AI agents:
#   - Query your live Oracle database
#   - Run: apex validate (and fix errors in a loop)
#   - Inspect schema objects
#   - Run PL/SQL
#
# Requires: SQLcl 25.2+ 
#   https://www.oracle.com/database/sqldeveloper/technologies/sqlcl/
#
# Usage:
#   ./scripts/start-mcp.sh              # uses saved VS Code connection
#   ./scripts/start-mcp.sh MYAPP-local  # specify connection name
# ============================================================

set -e

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

SQLCL="${SQLCL:-sql}"
CONNECTION_NAME="${1:-${MCP_CONNECTION:-MYAPP-LOCAL}}"

# Verify SQLcl version is 25.2+
VERSION=$("${SQLCL}" -v 2>/dev/null | grep -o '[0-9]*\.[0-9]*' | head -1)
MAJOR=$(echo $VERSION | cut -d. -f1)
MINOR=$(echo $VERSION | cut -d. -f2)

if [ "$MAJOR" -lt 25 ] || ([ "$MAJOR" -eq 25 ] && [ "$MINOR" -lt 2 ]); then
  echo "ERROR: SQLcl MCP requires version 25.2 or later."
  echo "Current version: ${VERSION}"
  echo "Download from: https://www.oracle.com/database/sqldeveloper/technologies/sqlcl/"
  exit 1
fi

echo "============================================"
echo "  SQLcl MCP Server"
echo "  Connection: ${CONNECTION_NAME}"
echo "  SQLcl: ${VERSION}"
echo "============================================"
echo ""
echo "  AI agents can now:"
echo "    - Query your Oracle database"
echo "    - Run: apex validate"
echo "    - Run: apex import"
echo "    - Inspect schema objects"
echo ""
echo "  Gemini prompt to validate APEXlang:"
echo "    Use the SQLcl MCP tool to run:"
echo "    apex validate -input ./apex/f103"
echo "    Fix any errors and validate again."
echo ""
echo "  Press Ctrl+C to stop the MCP server."
echo "============================================"
echo ""

# Start MCP server using the saved VS Code connection name
"${SQLCL}" -mcp -name "${CONNECTION_NAME}"