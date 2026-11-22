USE [msdb]
GO

/****** Object:  Job [(SysDBA) Transaction Logs Stream]    Script Date:
2/13/2025 4:53:52 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date:
2/13/2025 4:53:52 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE
name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL',
@name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'(SysDBA) Transaction
Logs Stream',
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
/****** Object:  Step [Exec All Tran Dumps]    Script Date: 2/13/2025
4:53:52 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'Exec All Tran Dumps',
@step_id=1,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'declare vCur cursor for select name from msdb.dbo.sysjobs
   where name like ''%TRAN DUMP''
   order by name;

declare @vSqlAgentJobName varchar(1000);

open vCur;
fetch next from vCur into @vSqlAgentJobName;
while @@FETCH_STATUS = 0
begin
   print @vSqlAgentJobName;
   exec DBAUtilities.dbo.StartJobWithWait @par_JobName=@vSqlAgentJobName,
@par_waitInterval=''00:00:10''
   fetch next from vCur into @vSqlAgentJobName;
end;
CLOSE vCur;
DEALLOCATE vCur;',
@database_name=N'DBAUtilities',
@output_file_name=N'',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id
= 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Dump
Tran Daily Strem 2am - midmight',
@enabled=1,
@freq_type=4,
@freq_interval=1,
@freq_subday_type=4,
@freq_subday_interval=15,
@freq_relative_interval=0,
@freq_recurrence_factor=0,
@active_start_date=20190218,
@active_end_date=99991231,
@active_start_time=20400,
@active_end_time=235959,
@schedule_uid=N'f6f96f12-830f-4ea0-82b1-9f08c542fba3'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Dump
Tran Daily Strem midnight-2am',
@enabled=1,
@freq_type=4,
@freq_interval=1,
@freq_subday_type=4,
@freq_subday_interval=10,
@freq_relative_interval=0,
@freq_recurrence_factor=0,
@active_start_date=20190217,
@active_end_date=99991231,
@active_start_time=400,
@active_end_time=15959,
@schedule_uid=N'ede0a5a4-fb47-4285-9028-8e2aa9d98343'
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

