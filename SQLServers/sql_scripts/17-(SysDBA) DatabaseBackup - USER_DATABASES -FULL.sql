USE [msdb]
GO

/****** Object:  Job [(SysDBA) DatabaseBackup - USER_DATABASES - FULL]
 Script Date: 2/13/2025 4:47:35 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date:
2/13/2025 4:47:35 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE
name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL',
@name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'(SysDBA) DatabaseBackup
- USER_DATABASES - FULL',
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
/****** Object:  Step [(SysDBA) DatabaseBackup - USER_DATABASES - FULL]
 Script Date: 2/13/2025 4:47:35 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'(SysDBA) DatabaseBackup - USER_DATABASES - FULL',
@step_id=1,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=2,
@on_fail_action=4,
@on_fail_step_id=3,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'
declare @vCredential varchar(512)
             , @vURL varchar(75)
             ,@vMirrorUrl varchar(75)
             ,@vEnvironment VARCHAR(20)

select @vCredential =ConfigValue from UtilitiesConfig where
ConfigTag=''S3-Credential''
select @vURL = ConfigValue from UtilitiesConfig where ConfigTag=''S3-URL''
select @vMirrorUrl = ConfigValue from UtilitiesConfig where
ConfigTag=''S3-MIRROR''
select @vEnvironment = ConfigValue from UtilitiesConfig where ConfigTag =
''Environment''

EXEC usp_backupdatabasetos3  @pIsSystem = 0
                   ,@pType = ''FULL''
                                                        ,@pCredential =
@vCredential
                                                        ,@pURL = @vURL
                                                        ,@pMirrorUrl =
@vMirrorUrl
                                                        ,@pMirrorOverride =
0
                                                        ,@pEnvironment =
@vEnvironment
                                                        ,@pNumberofFiles = 4






',
@database_name=N'DBAUtilities',
@output_file_name=N'',
@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [USER DBs Backup Success Notification]    Script
Date: 2/13/2025 4:47:35 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'USER DBs Backup Success Notification',
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
set @TheSubject = N''Informational: '' + @@SERVERNAME + '' Backup of USER
DBs Succeeded.''
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
/****** Object:  Step [USER DBs Backup Failure Notification]    Script
Date: 2/13/2025 4:47:35 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'USER DBs Backup Failure Notification',
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
set @TheSubject = N''Error: '' + @@SERVERNAME + '' USERS DB FULL Backup Job
Failed''
declare @TheRecipient varchar(200);
declare @TheBody varchar(200) =N''Job Name: (SysDBA) DatabaseBackup -
USER_DATABASES - FULL. Please check log for additional information.''

select @TheRecipient=ConfigValue from UtilitiesConfig where
ConfigTag=''Alert Email Notification'';
exec msdb.dbo.sp_send_dbmail @recipients=@TheRecipient,
@subject=@TheSubject, @body=@TheBody, @attach_query_result_as_file=0;
',
@database_name=N'msdb',
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

