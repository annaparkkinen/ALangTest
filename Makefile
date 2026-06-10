# ============================================================
# Makefile -- APEX Project Skeleton
# ============================================================
# Usage: make <target>
#        make <target> ENV=local     (target local Docker)
#        make <target> ENV=remote    (target OCI cloud)
#
# Default environment is set by ENV= in your .env file.
# ============================================================

-include .env
export

# ---- Connection strings ------------------------------------
# Local Docker -- connects as LOCAL_DB_USER (SYSTEM or ADMIN)
LOCAL_DB  = $(LOCAL_APP_SCHEMA)/$(LOCAL_APP_SCHEMA_PASSWORD)@$(LOCAL_HOST):$(LOCAL_ORACLE_PORT)/$(LOCAL_SERVICE)
LOCAL_SYS = SYSTEM/$(LOCAL_ORACLE_PWD)@$(LOCAL_HOST):$(LOCAL_ORACLE_PORT)/$(LOCAL_SERVICE)

# Remote OCI -- wallet-based (Autonomous DB)
ifdef REMOTE_WALLET
REMOTE_DB = $(REMOTE_APP_SCHEMA)/$(REMOTE_APP_SCHEMA_PASSWORD)@$(REMOTE_TNS_ALIAS)
else
REMOTE_DB = $(REMOTE_APP_SCHEMA)/$(REMOTE_APP_SCHEMA_PASSWORD)@$(REMOTE_HOST):$(REMOTE_PORT)/$(REMOTE_SERVICE)
endif

# Active connection -- driven by ENV variable (default: local)
ENV       ?= local
ifeq ($(ENV),remote)
ACTIVE_DB    = $(REMOTE_DB)
ACTIVE_LABEL = OCI Remote
ifdef REMOTE_WALLET
ACTIVE_TNS   = TNS_ADMIN=$(REMOTE_WALLET)
endif
else
ACTIVE_DB    = $(LOCAL_DB)
ACTIVE_LABEL = Local Docker
ACTIVE_TNS   =
endif

APP_ID          ?= 103
CONTAINER_NAME  ?= local-apex-dev
SQLCL           = sql

.PHONY: help start stop restart logs shell status \
        db db-system \
        deploy deploy-tables deploy-packages deploy-views \
        export import validate generate \
        mcp skills-update env-check clean clean-data

# ---- Help ---------------------------------------------------
help:
	@echo ""
	@echo "  APEX Project Skeleton (APEXlang workflow)"
	@echo "  Active: $(ACTIVE_LABEL)  (ENV=$(ENV))"
	@echo ""
	@echo "  Switch environments:"
	@echo "    make <target> ENV=local    -> Local Docker"
	@echo "    make <target> ENV=remote   -> OCI Cloud"
	@echo ""
	@echo "  Container (local only):"
	@echo "    make start            Start Docker container"
	@echo "    make stop             Stop container (data kept)"
	@echo "    make logs             Tail container logs"
	@echo "    make shell            Open bash inside container"
	@echo "    make status           Show running containers"
	@echo ""
	@echo "  Database:"
	@echo "    make db               Open SQLcl -> $(ACTIVE_LABEL)"
	@echo "    make db-system        Open SQLcl as SYSTEM (local only)"
	@echo "    make env-check        Show current connection settings"
	@echo ""
	@echo "  Deploy src/ to database:"
	@echo "    make deploy           Deploy all src/ -> $(ACTIVE_LABEL)"
	@echo "    make deploy-tables    Deploy src/tables/ only"
	@echo "    make deploy-packages  Deploy src/packages/ only"
	@echo "    make deploy-views     Deploy src/views/ only"
	@echo ""
	@echo "  APEXlang (APEX 26.1+):"
	@echo "    make generate         Generate new starter APEXlang app"
	@echo "    make export           Export app as APEXlang -> apex/f$(APP_ID)/"
	@echo "    make validate         Validate APEXlang files (no import)"
	@echo "    make import           Import APEXlang app -> $(ACTIVE_LABEL)"
	@echo ""
	@echo "    TIP: In VS Code, right-click app in Oracle sidebar"
	@echo "         -> Export/Import directly without terminal"
	@echo ""
	@echo "  AI Agents:"
	@echo "    make mcp              Start SQLcl MCP server"
	@echo ""
	@echo "  Maintenance:"
	@echo "    make skills-update    Pull latest Oracle DB Skills"
	@echo "    make clean            Remove container (keep data)"
	@echo "    make clean-data       Remove container + all data"
	@echo ""

# ---- Environment check --------------------------------------
env-check:
	@echo ""
	@echo "  ============================================"
	@echo "  Active: $(ACTIVE_LABEL)  (ENV=$(ENV))"
	@echo "  ============================================"
	@echo ""
	@echo "  LOCAL  -- schema: $(LOCAL_APP_SCHEMA)"
	@echo "            DB:     $(LOCAL_HOST):$(LOCAL_ORACLE_PORT)/$(LOCAL_SERVICE)"
	@echo "            APEX:   http://$(LOCAL_HOST):$(LOCAL_APEX_PORT)/apex"
	@echo ""
	@echo "  REMOTE -- user:   $(REMOTE_APP_SCHEMA)"
	@echo "            Wallet: $(REMOTE_WALLET)"
	@echo "            TNS:    $(REMOTE_TNS_ALIAS)"
	@echo ""
	@echo "  Active connection -> $(ACTIVE_DB)"
	@echo ""

# ---- Container (local only) ---------------------------------
start:
	docker start $(CONTAINER_NAME)
	@echo ""
	@echo "  Container $(CONTAINER_NAME) starting..."
	@echo "  APEX: http://localhost:$(LOCAL_APEX_PORT)/apex"

