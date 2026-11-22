USE [msdb]
GO

/****** Object:  Job [(SysDBA) Clear Local Instance Cache]    Script Date:
10/26/2026 6:03:56 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date:
10/26/2026 6:03:56 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE
name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL',
@name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'(SysDBA) Clear Local
Instance Cache',
@enabled=1,
@notify_level_eventlog=3,
@notify_level_email=0,
@notify_level_netsend=0,
@notify_level_page=0,
@delete_level=0,
@description=N'To enforce new query plan when a regression is identified',
@category_name=N'Database Maintenance',
@owner_login_name=N'<<username>>', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [(SysDBA) Clear Local Instance Cache]    Script Date:
10/26/2026 6:03:56 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'(SysDBA) Clear Local Instance Cache',
@step_id=1,
@cmdexec_success_code=0,
@on_success_action=4,
@on_success_step_id=2,
@on_fail_action=4,
@on_fail_step_id=3,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'PRINT CONCAT(''Instance : '', @@SERVERNAME, '' | Started : '',
CONVERT(varchar(33), SYSDATETIMEOFFSET()));

DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
DBCC FREESYSTEMCACHE (''ALL'');

PRINT CONCAT(''Completed at '', CONVERT(varchar(33),
SYSDATETIMEOFFSET()));',
@database_name=N'master',
@output_file_name=N'L:\SQLJobsOutput\(SysDBA) Clear Local Instance
Cache_(SysDBA) Clear Local Instance
Cache_$(ESCAPE_NONE(STRTDT))_$(ESCAPE_NONE(STRTTM)).txt',
@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [(SysDBA) Clear Local Instance Cache - Success
Notification]    Script Date: 10/26/2026 6:03:56 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'(SysDBA) Clear Local Instance Cache - Success Notification',
@step_id=2,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'
declare @TheSubject varchar(200)
set @TheSubject = N''Informational: '' + @@SERVERNAME + '' (SysDBA) Clear
Local Instance Cache Succeeded.''
declare @TheRecipient varchar(200);
declare @TheBody varchar(200) =N''No action is required.''

select @TheRecipient=ConfigValue from UtilitiesConfig where
ConfigTag=''Alert Email Notification'';
exec msdb.dbo.sp_send_dbmail @recipients=@TheRecipient,
@subject=@TheSubject, @body=@TheBody, @attach_query_result_as_file=0;
',
@database_name=N'DBAUtilities',
@output_file_name=N'L:\SQLJobsOutput\(SysDBA) Clear Local Instance
Cache_(SysDBA) Clear Local Instance Cache - Success
Notification_$(ESCAPE_NONE(STRTDT))_$(ESCAPE_NONE(STRTTM)).txt',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [(SysDBA) Clear Local Instance Cache - Failure
Notification]    Script Date: 10/26/2026 6:03:56 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'(SysDBA) Clear Local Instance Cache - Failure Notification',
@step_id=3,
@cmdexec_success_code=0,
@on_success_action=2,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'
declare @TheSubject varchar(200)
set @TheSubject = N''Error: '' + @@SERVERNAME + '' (SysDBA) Clear Local
Instance Cache Job Failed''
declare @TheRecipient varchar(200);
declare @TheBody varchar(200) =N''Job Name: (SysDBA) Clear Local Instance
Cache. Please refer to log for additinal information.''

select @TheRecipient=ConfigValue from UtilitiesConfig where
ConfigTag=''Alert Email Notification'';
exec msdb.dbo.sp_send_dbmail @recipients=@TheRecipient,
@subject=@TheSubject, @body=@TheBody, @attach_query_result_as_file=0;
',
@database_name=N'msdb',
@output_file_name=N'L:\SQLJobsOutput\(SysDBA) Clear Local Instance
Cache_(SysDBA) Clear Local Instance Cache - Failure
Notification_$(ESCAPE_NONE(STRTDT))_$(ESCAPE_NONE(STRTTM)).txt',
@flags=0
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


