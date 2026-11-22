USE DBAUtilities
GO

DROP TABLE IF EXISTS dbo.Server_login_info
GO
  CREATE TABLE dbo.Server_login_info
  (
Server_login_infoID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT
PK_Server_login_info_Server_login_infoID PRIMARY KEY
CLUSTERED(Server_login_infoID),
ServerName  sysname NOT NULL,
command_name VARCHAR(255) NULL,
  command VARCHAR(MAX) NULL,
CreateDate DATETIME CONSTRAINT defCreateDate DEFAULT CURRENT_TIMESTAMP NOT
NULL
  )
GO

CREATE INDEX IDX_Server_login_info_CreateDate ON dbo.Server_login_info
(CreateDate);
GO