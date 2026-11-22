USE [master]
GO
CREATE LOGIN [<<domain>>\<<username>>] from WINDOWS WITH
DEFAULT_DATABASE=[master]
GO
grant VIEW SERVER STATE to [<<domain>>\<<username>>]
go
grant VIEW ANY DEFINITION to [<<domain>>\<<username>>]
go
GRANT EXECUTE ON master.dbo.xp_sqlagent_enum_jobs TO
[<<domain>>\<<username>>]
go
use [DBAUtilities]
go
create user [<<domain>>\<<username>>] for login [<<domain>>\<<username>>]
go
use [DBAUtilities]
go
alter role [db_datareader] add member [<<domain>>\<<username>>]
go
use [DBAUtilities]
go
alter role [db_datawriter] add member [<<domain>>\<<username>>]
go

use [DBAUtilities]
GO
CREATE ROLE [db_executor] authorization [dbo]
GO
--GRANT Execute Permission on the role
GRANT EXECUTE TO [db_executor]
go
ALTER ROLE [db_executor] ADD MEMBER [<<domain>>\<<username>>]
GO

USE [msdb]
GO
CREATE USER [<<domain>>\<<username>>] FOR LOGIN [<<domain>>\<<username>>]
GO
USE [msdb]
GO
ALTER ROLE [db_datareader] ADD MEMBER [<<domain>>\<<username>>]
GO
USE [msdb]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [<<domain>>\<<username>>]
GO
GRANT EXECUTE ON dbo.agent_datetime TO [<<domain>>\<<username>>]
GO
USE [msdb]
GO
EXEC sp_addrolemember 'SQLAgentReaderRole', [<<domain>>\<<username>>]
go
GRANT EXECUTE ON msdb.dbo.agent_datetime TO [<<domain>>\<<username>>]
go
GRANT EXECUTE ON OBJECT::dbo.agent_datetime TO [<<domain>>\<<username>>];
go

