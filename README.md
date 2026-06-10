# APEX Project Skeleton

A ready-to-use Oracle APEX development environment using the modern APEXlang
workflow. Clone it, start Docker, and develop APEX applications from VS Code
with AI assistance — export and import as human-readable .apx files.

---

## What's Inside

- Oracle Database 26ai Free running in Docker
- Oracle APEX + ORDS pre-installed via the Pretius unattended installer
- APEXlang workflow — export/import as readable .apx files (APEX 26.1+)
- Oracle DB Skills — 100+ Oracle guides for AI agents
- VS Code integration via Oracle SQL Developer Extension
- Export/import scripts for local Docker and OCI cloud

---

## How Everything Fits Together

```
VS Code (on your Mac)
|
+-- Oracle SQL Developer Extension
|   +-- MYAPP-local  -----> Oracle DB in Docker (localhost:8521)
|   +-- MYAPP-OCI    -----> Oracle DB on OCI
|
+-- You write SQL/PL/SQL in src/
|   +-- run in SQL Worksheet ---------> installed in Oracle DB
|
+-- APEXlang files in apex/f102/app/   (exported .apx files)
|   +-- AI reads and edits .apx files
|   +-- make import -----------------> deployed to APEX
|
+-- Browser -> APEX at localhost:8023/apex (reads same Oracle DB)
```

VS Code, APEX, and your SQL files all talk to the same Oracle database.
APEXlang files are the APEX app structure — readable, editable, AI-friendly.

---

## Prerequisites

### 1. Homebrew (Mac)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Docker Desktop
Download and install from: https://www.docker.com/products/docker-desktop/

### 3. Git
```bash
brew install git
```

### 4. Java 
SQLcl requires Java 11 or later, check if you already have it.
```java -version```
if not installed
```bash
brew install openjdk@21
echo 'export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
java -version   # should show 21 or later
```
### 5. SQLcl 26.1+
APEXlang requires SQLcl 26.1 or later.

1. Download from: https://www.oracle.com/database/sqldeveloper/technologies/sqlcl/
2. A folder named `sqlcl` is downloaded -- move it and add to PATH:
```bash
mv ~/Downloads/sqlcl ~/sqlcl
echo 'export PATH="$HOME/sqlcl/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
sql -v   # should show 26.1 or later
```

### 6. VS Code Extensions
- **Oracle SQL Developer Extension for VS Code** (26.1+) -- export/import APEXlang natively
- **Claude Code / Copilot / Cursor** 

---

## Part 1 -- Get the Project

### New project (recommended)
1. Click **Use this template → Create a new repository**
2. Name your repo and clone it:
```bash
git clone --recurse-submodules https://github.com/YOUR_USERNAME/your-new-repo.git
cd your-new-repo
```

> Forgot --recurse-submodules? Run: `git submodule update --init --recursive`

---

## Part 2 -- Environment Configuration

```bash
cp .env.example .env
```

Edit `.env`:
```
# Active environment: local | remote
# Controls which DB make commands target by default
ENV=local

# ============================================================
# LOCAL — Docker container (development)
# ============================================================
LOCAL_ORACLE_PWD=E
LOCAL_ORACLE_PORT=8521
LOCAL_APEX_PORT=8023
LOCAL_APP_SCHEMA=YOUR-SCHEMA-NAME
LOCAL_APP_SCHEMA_PASSWORD=YOUR-PASSWORD
LOCAL_SERVICE=FREEPDB1
LOCAL_HOST=localhost
CONTAINER_NAME=local-apex-dev

# ============================================================
# REMOTE — OCI Cloud (staging / production)
# ============================================================
REMOTE_APP_SCHEMA=MYAPP
REMOTE_APP_SCHEMA_PASSWORD=your-oci-schema-password
REMOTE_HOST=your-oci-db-hostname
REMOTE_PORT=1521
REMOTE_SERVICE=your-oci-service-name

# For OCI Autonomous Database (wallet-based connection)
# Leave REMOTE_HOST blank and set these instead:
REMOTE_WALLET=~/wallets/myapp-prod
REMOTE_TNS_ALIAS=mydb_medium

# ============================================================
# SHARED
# ============================================================
# Your APEX application ID
APP_ID=100
```

> `.env` is in `.gitignore` -- never committed.

---

## Part 3 -- Docker Container Setup

Uses Matt Mulvaney's single-step Pretius installer. Creates Oracle 26ai with
APEX and ORDS installed automatically -- no manual steps needed.

### 3.1 -- Run the installer

```bash
docker create -it --name 23cfree \
  -p 8521:1521 -p 8500:5500 -p 8023:8080 -p 9043:8443 -p 9922:22 \
  -e ORACLE_PWD=E \
  container-registry.oracle.com/database/free:latest

curl -o unattended_apex_install_23c.sh \
  https://raw.githubusercontent.com/Pretius/pretius-23cfree-unattended-apex-installer/main/src/unattended_apex_install_23c.sh

curl -o 00_start_apex_ords_installer.sh \
  https://raw.githubusercontent.com/Pretius/pretius-23cfree-unattended-apex-installer/main/src/00_start_apex_ords_installer.sh

docker cp unattended_apex_install_23c.sh 23cfree:/home/oracle
docker cp 00_start_apex_ords_installer.sh 23cfree:/opt/oracle/scripts/startup
docker start 23cfree
```

