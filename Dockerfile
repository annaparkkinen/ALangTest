# Oracle APEX 23ai Free Developer Starter
# Based on the official Oracle APEX + ORDS image from Oracle Container Registry
#
# Pull the base image first:
#   docker login container-registry.oracle.com
#   (use your Oracle account credentials)
#
# The base image includes:
#   - Oracle Database 23ai Free
#   - Oracle APEX (latest)
#   - ORDS
FROM container-registry.oracle.com/database/free:latest

# Copy initialization scripts
COPY scripts/healthcheck.sh /scripts/healthcheck.sh
RUN chmod +x /scripts/healthcheck.sh

# Labels
LABEL maintainer="your-team"
LABEL description="Oracle APEX 23ai Free Developer Environment"
LABEL version="1.0.0"
