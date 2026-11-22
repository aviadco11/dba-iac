
use master
go
sp_configure 'show advanced options',1
go
reconfigure with override
go
sp_configure 'Database Mail XPs',1
--go
--sp_configure 'SQL Mail XPs',0
go
reconfigure
go

DECLARE @EmailAddress varchar(100)

SET @EmailAddress = CONCAT(@@ServerName, '@<<domain>>')

--SELECT @EmailAddress
--------------------------------------------------------------------------------------------------

-- BEGIN Mail Settings CRB EXCH
--------------------------------------------------------------------------------------------------

IF NOT EXISTS(SELECT * FROM msdb.dbo.sysmail_profile WHERE  name = 'CRB
EXCH')
  BEGIN
    --CREATE Profile [CRB EXCH]
    EXECUTE msdb.dbo.sysmail_add_profile_sp
      @profile_name = 'CRB EXCH',
      @description  = '';
  END --IF EXISTS profile

  IF NOT EXISTS(SELECT * FROM msdb.dbo.sysmail_account WHERE  name = 'CRB
CLOUD SMTP')
  BEGIN
    --CREATE Account [CRB CLOUD SMTP]
    EXECUTE msdb.dbo.sysmail_add_account_sp
    @account_name            = 'CRB CLOUD SMTP',
    @email_address           = @EmailAddress,
    @display_name            = @@ServerName,
    @replyto_address         = '<<email>>',
    @description             = '',
    @mailserver_name         = '<<mail_server>>',
    @mailserver_type         = 'SMTP',
    @port                    = '25',
    @username                =  NULL ,
    @password                =  NULL ,
    @use_default_credentials =  0 ,
    @enable_ssl              =  0 ;
  END --IF EXISTS  account

IF NOT EXISTS(SELECT *
              FROM msdb.dbo.sysmail_profileaccount pa
                INNER JOIN msdb.dbo.sysmail_profile p ON pa.profile_id =
p.profile_id
                INNER JOIN msdb.dbo.sysmail_account a ON pa.account_id =
a.account_id
              WHERE p.name = 'CRB EXCH'
                AND a.name = 'CRB CLOUD SMTP')
  BEGIN
    -- Associate Account [CRB CLOUD SMTP] to Profile [CRB EXCH]
    EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
      @profile_name = 'CRB EXCH',
      @account_name = 'CRB CLOUD SMTP',
      @sequence_number = 1 ;
  END
--IF EXISTS associate accounts to profiles
---------------------------------------------------------------------------------------------------

-- Drop Settings For CRB EXCH
--------------------------------------------------------------------------------------------------

/*
IF EXISTS(SELECT *
            FROM msdb.dbo.sysmail_profileaccount pa
              INNER JOIN msdb.dbo.sysmail_profile p ON pa.profile_id =
p.profile_id
              INNER JOIN msdb.dbo.sysmail_account a ON pa.account_id =
a.account_id
            WHERE p.name = 'CRB EXCH'
              AND a.name = 'CRB CLOUD SMTP')
  BEGIN
    EXECUTE msdb.dbo.sysmail_delete_profileaccount_sp @profile_name = 'CRB
EXCH',@account_name = 'CRB CLOUD SMTP'
  END
IF EXISTS(SELECT * FROM msdb.dbo.sysmail_account WHERE  name = 'CRB CLOUD
SMTP')
  BEGIN
    EXECUTE msdb.dbo.sysmail_delete_account_sp @account_name = 'CRB CLOUD
SMTP'
  END
IF EXISTS(SELECT * FROM msdb.dbo.sysmail_profile WHERE  name = 'CRB EXCH')
  BEGIN
    EXECUTE msdb.dbo.sysmail_delete_profile_sp @profile_name = 'CRB EXCH'
  END
*/

IF NOT EXISTS (
    SELECT 1
    FROM msdb.dbo.sysmail_profile
    WHERE name = 'MyGlobalProfile'
)
BEGIN
    EXEC msdb.dbo.sysmail_add_profile_sp
        @profile_name = 'CRB EXCH',
        @description = 'Global default mail profile';

    PRINT 'Profile created successfully.'
END
ELSE
BEGIN
    PRINT 'Profile already exists. Skipping creation.'
END