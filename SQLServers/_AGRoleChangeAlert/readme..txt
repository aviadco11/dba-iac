On each SQl server , put the following :

1. run all the scripts on each SQL server that is in this foler in
numerical order and modify for local machine usage and logging IE:/
sqloutput path , Alert response job edit .
2. create a new folder on D: called D:\CRB_DBA
2. create a new folder on L: called L:\MSSQL\SSRS_service
3. Copy the StopSSRS.ps1 , StartSSRS.ps1 to D:\CRB_DBA


Notes:
log write location for ssrsrestart service job @ L:\MSSQL\SSRS_service
Please enable Extended events session "AlwaysOn_health"  if running for
first time as it does not auto enable when built for some reason.

