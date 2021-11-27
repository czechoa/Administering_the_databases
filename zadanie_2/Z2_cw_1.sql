use master

IF NOT EXISTS
    (SELECT 1
     from sysobjects o (NOLOCK)
     WHERE (o.[name] = 'DB_BACKUP')
       AND (OBJECTPROPERTY(o.[ID], 'IsProcedure') = 1)
    )
    BEGIN
        DECLARE @stmt nvarchar(100)
        SET @stmt = 'CREATE PROCEDURE dbo.DB_BACKUP AS '
        EXEC sp_sqlexec @stmt
    END
GO

ALTER PROCEDURE dbo.DB_BACKUP(@db nvarchar(100),@path nvarchar(100))
AS

    declare @fname nvarchar(1000)
    SET @path = LTRIM(RTRIM(@path)) -- pomijamy spacje z obu stron

    IF @path NOT LIKE N'%/' -- nie ma / ( linux a nie windows)  na końcu
        SET @path = @path + N'/'

    SET @fname = REPLACE(REPLACE(CONVERT(nchar(19), GETDATE(), 126), N':', N'_'),'-','_')
    SET @fname = @path + RTRIM(@db)  + @fname + N'.bak'


    DECLARE @sql nvarchar(1000)

    SET @sql = 'backup database ' + @db + ' to DISK= N''' + @fname + ''''

    EXEC sp_sqlexec @sql
GO

-- EXEC master.dbo.DB_BACKUP @db = N'pwx_db', @path = N'/home/andrzej/DataGripProjects/admistrowanie_baz_danych'
-- user mssql serve must have permission the path
EXEC master.dbo.DB_BACKUP @db = N'pwx_db', @path = N'/var/opt/mssql/backups/'

-- test
/*
 21-11-05 16:19:30] [S0001][4035] Processed 464 pages for database 'pwx_db', file 'pwx_db' on file 1.
[2021-11-05 16:19:30] [S0001][4035] Processed 2 pages for database 'pwx_db', file 'pwx_db_log' on file 1.
[2021-11-05 16:19:30] [S0001][3014] BACKUP DATABASE successfully processed 466 pages in 0.095 seconds (38.281 MB/sec).
[2021-11-05 16:19:30] completed in 253 ms
 */