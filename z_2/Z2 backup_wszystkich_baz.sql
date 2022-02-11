/*
Andrzej Czechowski
Moj sql serwer działa na ubuntu,
Kod sql pisze w Datagrip
 */
use master -- Procedury backup danych zapisze w db master

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

    IF @path NOT LIKE N'%/' -- nie ma / (  linux a nie windows dlatego prawy slash)
        SET @path = @path + N'/'

    SET @fname = REPLACE(REPLACE(CONVERT(nchar(19), GETDATE(), 126), N':', N'_'),'-','_')
    SET @fname = @path + RTRIM(@db)  + @fname + N'.bak' -- pelna sciazka z nazwa backupowanej bazy danej


    DECLARE @sql nvarchar(1000) -- polecenie sql

    SET @sql = 'backup database ' + @db + ' to DISK= N''' + @fname + ''''

    EXEC sp_sqlexec @sql -- wykonaniaj polecenie sql
GO



EXEC master.dbo.DB_BACKUP @db = N'pwx_db', @path = N'/var/opt/mssql/backups/' --
/*
 na linuxie
 uzytkownik mssql serve, musi mieć prawa do odczytu i pisania w podanym katalogu
 na ubuntu uzytkonik mssql serve ma domysnie dostep do katalogu /var/opt/mssql/
 */
-- test
/*
 21-11-05 16:19:30] [S0001][4035] Processed 464 pages for database 'pwx_db', file 'pwx_db' on file 1.
[2021-11-05 16:19:30] [S0001][4035] Processed 2 pages for database 'pwx_db', file 'pwx_db_log' on file 1.
[2021-11-05 16:19:30] [S0001][3014] BACKUP DATABASE successfully processed 466 pages in 0.095 seconds (38.281 MB/sec).
[2021-11-05 16:19:30] completed in 253 ms
 */

 -- Przyklad sciezki, dla ktorej  procedura sie nie wykona

 -- EXEC master.dbo.DB_BACKUP @db = N'pwx_db', @path = N'/home/andrzej/DataGripProjects/admistrowanie_baz_danych'
-- user mssql serve must have permission the path


/*
BackUp wszytkich baz danych na serwerze
 */
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

            -- Dodanie warunki if, ponieważ nie można wykonać backup danych dla bazy danej 'tempdb'
            --   Backup and restore operations are not allowed on database tempdb
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


/*
Zaplanować uruchamianie procedury backupy wszystkich baz poprzez SQL Agent na co dzien
Zdokumentowac i udowodnic, ze JOB zadzialał i pliki powstały
 */
/*
    Nie udało  mi się uruchomić SQL Agent na ubuntu,
    jedna skorzystałem z z program crontab, który słyszy do tworzenia schedule job na linuxie
*/
/*
andrzej@Zenon:~/Documents$ crontab -l

30 16 * * * /bin/bash -l  '/home/andrzej/Documents/script.sh' # wykonaj skrypt codzienie o 16:30

*/
/* Skrypt
andrzej@Zenon:~/Documents$ cat script.sh
sqlcmd -S localhost -U SA -P ****** -Q "EXEC master.dbo.DB_BACKUP_ALL @path = '/var/opt/mssql/backups/'" # zalog sie do serwa, a nastepnie wykonaj procedure backupu danych
 */
-- Sprawdzenie
/*

 */
EXEC xp_dirtree '/var/opt/mssql/backups/', 1, 1 -- wyswietle
/*
 +------------------------------+-----+----+
|subdirectory                  |depth|file|
+------------------------------+-----+----+
|test2021_11_11T16_30_02.bak   |1    |1   |
|model2021_11_11T16_30_01.bak  |1    |1   |
|msdb2021_11_11T16_30_01.bak   |1    |1   |
|TestDB2021_11_11T16_30_02.bak |1    |1   |
|master2021_11_11T16_30_01.bak |1    |1   |
|pwx_db2021_11_11T16_30_02.bak |1    |1   |
|DB_STAT2021_11_11T16_30_02.bak|1    |1   |
+------------------------------+-----+----+
 */

