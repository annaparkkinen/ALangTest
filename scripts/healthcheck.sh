#!/bin/bash
# Docker healthcheck — verifies Oracle listener is up inside the container
# Note: uses internal port 1521 (not the host-mapped 8521)
echo "SELECT 'OK' FROM DUAL;" | sqlplus -S system/"${ORACLE_PWD:-E}"@//localhost:1521/FREEPDB1
