USE [msdb]
GO

/****** Object:  Job [(SysDBA) Check all User dBs for 2022 Compatibility]
 Script Date: 2/13/2025 4:45:07 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date:
2/13/2025 4:45:07 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE
name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL',
@name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'(SysDBA) Check all User
dBs for 2022 Compatibility',
@enabled=1,
@notify_level_eventlog=3,
@notify_level_email=0,
@notify_level_netsend=0,
@notify_level_page=0,
@delete_level=0,
@description=N'Checks and alerts all SQL User dBs for 2022 compatibility
level.',
@category_name=N'Database Maintenance',
@owner_login_name=N'<<username>>', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run Check]    Script Date: 2/13/2025 4:45:07 PM
******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run
Check',
@step_id=1,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'DECLARE @pMailProfile VARCHAR(64) = ''CRB EXCH'';
DECLARE @pEmail VARCHAR(1000) = ''<<email>>'';
DECLARE @vInstance VARCHAR(64) = @@SERVERNAME;
DECLARE @body1 NVARCHAR(MAX);
DECLARE @reccnt INT;

SET NOCOUNT ON;

DECLARE @vSubject VARCHAR(100) = ''Compatibility Database Alert: '' +
@vInstance;

-- Initialize email body
SET @body1 = N''<h3>'' + @vInstance + N'' has databases not at SQL 2022
compatibility level (160)</h3>'';
SET @body1 += N''<h5>*Listing all databases below:</h5>'';
SET @body1 += N''<table border="2" cellspacing="2" cellpadding="2">'';
SET @body1 += N''<thead style="font-family:Arial; font-size:11px;">
                   <tr>
                       <th>Database Name</th>
                       <th>Current Compatibility Level</th>
                   </tr>
               </thead>'';

-- Drop temp table if it exists
IF OBJECT_ID(''tempdb.dbo.#compat_level'') IS NOT NULL
    DROP TABLE #compat_level;

CREATE TABLE #compat_level (
    name VARCHAR(50),
    compatibility_level VARCHAR(60)
);

-- Common Table Expressions for Availability Group and Local Databases
WITH AGs AS (
    SELECT
        db.name,
        CASE db.compatibility_level
            WHEN 130 THEN ''SQL Server 2016''
            WHEN 140 THEN ''SQL Server 2017''
            WHEN 150 THEN ''SQL Server 2019''
            WHEN 160 THEN ''SQL Server 2022''
            ELSE CAST(db.compatibility_level AS CHAR(3))
        END AS compatibility_level
    FROM sys.databases db
    INNER JOIN sys.availability_databases_cluster adc ON db.name =
adc.database_name
    INNER JOIN sys.dm_hadr_availability_replica_states dbrs ON adc.group_id
= dbrs.group_id
    WHERE db.state_desc = ''ONLINE''  -- Only consider online databases
and db.is_read_only = 0 -- Exclude read-only databases
and db.compatibility_level <> 160   -- Filter for databases not in
compatibility level 160
            and dbrs.role_desc = ''PRIMARY'' -- Filter for Primary Node
),
LCL AS (
    SELECT
        db.name,
        CASE db.compatibility_level
            WHEN 130 THEN ''SQL Server 2016''
            WHEN 140 THEN ''SQL Server 2017''
            WHEN 150 THEN ''SQL Server 2019''
            WHEN 160 THEN ''SQL Server 2022''
            ELSE CAST(db.compatibility_level AS CHAR(3))
        END AS compatibility_level
    FROM sys.databases db
    WHERE db.state_desc = ''ONLINE'' AND db.compatibility_level <> 160
)
-- Insert data into temporary table
INSERT INTO #compat_level
SELECT name, compatibility_level FROM LCL
UNION ALL
SELECT name, compatibility_level FROM AGs;

-- Check if records exist
SELECT @reccnt = COUNT(1) FROM #compat_level;

-- Append data rows to email body
SELECT @body1 += N''<tr><td>'' + name + N''</td><td>'' +
compatibility_level + N''</td></tr>''
FROM #compat_level;

SET @body1 += N''</table>'';

-- Send email if records exist
IF @reccnt > 0
BEGIN
    EXEC msdb.dbo.sp_send_dbmail
        @profile_name = @pMailProfile,
        @recipients = @pEmail,
        @subject = @vSubject,
        @body = @body1,
        @body_format = ''HTML'';
END
ELSE
BEGIN
    PRINT ''No records to send for alert.'';
END

-- Clean up
DROP TABLE #compat_level;
',
@database_name=N'master',
@output_file_name=N'',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id
= 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId,
@name=N'Daily',
@enabled=1,
@freq_type=4,
@freq_interval=1,
@freq_subday_type=1,
@freq_subday_interval=1,
@freq_relative_interval=0,
@freq_recurrence_factor=0,
@active_start_date=20241212,
@active_end_date=99991231,
@active_start_time=30000,
@active_end_time=235959,
@schedule_uid=N'ab645410-ea81-4939-8f78-e0eab202a2a6'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name
= N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

