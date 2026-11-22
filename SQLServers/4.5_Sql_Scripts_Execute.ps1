Start-Transcript -Append c:\CRB\Bootstrap_Files\Win\4_5_SQLScripts_log.txt

Import-Module SQLServer

$MachineName = $Env:COMPUTERNAME
#$MachineName

# Define the directory containing .sql files
$directoryPath =
"C:\CRB\Bootstrap_Files\Win\PostBuildScripts\UpdatedWorkingSet\PostBuildScripts\SQLServers\sql_scripts\"
#$directoryPath

# Check if the directory exists
if (!(Test-Path -Path $directoryPath)) {
    Write-Output "The specified directory does not exist: $directoryPath"
    exit 1
}

# Loop through each .sql file in the directory
Get-ChildItem -Path $directoryPath -Filter *.sql | ForEach-Object {
    $sqlFile = $_.FullName
    Write-Output "Processing file: $sqlFile"
    #pause

    # Perform your actions on each .sql file here
    # Example: Display the content of the .sql file
    # $content = Get-Content -Path $sqlFile
    # Write-Output $content


    # Example: Execute SQL file content against a database (requires
SqlServer module)
    Invoke-Sqlcmd -InputFile $sqlFile -ServerInstance $MachineName
-Database "Master" -ErrorAction SilentlyContinue
}

Write-Output "Finished processing all .sql files in $directoryPath."


Write-Host "SQL Scripts done!" -ForegroundColor Yellow

Stop-Transcript