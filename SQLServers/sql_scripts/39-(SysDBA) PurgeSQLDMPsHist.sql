USE [DBAUtilities]
GO

/****** Object:  StoredProcedure [dbo].[PurgeSQLDMPsHist]    Script Date:
10/23/2025 7:37:17 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE OR ALTER  PROCEDURE [dbo].[PurgeSQLDMPsHist] (@RetentionDays INT =
14) as
BEGIN
SET NOCOUNT ON;
BEGIN TRY

DECLARE @tracePath NVARCHAR(260);
DECLARE @traceFolder NVARCHAR(260);

-- Get the full trace file path
SELECT TOP 1 @tracePath = path
FROM sys.traces
WHERE is_default = 1;

-- Extract folder path from full trace file path
SET @traceFolder = LEFT(@tracePath, LEN(@tracePath) - CHARINDEX('\',
REVERSE(@tracePath)));

-- Build PowerShell command
DECLARE @ps VARCHAR(8000) =
'powershell -NoLogo -NoProfile -Command "' +
'try {' +
'$folder = ''' + @traceFolder + '''; ' +
'$cutoff = (Get-Date).AddDays(-' + CAST(@RetentionDays AS NVARCHAR) + '); '
+
'$files = Get-ChildItem -Path $folder | Where-Object { ' +
'( $_.Name -like ''SQLDump*'' -or ( $_.Name -like ''SQLDmpr*'' -and
$_.Extension -eq ''.dmp'' ) ) -and $_.LastWriteTime -lt $cutoff ' +
'}; ' +
'$count = $files.Count; ' +
'$files | Remove-Item -Force; ' +
'Write-Output ''SUCCESS: Deleted '' + $count + '' file(s).''; ' +
'} catch {' +
'Write-Output ''FAILED: '' + $_.Exception.Message; ' +
'}"';

-- Execute PowerShell and capture output
CREATE TABLE #CleanupOutput (Output VARCHAR(4000));
INSERT INTO #CleanupOutput
EXEC master..xp_cmdshell @ps;

-- Concatenate output into a single message
DECLARE @Message NVARCHAR(MAX) = '';

SELECT @Message = COALESCE(@Message + '', '') + Output
FROM #CleanupOutput
WHERE Output IS NOT NULL and Output <> '+';

DROP TABLE #CleanupOutput;

-- Print final message
PRINT @Message;
END TRY
BEGIN CATCH
DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
PRINT 'SQL ERROR: ' + @ErrMsg;
END CATCH
END
GO





USE [msdb]
GO

IF EXISTS (
    SELECT 1
    FROM msdb.dbo.sysjobs
    WHERE name = N'(SysDBA) PurgeSQLDMPsHist'
)
BEGIN
    EXEC sp_delete_job
        @job_name = N'(SysDBA) PurgeSQLDMPsHist'
END

/****** Object:  Job [(SysDBA) PurgeSQLDMPsHist]    Script Date: 10/23/2025
7:38:17 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date:
10/23/2025 7:38:17 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE
name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL',
@name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'(SysDBA)
PurgeSQLDMPsHist',
@enabled=1,
@notify_level_eventlog=3,
@notify_level_email=0,
@notify_level_netsend=0,
@notify_level_page=0,
@delete_level=0,
@description=N'No description available.',
@category_name=N'Database Maintenance',
@owner_login_name=N'<<username>>', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [exec PurgeSQLDMPsHist]    Script Date: 10/23/2025
7:38:17 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'exec PurgeSQLDMPsHist',
@step_id=1,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'exec PurgeSQLDMPsHist',
@database_name=N'DBAUtilities',
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
@freq_subday_interval=0,
@freq_relative_interval=0,
@freq_recurrence_factor=0,
@active_start_date=20211213,
@active_end_date=99991231,
@active_start_time=213000,
@active_end_time=235959,
@schedule_uid=N'19226582-4c25-4883-a09e-42aade80c921'
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


