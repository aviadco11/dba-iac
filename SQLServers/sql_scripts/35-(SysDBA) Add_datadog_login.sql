/* Login [svcdatadogDev] */
IF NOT EXISTS (
    SELECT 1
    FROM sys.server_principals
    WHERE [name] = N'svcdatadogDev'
    )
BEGIN
CREATE LOGIN [svcdatadogDev]
    WITH PASSWORD = <<password_hash>> HASHED
        ,SID = <<sid>>
        ,DEFAULT_DATABASE = [master]
        ,DEFAULT_LANGUAGE = [us_english]
        ,CHECK_POLICY = ON
        ,CHECK_EXPIRATION = OFF
END