-- Andrzej Czechowski nr.307335 cw.1
-- Cwiczenie wykonałem przyuzyciu narzedzia datagrip jetbrains

-- cw 1. Stworzyć tabelę do przechowywania WSZYSTKICH kluczy obcych w danej bazie (połączona relacją z DB_STAT
-- - dzięki relacji wiemy jaka to baza)
USE DB_STAT
GO

IF NOT EXISTS
    (SELECT 1
     from sysobjects o (NOLOCK)
     WHERE (o.[name] = N'DB_FK')
       AND (OBJECTPROPERTY(o.[ID], N'IsUserTable') = 1)
    )
    BEGIN
        CREATE TABLE dbo.DB_FK
        (
            stat_id                 int           NOT NULL
                CONSTRAINT FK_DB_STAT__FK FOREIGN KEY
                    REFERENCES dbo.DB_STAT (stat_id),
            constraint_name         nvarchar(100) NOT NULL,
            referencing_table_name  nvarchar(100) NOT NULL                   -- Z jakiej tabeli klucz obcy
            ,
            referencing_column_name nvarchar(100) NOT NULL                   --  z jakiej kolumny
            ,
            referenced_table_name   nvarchar(100) NOT NULL                   -- do jakiej tabeli klucz obcy
            ,
            referenced_column_name  nvarchar(100) NOT NULL                   -- nazwa kolumny w tabeli do ktorej sie odwojujemy
            ,
            [RDT]                   datetime      NOT NULL DEFAULT GETDATE() -- stepel czasowy
        )

    END
GO


-- 2. Stworzyc procedure do zapamietania wszystkich kluczy obcych z wykorzystaniem tabel - patrz pkt 1


USE DB_STAT
GO

IF NOT EXISTS
    (SELECT 1
     from sysobjects o (NOLOCK)
     WHERE (o.[name] = 'DB_TC_STORE')
       AND (OBJECTPROPERTY(o.[ID], 'IsProcedure') = 1)
    )
    BEGIN
        DECLARE
            @stmt nvarchar(100)
        SET @stmt = 'CREATE PROCEDURE dbo.DB_TC_STORE_FK AS '
        EXEC sp_sqlexec @stmt
    END
GO

USE DB_STAT
GO

ALTER PROCEDURE dbo.DB_TC_STORE_FK(@db nvarchar(100), @commt nvarchar(20) = '<unkn>')
AS
DECLARE
    @sql   nvarchar(2000) -- tu będzie polecenie SQL wstawiajace wynik do tabeli
    , @id  int -- id nadane po wstawieniu rekordu do tabeli DB_STAT
    , @cID nvarchar(20) -- skonwertowane @id na tekst

    SET @db = LTRIM(RTRIM(@db)) -- usuwamy spacje początkowe i koncowe z nazwy bazy
INSERT INTO DB_STAT.dbo.DB_STAT (comment, db_nam)
VALUES (@commt, @db) -- wstawienie nowego akordu do bazy stat
    SET @id = SCOPE_IDENTITY() -- jakie ID zostało nadane wstawionemu wierszowi
/* tekstowo ID aby ciągle nie konwetować w pętli */
    SET @cID = RTRIM(LTRIM(STR(@id, 20, 0))) -- konwersja na string


    SET @sql = N'USE [' + @db +
               N']; insert into DB_STAT.dbo.DB_FK (stat_id, constraint_name, referencing_table_name, referencing_column_name, referenced_table_name, referenced_column_name) '
        + N'SELECT '
        + @cID
        + N',f.name constraint_name
                    ,OBJECT_NAME(f.parent_object_id) referencing_table_name
                    ,COL_NAME(fc.parent_object_id, fc.parent_column_id) referencing_column_name
                    ,OBJECT_NAME (f.referenced_object_id) referenced_table_name
                    ,COL_NAME(fc.referenced_object_id, fc.referenced_column_id) referenced_column_name'
        + N' FROM sys.foreign_keys AS f'
        + N' JOIN sys.foreign_key_columns AS fc'
        + N' ON f.[object_id] = fc.constraint_object_id'
        + N' ORDER BY f.name'

    EXEC sp_sqlexec @sql
