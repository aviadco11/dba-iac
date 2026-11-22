USE [msdb]
GO

/****** Object:  Job [(SysDBA) Server Login Export]    Script Date:
8/21/2025 12:42:20 PM ******/
--EXEC msdb.dbo.sp_delete_job  @job_name=N'(SysDBA) Server Login Export',
@delete_unused_schedule=1
--go

IF EXISTS (
    SELECT 1
    FROM msdb.dbo.sysjobs
    WHERE name = N'(SysDBA) Server Login Export'
)
begin
    exec msdb.dbo.sp_delete_job @job_name = N'(SysDBA) Server Login Export';
END

declare @suser varchar (10)
select @suser = name from sys.syslogins where sid = 0x01
--select @suser

/****** Object:  Job [(SysDBA) Server Login Export]    Script Date:
8/21/2025 2:44:59 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date:
8/21/2025 2:44:59 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE
name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL',
@name=N'Database Maintenance'
if (@@error <> 0 or @ReturnCode <> 0) goto QuitWithRollback

end

DECLARE @jobId BINARY(16)
exec @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'(SysDBA) Server Login
Export',
@enabled=1,
@notify_level_eventlog=3,
@notify_level_email=0,
@notify_level_netsend=0,
@notify_level_page=0,
@delete_level=0,
@description=N'Exports Sever Logins to file system to preserve in case of
instances failure',
@category_name=N'Database Maintenance',
@owner_login_name=@suser,
@job_id = @jobId output
if (@@error <> 0 or @ReturnCode <> 0) goto QuitWithRollback
/****** Object:  Step [Server Login Export]    Script Date: 8/21/2025
2:44:59 PM ******/
exec @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'Server Login Export',
@step_id=1,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'

exec dbo.[GetServerLoginInfo]  @pKeepDays=30;


',
@database_name=N'DBAUtilities',
@flags=0
if (@@error <> 0 or @ReturnCode <> 0) goto QuitWithRollback
exec @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id
= 1
if (@@error <> 0 or @ReturnCode <> 0) goto QuitWithRollback
exec @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId,
@name=N'Daily_Login_Export',
@enabled=1,
@freq_type=4,
@freq_interval=1,
@freq_subday_type=1,
@freq_subday_interval=0,
@freq_relative_interval=0,
@freq_recurrence_factor=0,
@active_start_date=20250821,
@active_end_date=99991231,
@active_start_time=0,
@active_end_time=235959,
@schedule_uid=N'a4a20c28-b010-4e13-8866-b4b1ebbe4ff9'
if (@@error <> 0 or @ReturnCode <> 0) goto QuitWithRollback
exec @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name
= N'(local)'
if (@@error <> 0 or @ReturnCode <> 0) goto QuitWithRollback
commit transaction
goto EndSave
QuitWithRollback:
    if (@@trancount > 0) rollback transaction
EndSave:
go



