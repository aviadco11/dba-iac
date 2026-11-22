# Filebeat Install — SQL servers (RDP)

For a **SQL server that has never had a beat**. Installs a brand-new
`filebeat`
service at **8.19.11**, SQL role only, run **on the server itself**.

Narrower than `..\..\individual\` on purpose:

- no old config to validate or migrate: if a `filebeat` service already
exists, it
  reports an error and quits
- no server-type detection (always SQL; never Reporting / Dual)
- no winlogbeat, no ODBC audit
- version is fixed at 8.19.11, so there's no `-toVersion`

## Copy onto the server

Copy this **entire folder** into a working folder (e.g. `C:\BeatInstall`):

```
Install-Filebeat-Auto.cmd              double-click: NO questions about
environment
Install-Filebeat-Auto.ps1              (environment taken from the server
name)
Install-Filebeat.cmd                   double-click: the wizard
Install-Filebeat.ps1                   the wizard
Filebeat-payload\
  README.md                            this file
  Install_SQL_Filebeat.ps1             the installer (wizard runs this)
  Get-SqlLogPaths.ps1                  SQL log-path probe
  install-service-beat.ps1             (shared copy - see
..\..\PROJECT_NOTES.md §2)
  check_errors.ps1                     (shared copy)
  diagnose-extract-denied.ps1          (shared copy)
  beat-secrets.psd1                    (shared copy) DO NOT COMMIT
  filebeat-8.19.11-windows-x86_64.zip  the prepared SQL ZIP (same as
..\..\individual\)
```

Only the two entry points sit at the top level. Everything they need is in
`Filebeat-payload\`.

## Run — automatic (easiest)

Double-click **`Install-Filebeat-Auto.cmd`** and accept the UAC prompt.

It works out the environment from the server name and prints it
(`Server '<<servername>>' -> environment 'production'`). It then shows the
detected log
paths and asks `Y/N` before changing anything. Answer `N` if the
environment or the
paths look wrong.

| Name contains | Environment | Seen on |
|---|---|---|
| `prd` | production | <<servername>>*, <<servername>>, <<servername>>* |
| `stg`, `sbx`, `lt02` | stg | sqldbstg*, sqldbsbx*, <<servername>>*,
sqldblt02-* |
| `uat`, `lt<n>` (other than lt02) | uat | <<servername>>, <<servername>>*,
sqldblt01-* |
| `qa` | qa | sqldbqa*, <<servername>>* |
| `dev`, `rsisd<n>` | dev | sqldbdev*, <<servername>>, <<servername>> |

The rules are checked top to bottom. If the name matches none of them, the
script stops
and shows how to run the installer by hand with `-ENV`. `demo` is never
derived. The
table was built from the SQL hosts shipping to each cluster on 2026-10-25.

## Run — wizard

Double-click **`Install-Filebeat.cmd`** and accept the UAC prompt.

1. Pick the **environment**.
2. Review the **detected log paths**. They're editable, one path per line:
   - jobsOutput: optional. Leave it empty and input id 1 is dropped.
   - sqlDump: leave it empty and it's derived from ERRORLOG.
   - ERRORLOG: required.
3. Click **Install** and confirm.

The install runs in a console window. It stays open at the end so you can
read the
result.

## Run — command line

Elevated PowerShell:

```powershell
cd C:\BeatInstall\Filebeat-payload
powershell -ExecutionPolicy Bypass -File .\Install_SQL_Filebeat.ps1 -ENV
production
```

Without path arguments it probes the server and asks `Y/N` before
installing. To set
the paths yourself, pass `-JobsOutput` / `-SqlDump` / `-ErrorLog`. Add
`-Yes` to skip
the confirmation prompt.

## What it does

1. Checks before changing anything, and stops if:
   - a `filebeat` service already exists (see the note below), or
   - there's no `FILEBEAT_PASSWORD` on the server and no secret for the
chosen environment.

   If existing `FILEBEAT_ENVIRONMENT` / `FILEBEAT_VPCE` /
`FILEBEAT_PASSWORD` values look
   like a different environment, it lists them and asks `Continue anyway?
(Y/N)`.
   Then it creates the machine env vars when they're absent
(`FILEBEAT_ENVIRONMENT`,
   `FILEBEAT_PRODUCT`, `FILEBEAT_USER`, `FILEBEAT_PASSWORD`) and sets
`FILEBEAT_VPCE`.
   An existing value is never overwritten, except `FILEBEAT_VPCE`.
2. Resolves the SQL log paths. The probe checks known layouts only:
   `<drive>:\MSSQL\MSSQL*\MSSQL\Log` and `<drive>:\SQLJobsOutput`.
3. Extracts the ZIP to `C:\Program
Files\Elastic\Beats\filebeat-8.19.11-windows-x86_64`
   and fills the SQL template in `filebeat.yml` and `modules.d\mssql.yml`.
4. Installs and starts the service, then validates the startup logs:
   - **Warnings only:** it waits 45 s and re-checks **once,
automatically**. If it's
     still not clean, you get the `[R]erun / [C]ontinue` prompt.
   - **Errors:** you get the `[R]erun / [C]ontinue` prompt straight away.

   There's no previous version, so there's no revert option.
5. Writes `install-sql-filebeat-<HOSTNAME>-<timestamp>.csv` in
`Filebeat-payload\`.

> If a `filebeat` service already exists, both the wizard and the installer
report an
> error and quit without changing anything. Use
`..\..\individual\Upgrade_Local.ps1` for
> servers that already run a beat.
>
> Exception: a service created by an earlier run of **this** installer (for
example, one that
> failed after the service was registered) can be re-run over. The wizard
asks first. The
> installer recognises its own installs by the marker file
> `installed-by-Install_SQL_Filebeat.txt` in the install folder.
