# SQL log-path probe (shared by Install_SQL_Filebeat.ps1 and the wizard)
# Same probe as individual\Upgrade_Local.ps1 (PROJECT_NOTES 4b): KNOWN
LAYOUTS ONLY, no
# recursive scan, drives A..Z:
#   <drive>:\MSSQL\MSSQL<nn>.MSSQLSERVER\MSSQL\Log   (MSSQL16 = SQL 2022,
MSSQL14 = SQL 2017)
#   <drive>:\SQLJobsOutput
# EVERY drive/instance that matches is collected. Emits the same GLOB shape
the real configs
# use (*.txt / SQLDump*.txt / ERRORLOG*), not bare directories. Any list
may come back EMPTY;
# the caller decides whether that is fatal.
# Read-only: changes nothing on the server.

$joList = @(); $sdList = @(); $elList = @()
foreach ($dl in [char[]](65..90)) {
    $mssqlRoot = "${dl}:\MSSQL"
    if (Test-Path $mssqlRoot -ErrorAction SilentlyContinue) {
        $insts = @(Get-ChildItem -LiteralPath $mssqlRoot -Directory -Filter
'MSSQL*' -ErrorAction SilentlyContinue)
        foreach ($inst in $insts) {
            $log = Join-Path $inst.FullName 'MSSQL\Log'
            if (Test-Path $log -ErrorAction SilentlyContinue) {
                # Existence of the Log DIRECTORY is the test - the globs
themselves are never
                # probed. SQLDump files appear only on a SQL fault, so a
healthy server has
                # none and must still get the path configured.
                $sdList += (Join-Path $log 'SQLDump*.txt')
                $elList += (Join-Path $log 'ERRORLOG*')
            }
        }
    }
    if (Test-Path "${dl}:\SQLJobsOutput" -ErrorAction SilentlyContinue) {
        $joList += "${dl}:\SQLJobsOutput\*.txt"
    }
}
@{ JobsOutput = $joList; SqlDump = $sdList; ErrorLog = $elList }
