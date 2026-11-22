declare @login_name1 varchar(30), @login_name2 varchar(30)
select @login_name1 = SUBSTRING(@@SERVERNAME,
CHARINDEX('stg',@@SERVERNAME),LEN(@@SERVERNAME)-CHARINDEX('stg',@@SERVERNAME)+1)


insert into [DBAUtilities].[Monitoring].[OmittedLogins] values
('<<domain>>\<<username>>'+UPPER(@login_name1))

select @login_name2 = SUBSTRING(@login_name1, 1,
CHARINDEX('-',@login_name1)-1)
insert into [DBAUtilities].[Monitoring].[OmittedLogins] values
('<<domain>>\<<username>>'+UPPER(@login_name2))
