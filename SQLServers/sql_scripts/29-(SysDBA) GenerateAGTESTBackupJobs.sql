USE [msdb]
GO

/****** Object:  Job [(SysDBA) DatabaseBackup - TEST_DATABASES - FULL]
 Script Date: 2/21/2025 1:25:53 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date:
2/21/2025 1:25:54 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE
name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL',
@name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'(SysDBA) DatabaseBackup
- TEST_DATABASES - FULL',
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
/****** Object:  Step [(SysDBA) DatabaseBackup - TEST_DATABASES - FULL]
 Script Date: 2/21/2025 1:25:54 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'(SysDBA) DatabaseBackup - TEST_DATABASES - FULL',
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


if dbo.fn_hadr_Is_Designated_backup( ''AG-TEST'')=1
begin
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
                                                        ,@AGName =
''AG-TEST''
end;
else print ''Backup skipped; Check on designated secondary node.''






',
@database_name=N'DBAUtilities',
@output_file_name=N'',
@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [AG-TEST DBs Backup Success Notification]    Script
Date: 2/21/2025 1:25:54 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'AG-TEST DBs Backup Success Notification',
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
set @TheSubject = N''Informational: '' + @@SERVERNAME + '' Backup of
AG-TEST DBs Succeeded.''
declare @TheRecipient varchar(200);
declare @TheBody varchar(200) =N''No Action Required.''

select @TheRecipient=ConfigValue from UtilitiesConfig where
ConfigTag=''Alert Email Notification'';
exec msdb.dbo.sp_send_dbmail @recipients=@TheRecipient,
@subject=@TheSubject, @body=@TheBody, @attach_query_result_as_file=0;
',
@database_name=N'DBAUtilities',
@output_file_name=N'',
@flags=12
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [AG-TEST DBs Backup Failure Notification]    Script
Date: 2/21/2025 1:25:54 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'AG-TEST DBs Backup Failure Notification',
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
set @TheSubject = N''Error: '' + @@SERVERNAME + '' AG-TEST  DB FULL Backup
Job Failed''
declare @TheRecipient varchar(200);
declare @TheBody varchar(200) =N''Job Name: (SysDBA) DatabaseBackup -
TEST_DATABASES - FULL. Please check log for additional information.''

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
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId,
@name=N'onetime',
@enabled=0,
@freq_type=1,
@freq_interval=0,
@freq_subday_type=0,
@freq_subday_interval=0,
@freq_relative_interval=0,
@freq_recurrence_factor=0,
@active_start_date=20220224,
@active_end_date=99991231,
@active_start_time=103645,
@active_end_time=235959,
@schedule_uid=N'517caedd-bb36-47cb-a4e7-a2df9aeb7cd4'
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

/****** Object:  Job [(SysDBA) DatabaseBackup - TEST_DATABASES - TRAN DUMP]
   Script Date: 2/21/2025 1:25:54 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date:
2/21/2025 1:25:54 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE
name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL',
@name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'(SysDBA) DatabaseBackup
- TEST_DATABASES - TRAN DUMP',
@enabled=1,
@notify_level_eventlog=3,
@notify_level_email=0,
@notify_level_netsend=0,
@notify_level_page=0,
@delete_level=0,
@description=N'Job auto updated on Primary Server <<servername>> at
11/20/2023 18:01:42 by SQL Server Agent Job Sync process to Secondary
Server <<servername>>.',
@category_name=N'Database Maintenance',
@owner_login_name=N'<<username>>', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [(SysDBA) DatabaseBackup - TEST_DATABASES - TRAN
DUMP]    Script Date: 2/21/2025 1:25:54 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'(SysDBA) DatabaseBackup - TEST_DATABASES - TRAN DUMP',
@step_id=1,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=0,
@on_fail_action=4,
@on_fail_step_id=3,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'declare @vCredential varchar(512)
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

if dbo.fn_hadr_Is_Designated_backup( ''AG-TEST'')=1
begin
EXEC usp_backupdatabasetos3  @pIsSystem = 0
                   ,@pType = ''TRN''
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
                                                        ,@AGName =
''AG-TEST''
end;
else print ''Backup skipped; Check on designated secondary node.''',
@database_name=N'DBAUtilities',
@output_file_name=N'',
@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [TEST_PRD DBs Backup Success Notification]    Script
Date: 2/21/2025 1:25:54 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'TEST_PRD DBs Backup Success Notification',
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
set @TheSubject = N''Informational: '' + @@SERVERNAME + '' Backup of
TEST_PRD DBs Trans Backup Succeeded.''
declare @TheRecipient varchar(200);
declare @TheBody varchar(200) =N''No Action Required.''

select @TheRecipient=ConfigValue from UtilitiesConfig where
ConfigTag=''Alert Email Notification'';
exec msdb.dbo.sp_send_dbmail @recipients=@TheRecipient,
@subject=@TheSubject, @body=@TheBody, @attach_query_result_as_file=0;
',
@database_name=N'DBAUtilities',
@output_file_name=N'',
@flags=12
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [TEST_PRD DBs Backup Failure Notification]    Script
Date: 2/21/2025 1:25:54 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'TEST_PRD DBs Backup Failure Notification',
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
set @TheSubject = N''Error: '' + @@SERVERNAME + '' TEST_PRD DB TRAN DUMP
Backup Job Failed''
declare @TheRecipient varchar(200);
declare @TheBody varchar(200) =N''Job Name: (SysDBA) DatabaseBackup -
TEST_DATABASES - TRAN DUMP. Please check log for additional information.''

select @TheRecipient=ConfigValue from UtilitiesConfig where
ConfigTag=''Alert Email Notification'';
exec msdb.dbo.sp_send_dbmail @recipients=@TheRecipient,
@subject=@TheSubject, @body=@TheBody, @attach_query_result_as_file=0;
',
@database_name=N'DBAUtilities',
@output_file_name=N'',
@flags=12
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [No Op]    Script Date: 2/21/2025 1:25:54 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'No
Op',
@step_id=4,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'Return',
@database_name=N'master',
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

