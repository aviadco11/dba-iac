USE [msdb]
GO

/****** Object:  Job [[SYSDBA] AG Role Change Alert]    Script Date:
8/1/2023 3:41:54 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date:
8/1/2023 3:41:54 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE
name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL',
@name=N'[Uncategorized (Local)]'
if (@@error <> 0 or @ReturnCode <> 0) goto QuitWithRollback

end

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'[SYSDBA] AG Role Change
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
/****** Object:  Step [Wait for 20 seconds]    Script Date: 8/1/2023
3:41:54 PM ******/
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
/****** Object:  Step [Fire Procedure]    Script Date: 8/1/2023 3:41:54 PM
******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'Fire Procedure',
@step_id=2,
@cmdexec_success_code=0,
@on_success_action=3,
@on_success_step_id=0,
@on_fail_action=3,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'EXEC DBAUtilities.dbo.GetAG_LatestRoleChange',
@database_name=N'DBAUtilities',
@output_file_name=N'\\<<servername>>.<<domain>>\share\SQLJobsOutput-prd$\<<servername>>\AG_Role_Change_Alert_$(ESCAPE_NONE(STRTDT))_$(ESCAPE_NONE(STRTTM)).txt',

@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Remove SSRS Subscriptions on Secondary Node]
 Script Date: 8/1/2023 3:41:54 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'Remove SSRS Subscriptions on Secondary Node',
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
WAITFOR DELAY ''00:00:30''

Use DBAUtilities;

if [dbo].[fn_hadr_database_is_primary]( ''ReportServer'')=0
begin
print ''Node is not Primary , removing  ssrs jobs''

Use Master;

IF OBJECT_ID(''tempdb..#DeleteReportServerJobs'') IS NOT NULL
DROP TABLE #DeleteReportServerJobs;

SELECT *, Processed = CONVERT(BIT, 0)
INTO #DeleteReportServerJobs
FROM msdb.dbo.sysjobs
WHERE description = ''This job is owned by a report server process.
Modifying this job could result in database incompatibilities. Use Report
Manager or Management Studio to update this job.''

DECLARE @JobID UNIQUEIDENTIFIER
WHILE (SELECT COUNT(*) FROM #DeleteReportServerJobs WHERE Processed = 0) > 0
BEGIN
SET @JobID = NULL
SELECT TOP 1 @JobID = job_id FROM #DeleteReportServerJobs WHERE Processed =
0
EXEC msdb.dbo.sp_delete_job @JobID;
UPDATE #DeleteReportServerJobs
SET Processed = 1
WHERE job_id = @JobID
END

SELECT *
FROM #DeleteReportServerJobs
end;

else
  Print ''Primary Node,skipping ssrs job delete''


',
@database_name=N'DBAUtilities',
@output_file_name=N'\\<<servername>>.<<domain>>\share\SQLJobsOutput-prd$\<<servername>>\AG_Role_Change_Alert_$(ESCAPE_NONE(STRTDT))_$(ESCAPE_NONE(STRTTM)).txt',

@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [****DISABLE Primary subscriptions for now , remove
step when datateam start using]    Script Date: 8/1/2023 3:41:54 PM ******/
exec @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId,
@step_name=N'****DISABLE Primary subscriptions for now , remove step when
datateam start using',
@step_id=4,
@cmdexec_success_code=0,
@on_success_action=1,
@on_success_step_id=0,
@on_fail_action=2,
@on_fail_step_id=0,
@retry_attempts=0,
@retry_interval=0,
@os_run_priority=0, @subsystem=N'TSQL',
@command=N'
WAITFOR DELAY ''00:00:30''

Use DBAUtilities;

if [dbo].[fn_hadr_database_is_primary]( ''ReportServer'')=1
begin
print ''Node is  Primary , disabling ssrs jobs''

use ReportServer;
drop table if exists #temp;
select c.[Name]                                  ReportName
     , s.ScheduleID                              JobName
     , ss.[Description]                          SubscriptionDescription
     , ss.DeliveryExtension                      SubscriptionType
     , c.[Path]                                  ReportFolderPath
     , row_number() over (order by s.ScheduleID) as rn
into #Temp
from ReportSchedule          rs
    inner join Schedule      s
        on rs.ScheduleID = s.ScheduleID
    inner join Subscriptions ss
        on rs.SubscriptionID = ss.SubscriptionID
    inner join [Catalog]     c
        on rs.ReportID = c.ItemID
           and ss.Report_OID = c.ItemID;
---select * from #temp

declare @count    int
      , @maxCount int;
set @count = 1;
select @maxCount = max(rn)
from #Temp;
declare @job_name varchar(max);
while @count <= @maxCount
begin
    select @job_name = JobName
    from #Temp
    where rn = @count;
    exec msdb..sp_update_job @job_name = @job_name, @enabled = 0;
    set @count = @count + 1;
    print @job_name;
end;
print @count;

end;

else
  Print ''Not Primary Node,skipping ssrs job disable''


',
@database_name=N'DBAUtilities',
@output_file_name=N'\\<<servername>>.<<domain>>\share\SQLJobsOutput-prd$\<<servername>>\AG_Role_Change_Alert_$(ESCAPE_NONE(STRTDT))_$(ESCAPE_NONE(STRTTM)).txt',

@flags=2
if (@@error <> 0 or @ReturnCode <> 0) goto QuitWithRollback
exec @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id
= 1
if (@@error <> 0 or @ReturnCode <> 0) goto QuitWithRollback
exec @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId,
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