go
-- Wywolanie procedury z baza @db
EXEC DB_STAT.dbo.DB_TC_STORE_FK @commt = 'final test fk procedure', @db = N'pwx_db'


use DB_STAT
GO

-- Sprawdzenie
select ds.stat_id,
       db_nam,
       constraint_name,
       referencing_table_name,
       referencing_column_name,
       referenced_table_name,
       referenced_column_name,
       RDT
from DB_STAT ds
         join DB_FK DF on ds.stat_id = DF.stat_id
where ds.comment = 'final test fk proced';
/*
 +-------+------+-----------------------------+----------------------+-----------------------+---------------------+----------------------+-----------------------+
|stat_id|db_nam|constraint_name              |referencing_table_name|referencing_column_name|referenced_table_name|referenced_column_name|RDT                    |
+-------+------+-----------------------------+----------------------+-----------------------+---------------------+----------------------+-----------------------+
|21     |pwx_db|fk_miasta__woj               |miasta                |kod_woj                |woj                  |kod_woj               |2021-10-06 12:45:47.740|
|21     |pwx_db|fk_osoby__miasta             |osoby                 |id_miasta              |miasta               |id_miasta             |2021-10-06 12:45:47.740|
|21     |pwx_db|fk_firmy__miasta             |firmy                 |id_miasta              |miasta               |id_miasta             |2021-10-06 12:45:47.740|
|21     |pwx_db|fk_etaty__osoby              |etaty                 |id_osoby               |osoby                |id_osoby              |2021-10-06 12:45:47.740|
|21     |pwx_db|fk_etaty__firmy              |etaty                 |id_firmy               |firmy                |nazwa_skr             |2021-10-06 12:45:47.740|
|21     |pwx_db|FK_WARTOSCI_CECHY__CECHY     |WARTOSCI_CECH         |id_CECHY               |CECHY                |id_CECHY              |2021-10-06 12:45:47.740|
|21     |pwx_db|FK_FIRMY_CECHY__WARTOSCI_CECH|FIRMY_CECHY           |id_wartosci            |WARTOSCI_CECH        |id_wartosci           |2021-10-06 12:45:47.740|
+-------+------+-----------------------------+----------------------+-----------------------+---------------------+----------------------+-----------------------+
 */

-- 3. Procedura do kasowania kluczy obcych - najpierw uruchamia procedure z punktu 2 a następnie kasuje klucze
use DB_STAT

IF NOT EXISTS
    (SELECT 1
     from sysobjects o (NOLOCK)
     WHERE (o.[name] = 'DB_TC_REMOVE_FK')
       AND (OBJECTPROPERTY(o.[ID], 'IsProcedure') = 1)
    )
    BEGIN
        DECLARE @stmt nvarchar(100)
        SET @stmt = 'CREATE PROCEDURE dbo.DB_TC_REMOVE_FK AS '
        EXEC sp_sqlexec @stmt
    END
GO


ALTER PROCEDURE dbo.DB_TC_REMOVE_FK(@db nvarchar(100))
AS

    SET @db = LTRIM(RTRIM(@db)) -- usuwamy spacje początkowe i koncowe z nazwy bazy

    EXEC DB_STAT.dbo.DB_TC_STORE_FK @commt = 'before remove fk', @db = N'pwx_db' -- Wywolanie procedury zapamietujacej klucze obce

DECLARE
    @sql                    nvarchar(2000),
    @constraint_name        nvarchar(100), -- atrybuty potrzebne do usuniecia kluczy
    @referencing_table_name nvarchar(100)

