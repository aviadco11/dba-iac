
USE [master]
GO
if not exists( select * from sys.server_principals where
name='<<domain>>\<<username>>')
begin
CREATE LOGIN [<<domain>>\<<username>>] FROM WINDOWS WITH
DEFAULT_DATABASE=[master]
end
GO
grant VIEW SERVER STATE to [<<domain>>\<<username>>]
go
grant VIEW ANY DEFINITION to [<<domain>>\<<username>>]
go
USE [msdb]
GO
if not exists( select * from sys.database_principals where
name='<<domain>>\<<username>>')
begin
CREATE USER [<<domain>>\<<username>>] FOR LOGIN [<<domain>>\<<username>>]
end
--doesn't work on rds
--ALTER ROLE [ServerGroupReaderRole] ADD MEMBER [<<domain>>\<<username>>]
GO
ALTER ROLE [db_datareader] ADD MEMBER [<<domain>>\<<username>>]
GO
ALTER ROLE [db_backupoperator] ADD MEMBER [<<domain>>\<<username>>]
GO

USE [DBAUtilities]
GO
if not exists( select * from sys.database_principals where
name='<<domain>>\<<username>>')
begin
CREATE USER [<<domain>>\<<username>>] FOR LOGIN [<<domain>>\<<username>>]
end
ALTER ROLE [db_executor] ADD MEMBER [<<domain>>\<<username>>]
GO
ALTER ROLE [db_datareader] ADD MEMBER [<<domain>>\<<username>>]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [<<domain>>\<<username>>]
GO