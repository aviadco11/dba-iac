USE [msdb]
GO

/****** Object:  Job [(SysDBA) Daily_DB_Maintenance_Jobs]    Script Date:
2/13/2025 4:46:35 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date:
2/13/2025 4:46:35 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE
name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL',
@name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'(SysDBA)
Daily_DB_Maintenance_Jobs',
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
/****** Object:  Step [Daily DBA Maintenance Jobs Start]    Script Date:
2/13/2025 4:46:36 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'Daily DBA Maintenance Jobs Start',
@step_id=1,
@cmdexec_success_code=0,
@on_success_action=3,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'declare @TheSubject varchar(200)
set @TheSubject = N''Informational: '' + @@SERVERNAME + '' Daily DBA
Maintenance Jobs Running'';
declare @Thebody varchar(100)=N''No Action is required.''
declare @vShout varchar(1);
select @vShout=ConfigValue from UtilitiesConfig where ConfigTag=''Daily and
Weekly Start Done'';

if @vShout=''Y''
begin
   declare @TheRecipient varchar(200);
   select @TheRecipient=ConfigValue from UtilitiesConfig where
ConfigTag=''Alert Email Notification'';
   exec msdb.dbo.sp_send_dbmail @recipients=@TheRecipient,
@subject=@TheSubject, @body=@TheBody, @attach_query_result_as_file=0;
end;
',
@database_name=N'DBAUtilities',
@output_file_name=N'',
@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [(SysDBA) DatabaseBackup - SYSTEM_DATABASES - FULL]
 Script Date: 2/13/2025 4:46:36 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'(SysDBA) DatabaseBackup - SYSTEM_DATABASES - FULL',
@step_id=2,
@cmdexec_success_code=0,
@on_success_action=3,
@on_success_step_id=0,
@on_fail_action=3,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'exec StartJobWithWait @par_JobName=''(SysDBA) DatabaseBackup -
SYSTEM_DATABASES - FULL'', @par_waitInterval=''00:00:30''
',
@database_name=N'DBAUtilities',
@output_file_name=N'',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [(SysDBA) DatabaseBackup - USER_DATABASES - FULL]
 Script Date: 2/13/2025 4:46:36 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'(SysDBA) DatabaseBackup - USER_DATABASES - FULL',
@step_id=3,
@cmdexec_success_code=0,
@on_success_action=3,
@on_success_step_id=0,
@on_fail_action=3,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'
exec StartJobWithWait @par_JobName=''(SysDBA) DatabaseBackup -
USER_DATABASES - FULL'', @par_waitInterval=''00:00:30''
',
@database_name=N'DBAUtilities',
@output_file_name=N'',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [(SysDBA) DatabaseBackup - CP_QA_DATABASES - FULL]
 Script Date: 2/13/2025 4:46:36 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'(SysDBA) DatabaseBackup - TEST_DATABASES - FULL',
@step_id=4,
@cmdexec_success_code=0,
@on_success_action=3,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'exec StartJobWithWait @par_JobName=''(SysDBA) DatabaseBackup -
TEST_DATABASES - FULL'', @par_waitInterval=''00:00:30''',
@database_name=N'DBAUtilities',
@output_file_name=N'',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [(SysDBA) DatabaseIntegrityCheck - SYSTEM_DATABASES]
   Script Date: 2/13/2025 4:46:36 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'(SysDBA) DatabaseIntegrityCheck - SYSTEM_DATABASES',
@step_id=5,
@cmdexec_success_code=0,
@on_success_action=3,
@on_success_step_id=0,
@on_fail_action=3,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'exec StartJobWithWait @par_JobName=''(SysDBA)
DatabaseIntegrityCheck - SYSTEM_DATABASES'', @par_waitInterval=''00:00:30''
',
@database_name=N'DBAUtilities',
@output_file_name=N'',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [(SysDBA) DatabaseIntegrityCheck - USER_DATABASES]
 Script Date: 2/13/2025 4:46:36 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'(SysDBA) DatabaseIntegrityCheck - USER_DATABASES',
@step_id=6,
@cmdexec_success_code=0,
@on_success_action=3,
@on_success_step_id=0,
@on_fail_action=3,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'exec StartJobWithWait @par_JobName=''(SysDBA)
DatabaseIntegrityCheck - USER_DATABASES'', @par_waitInterval=''00:00:30''
',
@database_name=N'DBAUtilities',
@output_file_name=N'',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [(SysDBA) IndexOptimize - USER_DATABASES]    Script
Date: 2/13/2025 4:46:36 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'(SysDBA) IndexOptimize - USER_DATABASES',
@step_id=7,
@cmdexec_success_code=0,
@on_success_action=3,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'exec StartJobWithWait @par_JobName=''(SysDBA) IndexOptimize -
USER_DATABASES'', @par_waitInterval=''00:00:30''
',
@database_name=N'DBAUtilities',
@output_file_name=N'',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [(SysDBA) Purge SQL Backups History]    Script Date:
2/13/2025 4:46:36 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'(SysDBA) Purge SQL Backups History',
@step_id=8,
@cmdexec_success_code=0,
@on_success_action=3,
@on_success_step_id=0,
@on_fail_action=3,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'exec StartJobWithWait @par_JobName=''(SysDBA) Purge SQL Backups
History'', @par_waitInterval=''00:00:10''
',
@database_name=N'DBAUtilities',
@output_file_name=N'',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [(SysDBA) Purge SQL Jobs History]    Script Date:
2/13/2025 4:46:36 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'(SysDBA) Purge SQL Jobs History',
@step_id=9,
@cmdexec_success_code=0,
@on_success_action=3,
@on_success_step_id=0,
@on_fail_action=3,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'exec StartJobWithWait @par_JobName=''(SysDBA) Purge SQL Jobs
History'', @par_waitInterval=''00:00:10''
',
@database_name=N'DBAUtilities',
@output_file_name=N'',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [(SysDBA) CommandLog Cleanup]    Script Date:
2/13/2025 4:46:36 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'(SysDBA) CommandLog Cleanup',
@step_id=10,
@cmdexec_success_code=0,
@on_success_action=3,
@on_success_step_id=0,
@on_fail_action=3,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'exec StartJobWithWait @par_JobName=''(SysDBA) CommandLog
Cleanup'', @par_waitInterval=''00:00:10''
',
@database_name=N'DBAUtilities',
@output_file_name=N'',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Daily DBA Maintenance Jobs End]    Script Date:
2/13/2025 4:46:36 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'Daily DBA Maintenance Jobs End',
@step_id=11,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=0,
@on_fail_action=1,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'declare @TheSubject varchar(200)
set @TheSubject = N''Informational: '' + @@SERVERNAME + '' Daily DBA
Maintenance Jobs Done'';
declare @Thebody varchar(100)=N''No Action is required.''
declare @vShout varchar(1);
select @vShout=ConfigValue from UtilitiesConfig where ConfigTag=''Daily and
Weekly Start Done'';

if @vShout=''Y''
begin
   declare @TheRecipient varchar(200);
   select @TheRecipient=ConfigValue from UtilitiesConfig where
ConfigTag=''Alert Email Notification'';
   exec msdb.dbo.sp_send_dbmail @recipients=@TheRecipient,
@subject=@TheSubject, @body=@TheBody, @attach_query_result_as_file=0;
end;
',
@database_name=N'DBAUtilities',
@output_file_name=N'',
@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id
= 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId,
@name=N'Sun-Fri @ 1 am',
@enabled=1,
@freq_type=8,
@freq_interval=63,
@freq_subday_type=1,
@freq_subday_interval=0,
@freq_relative_interval=0,
@freq_recurrence_factor=1,
@active_start_date=20210616,
@active_end_date=99991231,
@active_start_time=10000,
@active_end_time=235959,
@schedule_uid=N'b0b8ddc1-bbd0-4fef-85ab-01e170d55a36'
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

