USE tempdb;
GO

DECLARE @tempdb_data_file int = 25000;
DECLARE @tempdb_log_file int = 10000;
DECLARE @letter varchar(3);
DECLARE @num_of_files Tinyint;
DECLARE @freespaceMB int;

SELECT @letter = DriveLetter
FROM (
    SELECT DISTINCT LEFT(physical_name, 3) AS DriveLetter
    FROM sys.master_files
    WHERE database_id = DB_ID('tempdb')
) AS DistinctDrives;

SELECT @num_of_files= count(*)
    FROM sys.master_files
    WHERE database_id = DB_ID('tempdb')
and type_desc = 'ROWS'
select @letter
select @num_of_files
-- check disk space on server

SELECT @freespaceMB =
  ((available_bytes/1048576))
FROM sys.master_files AS f CROSS APPLY
  sys.dm_os_volume_stats(f.database_id, f.file_id)
  where volume_mount_point = @letter


select  @freespaceMB
if @freespaceMB*0.5 > (@num_of_files*@tempdb_data_file)
begin
DECLARE @logicalFileName NVARCHAR(128);
DECLARE @sql NVARCHAR(MAX);

-- Declare a cursor to iterate through all tempdb files
DECLARE fileCursor CURSOR FOR
SELECT name
FROM tempdb.sys.database_files
WHERE type_desc = 'ROWS';

-- Open the cursor
OPEN fileCursor;

-- Fetch the first file name
FETCH NEXT FROM fileCursor INTO @logicalFileName;

-- Loop through all files
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Generate dynamic SQL to alter the file size
    SET @sql = concat('USE master;
    ALTER DATABASE tempdb
    MODIFY FILE (NAME = ', @logicalFileName,',', 'SIZE =
',@tempdb_data_file,'MB);');


    -- Execute the dynamic SQL
    print @sql
EXEC sp_executesql @sql;

    -- Fetch the next file name
    FETCH NEXT FROM fileCursor INTO @logicalFileName;
END

-- Close and deallocate the cursor
CLOSE fileCursor;
DEALLOCATE fileCursor;

end


SELECT @logicalFileName = name
FROM tempdb.sys.database_files
WHERE type_desc = 'LOG';

SET @sql = concat('USE master;
    ALTER DATABASE tempdb
    MODIFY FILE (NAME = ', @logicalFileName,',', 'SIZE =
',@tempdb_log_file,'MB);');

print @sql
EXEC sp_executesql @sql;