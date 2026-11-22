IF NOT EXISTS (
    SELECT 1 FROM msdb.dbo.sysjobs
    WHERE name = N'(SysDBA) Check SQL and SQL Agent Errorlogs - Noon & 5PM'
)
BEGIN
    BEGIN TRANSACTION;
    DECLARE @ReturnCode INT = 0;
    DECLARE @jobId BINARY(16);

    IF NOT EXISTS (SELECT 1 FROM msdb.dbo.syscategories WHERE name =
N'Database Maintenance' AND category_class = 1)
    BEGIN
        EXEC @ReturnCode = msdb.dbo.sp_add_category @class = N'JOB', @type
= N'LOCAL', @name = N'Database Maintenance';
        IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;
    END;

    EXEC @ReturnCode = msdb.dbo.sp_add_job
        @job_name        = N'(SysDBA) Check SQL and SQL Agent Errorlogs -
Noon & 5PM',
        @enabled         = 1,
        @notify_level_eventlog = 3,
        @notify_level_email    = 0,
        @notify_level_netsend  = 0,
        @notify_level_page     = 0,
        @delete_level    = 0,
        @description     = N'Checks SQL Server and SQL Agent error logs at
noon and 5 PM daily.',
        @category_name   = N'Database Maintenance',
        @owner_login_name = N'<<username>>',
        @job_id          = @jobId OUTPUT;
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep
        @job_id              = @jobId,
        @step_name           = N'Get errors from SQL and SQL Agent
errorlogs',
        @step_id             = 1,
        @cmdexec_success_code = 0,
        @on_success_action   = 1,
        @on_fail_action      = 2,
        @retry_attempts      = 0,
        @retry_interval      = 0,
        @os_run_priority     = 0,
        @subsystem           = N'TSQL',
        @command             = N'EXEC
DBAUtilities.dbo.SQL_and_SqlAgent_errorlog_alert
    @pEmailTo = ''<<email>>;<<email>>'',
    @pDeltaHH = 5,
    @pOutput  = ''E'';',
        @database_name       = N'DBAUtilities',
        @output_file_name    = N'',
        @flags               = 2;
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

    EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId,
@start_step_id = 1;
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

    EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule
        @job_id          = @jobId,
        @name            = N'Daily Noon Check',
        @enabled         = 1,
        @freq_type       = 4,
        @freq_interval   = 1,
        @freq_subday_type = 1,
        @freq_subday_interval = 0,
        @freq_relative_interval = 0,
        @freq_recurrence_factor = 0,
        @active_start_date  = 20180629,
        @active_end_date    = 99991231,
        @active_start_time  = 120000,
        @active_end_time    = 235959;
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

    EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule
        @job_id          = @jobId,
        @name            = N'Daily 5PM Check',
        @enabled         = 1,
        @freq_type       = 4,
        @freq_interval   = 1,
        @freq_subday_type = 1,
        @freq_subday_interval = 0,
        @freq_relative_interval = 0,
        @freq_recurrence_factor = 0,
        @active_start_date  = 20180629,
        @active_end_date    = 99991231,
        @active_start_time  = 170000,
        @active_end_time    = 235959;
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

    EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId,
@server_name = N'(local)';
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

    COMMIT TRANSACTION;
    PRINT 'Job created successfully on ' + @@SERVERNAME;
    GOTO EndSave;

    QuitWithRollback:
        IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION;
        PRINT 'Job creation FAILED on ' + @@SERVERNAME;
    EndSave:
END
ELSE
    PRINT 'Job already exists on ' + @@SERVERNAME + ' — skipped.';
GO
