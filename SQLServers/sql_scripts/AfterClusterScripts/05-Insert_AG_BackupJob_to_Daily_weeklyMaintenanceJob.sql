--THIS GETS RUN IN SQLCMD MODE  NEED TO SUB SQLJob with the BACKUP JOB you want added to either DAILY OR WEEKLY MAINTENANCE JOB
--ALSO NEED TO SUB NAME in FOR JobNameInjection of either the name of the Daily Backup Job or the Weekly Job Name. 
--This will add this as a step right after the last backup step in the job
:setvar SQLJob "(SysDBA) DatabaseBackup - AG-CP-LT_DATABASES - FULL"
DECLARE @NewJobName sysname = '$(SQLJob)'
       ,@JobName sysname
       ,@Step_id INT
	   ,@NewStep_id INT
	   ,@Step_name sysname
	   ,@JobNameInjection sysname = '(SysDBA) Daily_DB_Maintenance_Jobs'

SELECT @NewJobName

USE msdb;

WITH Jobsteps AS
(
	SELECT 
		j.name AS [JobName],
		s.step_id,
		s.step_name,
		s.command,
		-- On Success
		s.on_success_action AS [On Success Action],
		CASE s.on_success_action
			WHEN 1 THEN 'Quit with Success'
			WHEN 2 THEN 'Quit with Failure'
			WHEN 3 THEN 'Go to Next Step'
			WHEN 4 THEN 'Go to Step'
			ELSE 'Unknown'
		END AS [On Success Action Description],
		s.on_success_step_id AS [On Success Step ID],
		-- On Failure
		s.on_fail_action AS [On Failure Action],
		CASE s.on_fail_action
			WHEN 1 THEN 'Quit with Success'
			WHEN 2 THEN 'Quit with Failure'
			WHEN 3 THEN 'Go to Next Step'
			WHEN 4 THEN 'Go to Step'
			ELSE 'Unknown'
		END AS [On Failure Action Description],
		s.on_fail_step_id AS [On Failure Step ID]
	FROM msdb.dbo.sysjobs j
	INNER JOIN msdb.dbo.sysjobsteps s
		ON j.job_id = s.job_id
		where j.name = @JobNameInjection
		--and s.on_fail_action=2
		--and s.step_name not like '%end%'
		--and s.step_name not in ('no op', 'success')
)

SELECT @Step_id  = MAX(Jobsteps.step_id) 
      ,@JobName = JobName 
	  ,@NewStep_id = @Step_id + 1
FROM Jobsteps
WHERE Step_Name LIKE '(SysDBA) DatabaseBackup -%'
GROUP BY JobName
ORDER BY jobname 

SELECT @JobName
      ,@Step_id
	  ,@NewStep_id

	  

EXEC sp_add_jobstep
    @job_name = @JobName,
	@step_id = @NewStep_id,
    @step_name = @NewJobName,
    @subsystem = N'TSQL',                     -- Type of job step
    @command = N'EXEC StartJobWithWait @par_JobName= $(SQLJob), @par_waitInterval=''00:00:30''',   
    @database_name = N'DBAUtilities',               -- Database context
    @on_success_action = 3,                   
    @on_fail_action = 3;                      
GO