> **Mac Apple Silicon:** Add `--platform linux/amd64` to the docker create line.
> **Network tip:** The image is ~8.7GB. If your connection drops, just re-run --
> Docker caches completed layers. Use `caffeinate -i docker pull ...` to prevent sleep.

### 3.2 -- Wait ~20 minutes (first run only)

```bash
docker logs -f 23cfree
```

Done when you see `### APEX INSTALLED ###`.

Then rename the container:
```bash
docker rename 23cfree local-apex-dev
```

### 3.3 -- Verify

Open http://localhost:8023/apex

| Field | Value |
|---|---|
| Workspace | `internal` |
| Username | `ADMIN` |
| Password | `OrclAPEX1999!` |

After logging in, you are required to change password, write it down!

### 3.4 -- Daily start/stop

```bash
docker start local-apex-dev
docker stop local-apex-dev
```

---

## Part 4 -- APEX Workspace Setup (example)

1. Go to http://localhost:8023/apex
2. Log in: `internal` / `ADMIN` / `OrclAPEX1999!`
3. **Manage Workspaces -> Create Workspace**
   - Workspace Name: `MYAPP-LOCAL`
   - Schema/Database User: `MYAPP-SCHEMA`
   - Password: `YOUR-PASSWORD`
   - Admin Username: `MYAPP-ADMIN`
   - Admin Password: `YOUR-PASSWORD`

Write down schema password for connecting database!
   
4. Log out, log back in as `MYAPP-ADMIN` workspace
5. **Create Application** -- note the App ID assigned (e.g. `102`)
6. Update `.env`: `APP_ID=102`

---

## Part 5 -- VS Code Database Connections

Oracle icon in VS Code sidebar -> **Add Connection**

### Local Docker

**SYSTEM-local (admin tasks)**

| Field | Value |
|---|---|
| Connection Name | `SYSTEM-local` |
| Username | `SYSTEM` |
| Password | `E` |
| Hostname | `localhost` |
| Port | `8521` |
| Service Name | `FREEPDB1` |

**MYAPP-local (example)**

| Field | Value |
|---|---|
| Connection Name | `APP-LOCAL` |
| Username | `YOUR-SCHEMA-NAME` |
| Password | `YOUR-SCHEMA-PASSWORD` |
| Hostname | `localhost` |
| Port | `8521` |
| Service Name | `FREEPDB1` |

### OCI Cloud

**MYAPP-OCI (cloud)**

| Field | Value |
|---|---|
| Connection Name | `MYAPP-OCI` |
| Connection Type | Cloud Wallet |
| Username | `ADMIN` |
| Password | your OCI password |
| Wallet Location | `~/wallets/Wallet_TESTINGADB/` |
| Service | `testingadb_tp` |

> Use `MYAPP-local` for daily development. `SYSTEM-local` for admin tasks only.
> Never run DDL against OCI production connections.

---

## Part 6 -- AI Agent Setup

The `oracle-skills/` folder gives your AI agent full Oracle and APEX context.

### Gemini Code Assist
1. Install extension, sign in with Google account
2. Open the project folder in VS Code
3. Before asking questions, open the relevant skill file as a tab:
   - `oracle-skills/skills/features/oracle-apex.md`
   - `oracle-skills/skills/plsql/plsql-package-design.md`

**Example prompt:**
```
I have oracle-skills/skills/features/oracle-apex.md open.
Look at apex/f102/app/pages/p00002-customers.apx and add a
search bar that filters by customer name.
```

---

## Part 7 -- APEXlang Workflow

This is the core of the modern APEX development loop.

### The APEXlang loop

```
Generate or export app -> edit .apx files in VS Code -> AI modifies them -> validate -> import
```

### 7.1 -- Start a new app

**Option A -- Generate via terminal (fastest, AI-ready immediately):**
```bash
make generate
```
This creates a blank APEXlang app structure in `apex/f102/app/` ready for
AI editing without touching the APEX browser at all.

**Option B -- Create via APEX App Builder (visual wizard):**
1. Go to http://localhost:8023/apex -> log into your workspace
2. Click **Create Application** and follow the wizard
3. Note the App ID assigned
4. Update `.env`: `APP_ID=102`
5. Then export it: `make export`

### 7.2 -- What the export looks like

```
apex/f102/
+-- app/
    +-- app.apx                      <- app definition
    +-- pages/
    |   +-- p00001-home.apx          <- one file per page
    |   +-- p00002-customers.apx
    +-- shared-components/
    |   +-- lists.apx
    |   +-- navigation.apx
    +-- deployments/
        +-- default.json             <- connection config
```

Each `.apx` file is plain text -- readable, diffable, AI-editable.

### 7.3 -- Let AI edit the .apx files

Open a page file in VS Code, then ask Gemini:
```
Look at apex/f102/app/pages/p00002-customers.apx
Add a button "Add Customer" that links to page 3.
Use the oracle-skills/skills/features/oracle-apex.md as reference.
```