DECLARE
    l_cursor CURSOR FOR -- zaladowanie do kursora tabeli, na ktorej podstawie zostana usuniete klucze obce
        SELECT constraint_name,
               referencing_table_name
        from DB_STAT.DBO.DB_FK DF -- pelne nazwy tabeli,  aby nie uzywać use
                 join DB_STAT.DBO.DB_STAT DS on DS.stat_id = DF.stat_id -- klucze obce ostatnio zapisane
        where DF.stat_id =
              (select MAX(DS2.stat_id) -- MAX Z DB_STAT, a nie DB_STAT_FK (jakby wczesniej było usuniete klucze obce)
               FROM DB_STAT.DBO.DB_STAT DS2
               WHERE EXISTS(SELECT 1 FROM DB_STAT.DBO.DB_FK))
    OPEN l_cursor
    FETCH NEXT FROM l_cursor INTO @constraint_name, @referencing_table_name -- zaladowanie do zmiennych,atrybutów pierwszego wiersza


    WHILE @@FETCH_STATUS = 0
        BEGIN
            -- usuwamy spacje początkowe i koncowe w zmiennych
            set @referencing_table_name = LTRIM(RTRIM(@referencing_table_name))
            set @constraint_name = LTRIM(RTRIM(@constraint_name))

            --zmienna do usuniecie kluczy obcych z tabeli
            set @sql = N'USE [' + @db + N']; alter table ' + @referencing_table_name + N' drop constraint ' +
                       @constraint_name

            --wykonanie  usuniecie kluczy obcych z tabeli
            EXEC sp_sqlexec @sql

            FETCH NEXT FROM l_cursor INTO @constraint_name, @referencing_table_name -- zaladowanie do zmiennych, atrybutów z kolejnego wiersza
        end
    CLOSE l_cursor
    DEALLOCATE l_cursor
go

EXEC DB_STAT.dbo.DB_TC_REMOVE_FK @db = N'pwx_db'

-- Sprawdzenie
use pwx_db
go

SELECT f.name                                                     constraint_name
     , OBJECT_NAME(f.parent_object_id)                            referencing_table_name
     , COL_NAME(fc.parent_object_id, fc.parent_column_id)         referencing_column_name
     , OBJECT_NAME(f.referenced_object_id)                        referenced_table_name
     , COL_NAME(fc.referenced_object_id, fc.referenced_column_id) referenced_column_name
FROM sys.foreign_keys AS f
         JOIN sys.foreign_key_columns AS fc
              ON f.[object_id] = fc.constraint_object_id
ORDER BY f.name

-- +---------------+----------------------+-----------------------+---------------------+----------------------+
-- |constraint_name|referencing_table_name|referencing_column_name|referenced_table_name|referenced_column_name|
-- +---------------+----------------------+-----------------------+---------------------+----------------------+

-- 4. Napisanie procedury do odtworzenia kluczy obcych ostatnio zapisanych

use DB_STAT
go

IF NOT EXISTS
    (SELECT 1
     from sysobjects o (NOLOCK)
     WHERE (o.[name] = 'DB_TC_RECREATE_FK')
       AND (OBJECTPROPERTY(o.[ID], 'IsProcedure') = 1)
    )
    BEGIN
        DECLARE @stmt nvarchar(100)
        SET @stmt = 'CREATE PROCEDURE dbo.DB_TC_RECREATE_FK AS '
        EXEC sp_sqlexec @stmt
    END
GO


ALTER PROCEDURE dbo.DB_TC_RECREATE_FK
AS

    -- decklaracja zmiennych
DECLARE
    @sql                     nvarchar(2000),
    @db                      nvarchar(100), -- nazwa bazy danych
    @constraint_name         nvarchar(100), -- atrybuty tabeli DB_TC_STORE_FK potrzebne do odtworzenia kluczy
    @referencing_table_name  nvarchar(100),
    @referencing_column_name nvarchar(100),
    @referenced_table_name   nvarchar(100),
    @referenced_column_name  nvarchar(100)

