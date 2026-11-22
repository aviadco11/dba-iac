use [msdb]
go

declare @J_ID varchar (150)
select @J_ID =  job_id from msdb.dbo.sysjobs where [name] = '[SYSDBA] AG
Role Change Alert'
--select @J_ID

/****** Object:  Alert [AG Role Change Alert]    Script Date: 5/3/2022
2:23:55 PM ******/
exec msdb.dbo.sp_add_alert @name=N'AG Role Change Alert',
@message_id=35202,
@severity=0,
@enabled=1,
@delay_between_responses=300,
@include_event_description_in=0,
@category_name=N'[Uncategorized]',
@job_id=@J_ID  -- (!!!!Need to obtaine SQL agent jobid from above
variable!!!)
go




