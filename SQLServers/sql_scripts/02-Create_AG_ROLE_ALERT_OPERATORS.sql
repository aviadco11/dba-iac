USE [msdb]
GO

/****** Object:  Job [(SysDBA) AG Role Change Alert]    Script Date:
10/28/2024 2:54:46 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date:
10/28/2024 2:54:46 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE
name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL',
@name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'(SysDBA) AG Role Change
Alert',
@enabled=1,
@notify_level_eventlog=3,
@notify_level_email=0,
@notify_level_netsend=0,
@notify_level_page=0,
@delete_level=0,
@description=N'Send email on latest AG role change supplied by AlwaysOn -
Role Change Alert',
@category_name=N'[Uncategorized (Local)]',
@owner_login_name=N'<<username>>', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Wait for 20 seconds]    Script Date: 10/28/2024
2:54:46 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'Wait for 20 seconds',
@step_id=1,
@cmdexec_success_code=0,
@on_success_action=3,
@on_success_step_id=0,
@on_fail_action=3,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'WAITFOR DELAY ''00:00:20''',
@database_name=N'master',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Fire Procedure]    Script Date: 10/28/2024 2:54:46
PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'Fire Procedure',
@step_id=2,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'EXEC DBAUtilities.dbo.GetAG_LatestRoleChange',
@database_name=N'DBAUtilities',
--@output_file_name=N'',
@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [NoOp]    Script Date: 10/28/2024 2:54:46 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'NoOp',
@step_id=3,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'select getdate()',
@database_name=N'master',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id
= 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId,
@name=N'Restart Notify Schedule',
@enabled=1,
@freq_type=64,
@freq_interval=0,
@freq_subday_type=0,
@freq_subday_interval=0,
@freq_relative_interval=0,
@freq_recurrence_factor=0,
@active_start_date=20180626,
@active_end_date=99991231,
@active_start_time=0,
@active_end_time=235959,
@schedule_uid=N'3706e58d-ae08-49cb-8fa5-f25235ad436f'
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



USE [msdb]
GO

----------------------------
--CREATE OPERATOR FOR ALERTS
----------------------------
/****** Object:  Operator [CRB_DBA]    Script Date: 10/28/2024 2:46:25 PM
******/
EXEC msdb.dbo.sp_add_operator @name=N'CRB_DBA',
@enabled=1,
@weekday_pager_start_time=90000,
@weekday_pager_end_time=180000,
@saturday_pager_start_time=90000,
@saturday_pager_end_time=180000,
@sunday_pager_start_time=90000,
@sunday_pager_end_time=180000,
@pager_days=0,
@email_address=N'<<email>>',
@category_name=N'[Uncategorized]'
GO


----------------------
--CREATE AG ROLE ALERT
----------------------
/****** Object:  Alert [AG Role Change Alert]    Script Date: 10/28/2024
2:45:59 PM ******/
EXEC msdb.dbo.sp_add_alert @name=N'AG Role Change Alert',
@message_id=35202,
@severity=0,
@enabled=1,
@delay_between_responses=300,
@include_event_description_in=0,
@category_name=N'[Uncategorized]',
@job_name = '(SysDBA) AG Role Change Alert'
--@job_id=N'2575bce5-96a7-45db-9547-a9b0d5db6362'
GO