DECLARE
    l_cursor CURSOR FOR -- zaladowanie kursora do tabelki
        select db_nam, -- baza danych, ktorej zostana ponownie stworzone klucze obce
               constraint_name,
               referencing_table_name,
               referencing_column_name,
               referenced_table_name,
               referenced_column_name
        from DB_STAT.DBO.DB_FK DF -- Pelne nazwy
                 join DB_STAT.DBO.DB_STAT DS on DS.stat_id = DF.stat_id -- kluczy obcych ostatnio zapisanych
        where DF.stat_id = (select MAX(DS2.stat_id) -- MAX Z DB_fk A NIE Z DB_STAT
                            FROM DB_STAT.DBO.DB_FK DS2
                            WHERE EXISTS(SELECT 1 FROM DB_STAT.DBO.DB_FK))

    OPEN l_cursor
    FETCH NEXT FROM l_cursor INTO @db ,@constraint_name, @referencing_table_name, @referencing_column_name, @referenced_table_name, @referenced_column_name
    WHILE @@FETCH_STATUS = 0
        BEGIN
            set @referencing_table_name = LTRIM(RTRIM(@referencing_table_name))
            set @constraint_name = LTRIM(RTRIM(@constraint_name))
            set @referencing_column_name = LTRIM(RTRIM(@referencing_column_name))
            set @referenced_table_name = LTRIM(RTRIM(@referenced_table_name))
            set @referenced_column_name = LTRIM(RTRIM(@referenced_column_name))
            SET @db = LTRIM(RTRIM(@db))

            -- Polecenie do otworzenia kluczy obcych
            set @sql = N'USE [' + @db + N']; alter table ' + @referencing_table_name +
                       N' add constraint ' + @constraint_name +
                       N' foreign key (' + @referencing_column_name + N') REFERENCES ' + @referenced_table_name + N'(' +
                       @referenced_column_name + N')'
            -- wykonanie polecenia
            EXEC sp_sqlexec @sql

            FETCH NEXT FROM l_cursor INTO @db, @constraint_name, @referencing_table_name, @referencing_column_name, @referenced_table_name, @referenced_column_name

        end
    CLOSE l_cursor
    DEALLOCATE l_cursor
go



EXEC DB_STAT.dbo.DB_TC_RECREATE_FK

-- Sprawdzenie
use pwx_db

SELECT f.name                                                     constraint_name
     , OBJECT_NAME(f.parent_object_id)                            referencing_table_name
     , COL_NAME(fc.parent_object_id, fc.parent_column_id)         referencing_column_name
     , OBJECT_NAME(f.referenced_object_id)                        referenced_table_name
     , COL_NAME(fc.referenced_object_id, fc.referenced_column_id) referenced_column_name
FROM sys.foreign_keys AS f
         JOIN sys.foreign_key_columns AS fc
              ON f.[object_id] = fc.constraint_object_id
ORDER BY f.name

-- +-----------------------------+----------------------+-----------------------+---------------------+----------------------+
-- |constraint_name              |referencing_table_name|referencing_column_name|referenced_table_name|referenced_column_name|
-- +-----------------------------+----------------------+-----------------------+---------------------+----------------------+
-- |fk_etaty__firmy              |etaty                 |id_firmy               |firmy                |nazwa_skr             |
-- |fk_etaty__osoby              |etaty                 |id_osoby               |osoby                |id_osoby              |
-- |fk_firmy__miasta             |firmy                 |id_miasta              |miasta               |id_miasta             |
-- |FK_FIRMY_CECHY__WARTOSCI_CECH|FIRMY_CECHY           |id_wartosci            |WARTOSCI_CECH        |id_wartosci           |
-- |fk_miasta__woj               |miasta                |kod_woj                |woj                  |kod_woj               |
-- |fk_osoby__miasta             |osoby                 |id_miasta              |miasta               |id_miasta             |
-- |FK_WARTOSCI_CECHY__CECHY     |WARTOSCI_CECH         |id_CECHY               |CECHY                |id_CECHY              |
-- +-----------------------------+----------------------+-----------------------+---------------------+----------------------+


