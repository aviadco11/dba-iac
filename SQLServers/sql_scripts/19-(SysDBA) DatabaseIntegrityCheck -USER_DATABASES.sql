USE [msdb]
GO

/****** Object:  Job [(SysDBA) DatabaseIntegrityCheck - USER_DATABASES]
 Script Date: 2/18/2025 10:58:31 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date:
2/18/2025 10:58:31 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE
name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL',
@name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'(SysDBA)
DatabaseIntegrityCheck - USER_DATABASES',
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
/****** Object:  Step [(SysDBA) DatabaseIntegrityCheck - USER_DATABASES]
 Script Date: 2/18/2025 10:58:31 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'(SysDBA) DatabaseIntegrityCheck - USER_DATABASES',
@step_id=1,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=2,
@on_fail_action=4,
@on_fail_step_id=3,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'declare @DBCCDayAbbreviation varchar(3);
declare @p_PhysicalOnly varchar(1) ;
declare @CurrentDayAbbreviation  varchar(3) ;
declare @CoresUse int;

SELECT @CoresUse = count(*)/2
FROM sys.dm_os_schedulers
WHERE status = ''VISIBLE ONLINE'';

select @CurrentDayAbbreviation = LEFT(DATENAME(WEEKDAY, Getdate()), 3)
select @DBCCDayAbbreviation=ConfigValue from UtilitiesConfig where
ConfigTag=''Full DBCC Day'';

if ((@DBCCDayAbbreviation is not null) and  (Upper(@CurrentDayAbbreviation)
<> Upper(@DBCCDayAbbreviation)))
select @p_PhysicalOnly  = ''Y''
else
select  @p_PhysicalOnly = ''N''

EXECUTE dbo.DatabaseIntegrityCheck
@Databases = ''USER_DATABASES, -DBAUtilities'',
@PhysicalOnly = @p_PhysicalOnly,
@LogToTable = ''Y'',
@MaxDOP=@CoresUse',
@database_name=N'DBAUtilities',
@output_file_name=N'',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CHECKDB USER DBs Success Notification]    Script
Date: 2/18/2025 10:58:31 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'CHECKDB USER DBs Success Notification',
@step_id=2,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=0,
@on_fail_action=1,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'
declare @TheSubject varchar(200)
set @TheSubject = N''Informational: '' + @@SERVERNAME + ''CHECKDB for USER
DBs Succeeded.''
declare @TheRecipient varchar(200);
declare @TheBody varchar(200) =N''No action is required.''

select @TheRecipient=ConfigValue from UtilitiesConfig where
ConfigTag=''Alert Email Notification'';
exec msdb.dbo.sp_send_dbmail @recipients=@TheRecipient,
@subject=@TheSubject, @body=@TheBody, @attach_query_result_as_file=0;
',
@database_name=N'DBAUtilities',
@output_file_name=N'',
@flags=12
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CHECKDB USER DBs Failure Notification]    Script
Date: 2/18/2025 10:58:31 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'CHECKDB USER DBs Failure Notification',
@step_id=3,
@cmdexec_success_code=0,
@on_success_action=2,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'declare @TheSubject varchar(200)
set @TheSubject = N''Error: '' + @@SERVERNAME + '' CHECKDB for USER DBs
FAILED''
declare @TheRecipient varchar(200);
declare @TheBody varchar(200) =N''Job Name: (SysDBA) DatabaseIntegrityCheck
- USER_DATABASES. Please refer to log for additional information.''

select @TheRecipient=ConfigValue from UtilitiesConfig where
ConfigTag=''Alert Email Notification'';
exec msdb.dbo.sp_send_dbmail @recipients=@TheRecipient,
@subject=@TheSubject, @body=@TheBody, @attach_query_result_as_file=0;
',
@database_name=N'DBAUtilities',
@output_file_name=N'',
@flags=12
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id
= 1
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