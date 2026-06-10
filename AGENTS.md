# Agent Instructions -- APEX Project Skeleton

## Environment

- Oracle Database 23ai Free + APEX 26.1 + ORDS in Docker
- APEX:   http://localhost:8023/apex
- ORDS:   http://localhost:8023/ords
- DB:     localhost:8521/FREEPDB1

## How to Use SQLcl

You have access to the SQLcl which gives you a live connection
to the Oracle database. Use it to:

- Validate APEXlang files:      apex validate -input ./apex/f<APP_ID>/app
- Import after clean validate:  apex import -input ./apex/f<APP_ID>/app
- Check tables exist:           SELECT column_name FROM user_tab_columns WHERE table_name = 'X'
- Check templates:              SELECT template_name FROM apex_templates WHERE workspace = 'MYAPP'
- Generate new apps:            apex generate -name "X" -alias x -schema MYAPP -dir ./apex/fX/app

## APEXlang Validation Loop -- ALWAYS DO THIS

This is mandatory. Never skip it. Never import without a clean validate.

```
Step 1: Write or edit .apx file
Step 2: apex validate -input ./apex/f<APP_ID>/app   
Step 3: Errors? Fix them. Go to Step 2.
Step 4: Zero errors? Tell user. Ask before importing.
```

The validator knows your exact APEX version, your actual templates,
and your real schema -- it catches errors you cannot see by reading alone.

## APEXlang -- How APEX Pages Are Stored

```
apex/f103/
+-- app.apx
+-- pages/
|   +-- p00001-home.apx
|   +-- p00002-report.apx
+-- shared-components/
+-- deployments/default.json
```

Edit .apx files directly. 
```
Apply patterns from fixed pages to other pages using the diff as reference.

## Oracle Skills

Before writing Oracle code, read the relevant skill:
- oracle-skills/skills/features/oracle-apex.md
- oracle-skills/skills/plsql/plsql-package-design.md
- oracle-skills/skills/ords/
- oracle-skills/skills/security/row-level-security.md

## Example App

When creating components, look at the example app called strategic-planner located in the example-app directory.
This app contains examples of apx files that you can use to generate components.

## Coding Rules

1. Bind variables always -- never concatenate user input into SQL
2. PL/SQL: spec + body separation
3. Table prefix APP_, package prefix PKG_, view prefix V_
4. Schema is MYAPP
5. Never import APEXlang without a clean validate first

## Tool-Specific Notes

## APEXlang Validation Loop -- MANDATORY TOOL EXECUTION

You (the AI) have access to terminal execution capabilities. You are strictly forbidden from considering any coding task "complete" until you have successfully validated the `.apx` files yourself. 

Whenever you are asked to write, edit, or fix code in this project, your task plan MUST end with the following automated sequence. **Do not wait for the user to ask you to validate.**

**Step 1: Execute Validation**
Automatically use your terminal tools to run the following commands:
`make validate`

**Step 2: Self-Correction (If Errors)**
If your terminal execution returns errors, you must autonomously read those errors, fix the `.apx` file, and re-run Step 1. Do not ask the user for permission to fix your own errors.

**Step 3: Final Output**
Only once your terminal execution returns zero errors are you allowed to tell the user the task is complete. At that point, output the import command (`apex import -input ./apex/f<APP_ID>/app`) for the user.
