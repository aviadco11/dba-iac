USE [msdb]
GO

EXEC msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=-1,
@jobhistory_max_rows_per_job=-1
GO

EXEC dbo.sp_get_sqlagent_properties;
GO