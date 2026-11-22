USE [msdb]
GO

/****** Object:  Job [(SysDBA) IndexOptimize - USER_DATABASES]    Script
Date: 2/13/2025 4:51:23 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date:
2/13/2025 4:51:23 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE
name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL',
@name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'(SysDBA) IndexOptimize
- USER_DATABASES',
@enabled=1,
@notify_level_eventlog=3,
@notify_level_email=0,
@notify_level_netsend=0,
@notify_level_page=0,
@delete_level=0,
@description=N'(SysDBA) IndexOptimize - USER_DATABASES',
@category_name=N'Database Maintenance',
@owner_login_name=N'<<username>>', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [(SysDBA) IndexOptimize - USER_DATABASES]    Script
Date: 2/13/2025 4:51:23 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'(SysDBA) IndexOptimize - USER_DATABASES',
@step_id=1,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=0,
@on_fail_action=4,
@on_fail_step_id=3,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'EXECUTE dbo.IndexOptimize @Databases = ''USER_DATABASES'',
@Indexes = ''ALL_INDEXES'',
@FragmentationLow = NULL,
@FragmentationMedium =
 ''INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'',
@FragmentationHigh = ''INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'',
@FragmentationLevel1 = 10,
@FragmentationLevel2 = 40,
@Execute = ''Y'',
@LogToTable = ''Y''
',
@database_name=N'DBAUtilities',
@output_file_name=N'',
@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [(SysDBA) IndexOptimize - USER_DATABASES Success
Notification]    Script Date: 2/13/2025 4:51:23 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'(SysDBA) IndexOptimize - USER_DATABASES Success Notification',
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
set @TheSubject = N''Informational: '' + @@SERVERNAME + '' Index
Optimization of USER DBs Succeeded.''
declare @TheRecipient varchar(200);
declare @TheBody varchar(200) =N''No Action Required.''

select @TheRecipient=ConfigValue from UtilitiesConfig where
ConfigTag=''Alert Email Notification'';
exec msdb.dbo.sp_send_dbmail @recipients=@TheRecipient,
@subject=@TheSubject, @body=@TheBody, @attach_query_result_as_file=0;
',
@database_name=N'msdb',
@output_file_name=N'',
@flags=12
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [(SysDBA) IndexOptimize - USER_DATABASES Failure
Notification]    Script Date: 2/13/2025 4:51:23 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'(SysDBA) IndexOptimize - USER_DATABASES Failure Notification',
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
set @TheSubject = N''Error: '' + @@SERVERNAME + '' Index Optimization of
USER DBs Job Failed''
declare @TheRecipient varchar(200);
declare @TheBody varchar(200) =N''Job Name: (SysDBA) IndexOptimize -
USER_DATABASE. Please refer to log for additinal information.''

select @TheRecipient=ConfigValue from UtilitiesConfig where
ConfigTag=''Alert Email Notification'';
exec msdb.dbo.sp_send_dbmail @recipients=@TheRecipient,
@subject=@TheSubject, @body=@TheBody, @attach_query_result_as_file=0;
',
@database_name=N'msdb',
@output_file_name=N'',
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

