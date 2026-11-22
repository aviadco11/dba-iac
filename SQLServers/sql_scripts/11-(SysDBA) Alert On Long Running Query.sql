USE [msdb]
GO

/****** Object:  Job [(SysDBA) Alert On Long Running Query]    Script Date:
2/13/2025 4:44:40 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date:
2/13/2025 4:44:40 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE
name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL',
@name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'(SysDBA) Alert On Long
Running Query',
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
/****** Object:  Step [Run Proc]    Script Date: 2/13/2025 4:44:40 PM
******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run
Proc',
@step_id=1,
@cmdexec_success_code=0,
@on_success_action=3,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'exec DBAUtilities.dbo.AlertOnLongQuery',
@database_name=N'DBAUtilities',
@output_file_name=N'',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Email the users directly]    Script Date: 2/13/2025
4:44:40 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'Email the users directly',
@step_id=2,
@cmdexec_success_code=0,
@on_success_action=3,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'if DATEPART(minute, getdate()) between 0 and 4
begin
exec dbautilities.dbo.AlertOnLongRunningQueryEmailUsers
@collectionthreshold =5,
@runningThreshold =120,
@domain =''crb'',
@pMailProfile = ''CRB EXCH''
end',
@database_name=N'DBAUtilities',
@output_file_name=N'',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Kill sleeping spids with open tran count over 3 hrs]
   Script Date: 2/13/2025 4:44:40 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'Kill sleeping spids with open tran count over 3 hrs',
@step_id=3,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'
DECLARE @s nVARCHAR(MAX)
DECLARE @r INT;
    SET @r = 1;

EXEC sp_WhoIsActive  @output_column_list = ''[dd
hh:mm:ss.mss],[session_id],[login_name],[host_name],[database_name],[collection_time],[start_time],[sql_text],[blocking_session_id],[program_name],
[wait_info],[CPU],[reads],[writes],[physical_reads],[used_memory],[status],[open_tran_count],[percent_complete]'',
@return_schema = 1,
@schema = @s OUTPUT;

SET @s = REPLACE(@s, ''<table_name>'', ''tempdb.dbo.WHO_IS_KILL'')
IF OBJECT_ID(''tempdb.dbo.WHO_IS_KILL'', ''U'') IS NOT NULL
begin
  print ''tempdb.dbo.WHO_IS_KILL will be Re-Created.'';
  drop table tempdb.dbo.WHO_IS_KILL;
end;
else print ''tempdb.dbo.WHO_IS_KILL will be created.'';

EXEC(@s);

exec DBAUtilities.dbo.sp_WhoIsActive  @output_column_list = ''[dd
hh:mm:ss.mss],[session_id],[login_name],[host_name],[database_name],[collection_time],[start_time],[sql_text],[blocking_session_id],[program_name],
[wait_info],[CPU],[reads],[writes],[physical_reads],[used_memory],[status],[open_tran_count],[percent_complete]'',
@destination_table = ''tempdb.dbo.WHO_IS_KILL'';

delete from tempdb.dbo.WHO_IS_KILL where login_name in (select Login_Name
from DBAUtilities.[Monitoring].[OmittedLogins]);

--- update fix below as [dd hh:mm:ss.mss] sometimes outputs 16 chars
instead of 15, as 15 is the standard( can''t figure out why yet  (
padbprod01) )
update tempdb.dbo.WHO_IS_KILL set [dd hh:mm:ss.mss] = right([dd
hh:mm:ss.mss] ,15)
where len([dd hh:mm:ss.mss]) > 15;

--select [dd hh:mm:ss.mss]
--     , [session_id]
--     , [login_name]
--     , [host_name]
--     , [database_name]
--     , [collection_time]
--     , [start_time]
--     , [sql_text]
--     , [blocking_session_id]
--     , [program_name]
--     , [wait_info]
--     , [CPU]
--     , [reads]
--     , [writes]
--     , [physical_reads]
--     , [used_memory]
--     , [status]
--     , [open_tran_count]
--     , [percent_complete]
--    from tempdb.dbo.WHO_IS_KILL
--where [dd hh:mm:ss.mss] > ''00 03:00:00.000'' ;

    declare @sessID varchar(30)
       select  @sessID =  cast(session_id as varchar( 10)) from
tempdb.dbo.WHO_IS_KILL where [dd hh:mm:ss.mss] > ''00 03:00:00.000''  and
open_tran_count > 0  and status = ''sleeping''

    declare KillCursor cursor for
select session_id  from tempdb.dbo.WHO_IS_KILL where [dd hh:mm:ss.mss] >
''00 03:00:00.000''  and open_tran_count > 0  and status = ''sleeping''
open KillCursor

fetch next from KillCursor into @sessID
while @@fetch_status = 0
begin
declare @cmd nvarchar (50)
set @cmd = ''Kill '' + @sessID
exec sp_executesql  @cmd
print ''Killed following Spids with command =  '' + @cmd

fetch next from KillCursor into @sessID
end

close KillCursor
deallocate KillCursor',
@database_name=N'DBAUtilities',
@output_file_name=N'',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id
= 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId,
@name=N'CollectorSchedule_Every_5min',
@enabled=1,
@freq_type=4,
@freq_interval=1,
@freq_subday_type=4,
@freq_subday_interval=5,
@freq_relative_interval=0,
@freq_recurrence_factor=0,
@active_start_date=20160430,
@active_end_date=99991231,
@active_start_time=0,
@active_end_time=235959,
@schedule_uid=N'23f60231-26d4-4ae9-9fce-8623cede5630'
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