stop:
	docker stop $(CONTAINER_NAME)

restart:
	docker restart $(CONTAINER_NAME)

logs:
	docker logs -f $(CONTAINER_NAME)

shell:
	docker exec -it $(CONTAINER_NAME) bash

status:
	docker ps --filter name=$(CONTAINER_NAME)

# ---- Database -----------------------------------------------
db:
	@echo "Connecting to: $(ACTIVE_LABEL)"
ifdef REMOTE_WALLET
	TNS_ADMIN=$(REMOTE_WALLET) $(SQLCL) $(ACTIVE_DB)
else
	$(SQLCL) $(ACTIVE_DB)
endif

db-system:
	$(SQLCL) $(LOCAL_SYS)

# ---- Deploy src/ to active environment ----------------------
deploy:
	@echo "Deploying all src/ to: $(ACTIVE_LABEL)"
	@$(MAKE) deploy-tables ENV=$(ENV)
	@$(MAKE) deploy-views ENV=$(ENV)
	@$(MAKE) deploy-packages ENV=$(ENV)
	@echo "Deploy complete -> $(ACTIVE_LABEL)"

deploy-tables:
	@echo "Deploying tables -> $(ACTIVE_LABEL)..."
	@for f in src/tables/*.sql; do \
	  [ -f "$$f" ] || continue; \
	  echo "  $$f"; \
	  $(ACTIVE_TNS) $(SQLCL) -S $(ACTIVE_DB) @$$f; \
	done

deploy-packages:
	@echo "Deploying packages -> $(ACTIVE_LABEL)..."
	@for f in src/packages/*.pks src/packages/*.pkb; do \
	  [ -f "$$f" ] || continue; \
	  echo "  $$f"; \
	  $(ACTIVE_TNS) $(SQLCL) -S $(ACTIVE_DB) @$$f; \
	done

deploy-views:
	@echo "Deploying views -> $(ACTIVE_LABEL)..."
	@for f in src/views/*.sql; do \
	  [ -f "$$f" ] || continue; \
	  echo "  $$f"; \
	  $(ACTIVE_TNS) $(SQLCL) -S $(ACTIVE_DB) @$$f; \
	done

# ---- APEXlang export / validate / import / generate ---------
export:
	@echo "Exporting app $(APP_ID) from: $(ACTIVE_LABEL) (APEXlang)"
	@chmod +x scripts/export-app.sh
ifdef REMOTE_WALLET
	TNS_ADMIN=$(REMOTE_WALLET) DB_CONNECTION="$(ACTIVE_DB)" SQLCL="$(SQLCL)" \
	  LOCAL_APEX_PORT="$(LOCAL_APEX_PORT)" \
	  ./scripts/export-app.sh $(APP_ID)
else
	DB_CONNECTION="$(ACTIVE_DB)" SQLCL="$(SQLCL)" \
	  LOCAL_APEX_PORT="$(LOCAL_APEX_PORT)" \
	  ./scripts/export-app.sh $(APP_ID)
endif

validate:
	@echo "Validating APEXlang: apex/f$(APP_ID)/"
	@chmod +x scripts/validate-app.sh
ifdef REMOTE_WALLET
	TNS_ADMIN=$(REMOTE_WALLET) DB_CONNECTION="$(ACTIVE_DB)" SQLCL="$(SQLCL)" \
	  ./scripts/validate-app.sh $(APP_ID)
else
	DB_CONNECTION="$(ACTIVE_DB)" SQLCL="$(SQLCL)" \
	  ./scripts/validate-app.sh $(APP_ID)
endif

import:
	@echo "Importing app $(APP_ID) to: $(ACTIVE_LABEL) (APEXlang)"
	@chmod +x scripts/import-app.sh
ifdef REMOTE_WALLET
	TNS_ADMIN=$(REMOTE_WALLET) DB_CONNECTION="$(ACTIVE_DB)" SQLCL="$(SQLCL)" \
	  LOCAL_APEX_PORT="$(LOCAL_APEX_PORT)" \
	  ./scripts/import-app.sh $(APP_ID)
else
	DB_CONNECTION="$(ACTIVE_DB)" SQLCL="$(SQLCL)" \
	  LOCAL_APEX_PORT="$(LOCAL_APEX_PORT)" \
	  ./scripts/import-app.sh $(APP_ID)
endif

generate:
	@echo "Generating new starter APEXlang app..."
	@chmod +x scripts/generate-app.sh
	DB_CONNECTION="$(LOCAL_DB)" SQLCL="$(SQLCL)" \
	  APP_SCHEMA="$(LOCAL_APP_SCHEMA)" \
	  ./scripts/generate-app.sh

# ---- AI Agents ----------------------------------------------
mcp:
	@chmod +x scripts/start-mcp.sh
	./scripts/start-mcp.sh

# ---- Maintenance --------------------------------------------
skills-update:
	git submodule update --remote oracle-skills
	@echo "Oracle skills updated. Commit with:"
	@echo "  git add oracle-skills && git commit -m 'Update oracle skills'"

clean:
	docker stop $(CONTAINER_NAME) && docker rm $(CONTAINER_NAME)

clean-data:
	@echo "WARNING: This will delete all Oracle data!"
	@read -p "Are you sure? (yes/no): " confirm && [ "$$confirm" = "yes" ]
	docker stop $(CONTAINER_NAME)
	docker rm $(CONTAINER_NAME)
	docker volume rm $$(docker volume ls -q | grep $(CONTAINER_NAME)) 2>/dev/null || true