Gemini reads the .apx file, makes the change, and you can review the diff
in git before importing -- just like code review.

### 7.4 -- Validate before importing

```bash
make validate   # checks for syntax errors without touching APEX
```

Any errors appear in the terminal with exact file and line.

### 7.5 -- Import back to APEX

**Option A -- Via VS Code (easiest):**
1. Open any file in your `apex/f102/app/` folder
2. Click the **Import Application** button (play icon) in the top-right of the editor
3. Done -- app is updated in APEX

**Option B -- Via terminal:**
```bash
make import              # imports to active ENV
make import ENV=remote   # imports to OCI
```

### 7.6 -- Commit your changes

```bash
git add apex/ src/
git commit -m "Add customer search bar to page 2"
git push
```

The `.apx` files in git give you meaningful diffs:
```diff
- label: "Customers"
+ label: "Customers ({{count}} records)"
```

---

## Part 8 -- SQL/PL/SQL Development

For tables, packages, views -- written in VS Code and run directly in the DB.

### Write a table

Create `src/tables/APP_CUSTOMERS.sql`:
```sql
CREATE TABLE app_customers (
  customer_id  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  full_name    VARCHAR2(200) NOT NULL,
  email        VARCHAR2(300) NOT NULL,
  is_active    VARCHAR2(1)   DEFAULT 'Y' NOT NULL
);
```

### Run it in VS Code

1. Right-click `MYAPP-local` in Oracle sidebar -> **Open New SQL Worksheet**
2. Paste the SQL, confirm connection is `MYAPP-local`
3. Press **Ctrl+Enter**

The table is immediately available in your APEX app -- same database.

### Deploy all at once

```bash
make deploy           # runs all src/ files in correct order
make deploy-tables    # tables only
make deploy-packages  # packages only
```

---

## Daily Workflow

```
1. docker start local-apex-dev
2. Open VS Code -> project folder
3. Open MYAPP-local in Oracle sidebar
4. Open http://localhost:8023/apex -> MYAPP workspace

Start a new feature:
  make generate                    <- fastest: blank APEXlang app ready for AI
  OR create in APEX wizard -> make export

Develop database objects:
  write in src/ -> run in SQL Worksheet -> live in APEX

Develop APEX pages:
  AI edits .apx files in apex/f102/app/
  -> make validate
  -> make import (or VS Code import button)
  -> refresh browser

End of session:
  git add src/ apex/
  git commit -m "what you built"
  git push
  docker stop local-apex-dev
```

---

## Deploying to OCI

```bash
make export ENV=local    # export from local
make import ENV=remote   # import to OCI
```

Or via APEX UI:
1. Log into OCI APEX instance
2. App Builder -> Import -> upload the `apex/f102/app/` contents
3. Follow wizard

---

## Quick Reference

| Task | Command |
|---|---|
| Start container | `docker start local-apex-dev` |
| Stop container | `docker stop local-apex-dev` |
| Watch logs | `make logs` |
| Open SQLcl | `make db` |
| Check connections | `make env-check` |
| Generate new app | `make generate` |
| Deploy all src/ | `make deploy` |
| Export as APEXlang | `make export` |
| Validate APEXlang | `make validate` |
| Import APEXlang | `make import` |
| Update Oracle skills | `make skills-update` |
| All commands | `make help` |

**URLs:**
- APEX: http://localhost:8023/apex
- ORDS: http://localhost:8023/ords
- DB:   localhost:8521/FREEPDB1

**Credentials:**
- APEX internal: `internal` / `ADMIN` / `OrclAPEX1999!`
- APEX workspace: `MYAPP` / `ADMIN` / your password
- DB system: `SYSTEM` / `E`
- App schema: `MYAPP` / `Welcome1!`

---

## Troubleshooting

**NOTE: Some false errors appear in VSCODE, they can safely be ignored if they don't appear during validation**

**`sql -v` shows version older than 26.1**
APEXlang requires SQLcl 26.1+. Download the latest from:
https://www.oracle.com/database/sqldeveloper/technologies/sqlcl/

**APEXlang import fails -- "schema must be REST-enabled"**
In APEX: SQL Workshop -> RESTful Services -> enable REST for your schema.
Or run in SQL Worksheet:
```sql
BEGIN
  ORDS.ENABLE_SCHEMA(p_enabled => TRUE, p_schema => 'MYAPP');
  COMMIT;
END;
```

**Export produces SQL instead of .apx files**
Make sure you are on APEX 26.1 -- check: APEX -> Help -> About.
The local Docker Pretius installer installs the latest APEX automatically.

**`make validate` shows errors**
Fix the .apx file, re-validate, then import.

**Container not starting after Mac restart**
```bash
docker start local-apex-dev
```

**Table not visible in APEX after running in VS Code**
Check SQL Worksheet connection is MYAPP-local not SYSTEM-local.

**Submodule missing after clone**
```bash
git submodule update --init --recursive
```

**Full reset**
```bash
docker stop local-apex-dev && docker rm local-apex-dev
docker volume rm $(docker volume ls -q | grep local-apex-dev)
# Then redo Part 3
```