USE [msdb]
GO

/****** Object:  Job [(SysDBA) Alert On Long Running SQL Agent Job]
 Script Date: 2/5/2025 5:13:16 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date:
2/5/2025 5:13:16 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE
name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL',
@name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'(SysDBA) Alert On Long
Running SQL Agent Job',
@enabled=1,
@notify_level_eventlog=3,
@notify_level_email=0,
@notify_level_netsend=0,
@notify_level_page=0,
@delete_level=0,
@description=N'Captures long running SQL Agent Jobs by timeframe and Job
Name Prefix',
@category_name=N'[Uncategorized (Local)]',
@owner_login_name=N'<<username>>', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [SysDBA Alert]    Script Date: 2/5/2025 5:13:16 AM
******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'SysDBA Alert',
@step_id=1,
@cmdexec_success_code=0,
@on_success_action=3,
@on_success_step_id=0,
@on_fail_action=3,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'exec dbautilities.dbo.LongRunning_AgentJobAlert_SysDBADetails
@pEmail=''<<email>>;''
,@p_runtime_mm = 900
,@NamePrefix  = SysDBA',
@database_name=N'DBAUtilities',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Reporting Alert]    Script Date: 2/5/2025 5:13:16 AM
******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'Reporting Alert',
@step_id=2,
@cmdexec_success_code=0,
@on_success_action=3,
@on_success_step_id=0,
@on_fail_action=3,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'
exec dbautilities.dbo.LongRunning_AgentJobAlert
@pEmail=''<<email>>;<<email>>;<<email>>''
,@p_runtime_mm = 60
,@NamePrefix  = Reporting',
@database_name=N'DBAUtilities',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [SSIS Alert]    Script Date: 2/5/2025 5:13:16 AM
******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'SSIS Alert',
@step_id=3,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=0,
@on_fail_action=1,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'
exec dbautilities.dbo.LongRunning_AgentJobAlert
@pEmail=''<<email>>;<<email>>;<<email>>''
,@p_runtime_mm = 60
,@NamePrefix  = SSIS',
@database_name=N'DBAUtilities',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id
= 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId,
@name=N'Every 75 Minutes',
@enabled=1,
@freq_type=4,
@freq_interval=1,
@freq_subday_type=4,
@freq_subday_interval=75,
@freq_relative_interval=0,
@freq_recurrence_factor=0,
@active_start_date=20220705,
@active_end_date=99991231,
@active_start_time=0,
@active_end_time=235959,
@schedule_uid=N'77f91fa1-141f-4575-9329-238dc69a3bdc'
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

/****** Object:  Job [(SysDBA) Check Mail Status]    Script Date: 2/5/2025
5:14:26 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date:
2/5/2025 5:14:26 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE
name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL',
@name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'(SysDBA) Check Mail
Status',
@enabled=1,
@notify_level_eventlog=3,
@notify_level_email=0,
@notify_level_netsend=0,
@notify_level_page=0,
@delete_level=0,
@description=N'Check MAil Status',
@category_name=N'Database Maintenance',
@owner_login_name=N'<<username>>', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [check_mail_status]    Script Date: 2/5/2025 5:14:27
AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'check_mail_status',
@step_id=1,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'use [DBAUtilities]
go
exec CheckMailStatus',
@database_name=N'DBAUtilities',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id
= 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId,
@name=N'CheckMailStatus',
@enabled=1,
@freq_type=4,
@freq_interval=1,
@freq_subday_type=1,
@freq_subday_interval=0,
@freq_relative_interval=0,
@freq_recurrence_factor=0,
@active_start_date=20230427,
@active_end_date=99991231,
@active_start_time=230000,
@active_end_time=235959,
@schedule_uid=N'13f9400a-a36e-4460-8557-b3b36ca04cfd'
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

/****** Object:  Job [(SysDBA) CheckAGHealth]    Script Date: 2/5/2025
5:14:42 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date:
2/5/2025 5:14:42 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE
name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL',
@name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'(SysDBA)
CheckAGHealth',
@enabled=1,
@notify_level_eventlog=3,
@notify_level_email=0,
@notify_level_netsend=0,
@notify_level_page=0,
@delete_level=0,
@description=N'this job check AG Health every 10 minutes.',
@category_name=N'Database Maintenance',
@owner_login_name=N'<<username>>', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CheckAGHealth]    Script Date: 2/5/2025 5:14:42 AM
******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'CheckAGHealth',
@step_id=1,
@cmdexec_success_code=0,
@on_success_action=3,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'exec [DBAUtilities].[dbo].[AlertOnAGHealth]
@pEmail=''<<email>>;<<email>>;<<email>>''',
@database_name=N'DBAUtilities',
@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CheckAGLatency]    Script Date: 2/5/2025 5:14:42 AM
******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'CheckAGLatency',
@step_id=2,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'print concat(''*** Current Time: '', RIGHT(CONVERT(VARCHAR(26),
GETDATE(), 109),14))
if DATEPART(minute, getdate()) between 0 and 9
begin
print ''*** Check AG Latency''
exec [DBAUtilities].[dbo].[AlertOnAGLatency]
@pEmail=''<<email>>;<<email>>;<<email>>''
end
else print ''*** Skip Check AG Latency''',
@database_name=N'DBAUtilities',
@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id
= 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId,
@name=N'CollectorSchedule_Every_10min',
@enabled=1,
@freq_type=4,
@freq_interval=1,
@freq_subday_type=4,
@freq_subday_interval=10,
@freq_relative_interval=0,
@freq_recurrence_factor=0,
@active_start_date=20170822,
@active_end_date=99991231,
@active_start_time=0,
@active_end_time=235959,
@schedule_uid=N'dcdc8189-da0a-41ef-aa79-e39016f3bdfa'
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

/****** Object:  Job [(SysDBA) Collect Tempdb Size]    Script Date:
2/5/2025 5:14:55 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date:
2/5/2025 5:14:55 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE
name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL',
@name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'(SysDBA) Collect Tempdb
Size',
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
/****** Object:  Step [collect_tempdb_size]    Script Date: 2/5/2025
5:14:55 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'collect_tempdb_size',
@step_id=1,
@cmdexec_success_code=0,
@on_success_action=3,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'use tempdb;
insert into [DBAUtilities].[HealthCheck].[TempDBSize]
 SELECT getdate() as collection_time,
DB_NAME() AS [database_name],
        name AS [FileName],
        type_desc as [type_desc],
        cast(size/128.0 as numeric(9,1)) AS CurrentSizeMB,
        cast(size/128.0 - CAST(FILEPROPERTY(name, ''SpaceUsed'') AS
INT)/128.0 as numeric(9,1)) AS FreeSpaceMB,
cast(cast(CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT)/128.0 as
numeric(9,1)) / cast(size/128.0 as numeric(9,1))*100 as numeric(4,1)) as
[PercentUsed(%)] ,
dm.version_store_reserved_page_count*8/1024 as VersionStore_usedMB,
dm.user_object_reserved_page_count*8/1024 as UserObjects_usedMB
FROM sys.database_files df
left join sys.dm_db_file_space_usage dm
on df.file_id = dm.file_id
WHERE type IN (0,1);',
@database_name=N'DBAUtilities',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [collect_total_tempdb_size_and_find_consumers]
 Script Date: 2/5/2025 5:14:55 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'collect_total_tempdb_size_and_find_consumers',
@step_id=2,
@cmdexec_success_code=0,
@on_success_action=3,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'Use tempdb

use tempdb

declare @perc numeric(5,2), @version_store_size DECIMAL(25,2)
select @perc = cast(((SUM(allocated_extent_page_count)*1.0/128) /
(SUM(total_page_count)*1.0/128)) * 100 as numeric(5,2)),
@version_store_size = CAST(SUM((version_store_reserved_page_count) * 8) /
1024. AS DECIMAL(25, 2))
FROM sys.dm_db_file_space_usage

insert into [DBAUtilities].[HealthCheck].[TempDBSizeUsed]
SELECT getdate() as [collection_time],CAST(SUM((total_page_count) * 8) /
1024. AS DECIMAL(25, 2)) AS Total_Size_MB
,--Works on SQL 2012 and future editions
CAST(SUM((unallocated_extent_page_count) * 8) / 1024. AS DECIMAL(25, 2)) AS
Free_Space_MB
,CAST(SUM((user_object_reserved_page_count) * 8) / 1024. AS DECIMAL(25, 2))
AS User_Objects_MB
,CAST(SUM((internal_object_reserved_page_count) * 8) / 1024. AS DECIMAL(25,
2)) AS Internal_Objects_MB
,CAST(SUM((version_store_reserved_page_count) * 8) / 1024. AS DECIMAL(25,
2)) AS Version_Store_MB
,@perc as [PercentUsed(%)]
FROM tempdb.sys.dm_db_file_space_usage


if @perc >= 80
begin
exec [DBAUtilities].[dbo].sp_whoisactive
@sort_order = ''[tempdb_current] DESC'',
@get_plans = 1,
@output_column_list = ''[dd
hh:mm:ss.mss][session_id][login_name][host_name][database_name][start_time][sql_text][query_plan][program_name][wait_info][temp%]'',
@destination_table = ''DBAUtilities.Monitoring.tempdbConsumers'';
end',
@database_name=N'DBAUtilities',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [alert_version_Store_size]    Script Date: 2/5/2025
5:14:55 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'alert_version_Store_size',
@step_id=3,
@cmdexec_success_code=0,
@on_success_action=3,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'print concat(''*** Current Time: '', RIGHT(CONVERT(VARCHAR(26),
GETDATE(), 109),14))
if DATEPART(minute, getdate()) between 1 and 6
begin
print ''*** Check version store size''
exec [DBAUtilities].[dbo].[AlertOnLargeVersionStore]
@pEmail=''<<email>>;<<email>>;<<email>>'',@ThresholdVersionStoreSizeMB=300000,
@ThresholdDurationVersionStoreSizeMin=-60
end
else print ''*** Skip Check version store size''',
@database_name=N'DBAUtilities',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [purge_retention]    Script Date: 2/5/2025 5:14:55 AM
******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'purge_retention',
@step_id=4,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'delete   FROM [DBAUtilities].[HealthCheck].[TempDBSize] where
[collection_time] < dateadd(month,-1,getdate())
GO
delete   FROM [DBAUtilities].[HealthCheck].[TempDBSizeUsed] where
[collection_time] < dateadd(month,-1,getdate())
GO
delete   FROM [DBAUtilities].[Monitoring].[tempdbConsumers] where
[start_time] < dateadd(month,-1,getdate())
GO
',
@database_name=N'DBAUtilities',
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id
= 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId,
@name=N'every_5min',
@enabled=1,
@freq_type=4,
@freq_interval=1,
@freq_subday_type=4,
@freq_subday_interval=5,
@freq_relative_interval=0,
@freq_recurrence_factor=0,
@active_start_date=20241021,
@active_end_date=99991231,
@active_start_time=0,
@active_end_time=235959,
@schedule_uid=N'bc4e861c-d057-4ae3-b9db-9782c80bcb0a'
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







