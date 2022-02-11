use master

IF NOT EXISTS
    (SELECT 1
     from sysobjects o (NOLOCK)
     WHERE (o.[name] = 'DB_BACKUP_ALL')
       AND (OBJECTPROPERTY(o.[ID], 'IsProcedure') = 1)
    )
    BEGIN
        DECLARE @stmt nvarchar(100)
        SET @stmt = 'CREATE PROCEDURE dbo.DB_BACKUP_ALL AS '
        EXEC sp_sqlexec @stmt
    END
GO

ALTER PROCEDURE dbo.DB_BACKUP_ALL(@path nvarchar(100))
AS

DECLARE
    @db nvarchar(100) -- nazwa bazy danych


DECLARE
    l_cursor CURSOR FOR -- zaladowanie do kursora tabeli, na ktorej podstawie zostana usuniete klucze obce
        SELECT name
        FROM sys.databases; -- tabela z nazwami wszytkich baz danych na serwerze

    OPEN l_cursor
    FETCH NEXT FROM l_cursor INTO @db -- zaladowanie do zmiennych,atrybutów pierwszego wiersza


    WHILE @@FETCH_STATUS = 0
        BEGIN
            --
            -- usuwamy spacje początkowe i koncowe w zmiennych
            set @db = LTRIM(RTRIM(@db))

            --         Backup and restore operations are not allowed on database tempdb
            if @db != N'tempdb'
                BEGIN
                    EXEC master.dbo.DB_BACKUP @db = @db, @path = @path
                END

            FETCH NEXT FROM l_cursor INTO @db -- zaladowanie do zmiennych, atrybutów z kolejnego wiersza

        end

    CLOSE l_cursor
    DEALLOCATE l_cursor
Go

EXEC master.dbo.DB_BACKUP_ALL @path = N'/var/opt/mssql/backups/'

SELECT name
FROM sys.databases;

-- test
EXEC xp_dirtree '/var/opt/mssql/backups/', 1, 1 -- wyswietle

/*
|subdirectory                  |depth|file|
+------------------------------+-----+----+
|test2021_11_05T16_41_22.bak   |1    |1   |
|pwx_db2021_11_05T16_41_22.bak |1    |1   |
|TestDB2021_11_05T16_48_42.bak |1    |1   |
|msdb2021_11_05T16_41_21.bak   |1    |1   |
|TestDB2021_11_05T16_44_03.bak |1    |1   |
|master2021_11_05T16_51_01.bak |1    |1   |
|test2021_11_05T16_44_04.bak   |1    |1   |
 */
