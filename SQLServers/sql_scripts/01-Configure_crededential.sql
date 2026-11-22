
-- Dynamically set the value of the environment

Declare @Value varchar(13)= case
    when @@servername like '%prd%' then 'prod'
when @@servername like '%stg%' then 'stg'
when @@servername like '%sbx%' then 'sbx'
when @@servername like '%dev%' then 'dev'
when @@servername like '%uat%' then 'uat'
when @@servername like '%lt%' then 'uat'
when @@servername like '%qa%' then 'qa'
when @@servername ='<<servername>>' then 'dev'
else @@servername end

Delete  from dbautilities.[dbo].[UtilitiesConfig] where configtag =
'env_abbr';

Insert into dbautilities.[dbo].[UtilitiesConfig]
([configTag],[ConfigValue])
Select 'env_abbr',@Value ;

USE [master]

Declare @credstring nvarchar(1000)

Select @credstring =  concat('CREATE CREDENTIAL [','s3://<<s3_bucket>>/',
ConfigValue ,'] WITH IDENTITY = N''S3 Access Key'', SECRET =
N''<<aws_access_key>>:<<aws_secret_key>>''')
 from  dbautilities.dbo.Utilitiesconfig where configtag = 'Env_abbr'

EXEC sp_executesql @statement = @credstring
Go

USE DBAUtilities
GO

declare @MyURL varchar(1000)
Select @MyURL = concat('s3://<<s3_bucket>>/', ConfigValue )  from
 dbautilities.dbo.Utilitiesconfig where configtag = 'Env_abbr'

declare @MyMirror varchar (1000)
Select @MyMirror = concat('s3://<<s3_bucket>>/', ConfigValue )  from
 dbautilities.dbo.Utilitiesconfig where configtag = 'Env_abbr'


MERGE INTO dbo.UtilitiesConfig T
USING (
VALUES
( 'S3-URL'        ,@MyURL),
( 'S3-MIRROR'        ,@MyMirror),
( 'S3-Credential' ,@MyURL) )
AS S (ConfigTag, ConfigValue)
ON  (T.configTag = S.ConfigTag )
WHEN MATCHED THEN UPDATE
SET T.ConfigValue = S.ConfigValue
WHEN NOT MATCHED BY TARGET THEN INSERT
(ConfigTag, ConfigValue)
VALUES
(s.ConfigTag, s.ConfigValue);

DECLARE @vCredential varchar(512)
             , @vURL varchar(75)
             ,@vMirrorUrl varchar(75)
             ,@vEnvironment VARCHAR(20)

select @vCredential =ConfigValue from UtilitiesConfig where
ConfigTag='S3-Credential'
select @vURL = ConfigValue from UtilitiesConfig where ConfigTag='S3-URL'
select @vMirrorUrl = ConfigValue from UtilitiesConfig where
ConfigTag='S3-MIRROR'
select @vEnvironment = ConfigValue from UtilitiesConfig where ConfigTag =
'env_abbr'

EXEC usp_backupdatabasetos3  @pIsSystem = 1
                   ,@pType = 'FULL'
,@pCredential = @vCredential
,@pURL = @vURL
,@pMirrorUrl =   @vMirrorUrl
,@pMirrorOverride = 0
,@pEnvironment = @vEnvironment
,@pNumberofFiles = 4
,@pWhatif = 0





