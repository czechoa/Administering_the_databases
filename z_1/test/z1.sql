-- 1. Stworzyć tabelę do przechowywania WSZYSTKICH kluczy obcych w danej bazie (połączona relacją z DB_STAT
-- - dzięki relacji wiemy jaka to baza)
-- 2. Stworzyc procedure do zapamietania wszystkich luczy obcych z wykorzystaniem tabel - patrz pkt 1
USE DB_STAT
GO

IF NOT EXISTS
(	SELECT 1
		from sysobjects o (NOLOCK)
		WHERE	(o.[name] = 'DB_TC_STORE')
		AND		(OBJECTPROPERTY(o.[ID],'IsProcedure')=1)
)
BEGIN
	DECLARE @stmt nvarchar(100)
	SET @stmt = 'CREATE PROCEDURE dbo.DB_TC_STORE_FK AS '
	EXEC sp_sqlexec @stmt
END
GO

USE DB_STAT
GO

ALTER PROCEDURE dbo.DB_TC_STORE_FK (@db nvarchar(100), @commt nvarchar(20) = '<unkn>')
AS
   DECLARE
    @sql nvarchar(2000) -- tu będzie polecenie SQL wstawiajace wynik do tabeli
    ,@id int -- id nadane po wstawieniu rekordu do tabeli DB_STAT
    ,@cID nvarchar(20) -- skonwertowane @id na tekst

    SET @db = LTRIM(RTRIM(@db)) -- usuwamy spacje początkowe i koncowe z nazwy bazy
    INSERT INTO DB_STAT.dbo.DB_STAT (comment, db_nam) VALUES (@commt, @db) -- wstawienie nowego akordu do bazy stat
    SET  @id = SCOPE_IDENTITY() -- jakie ID zostało nadane wstawionemu wierszowi
    /* tekstowo ID aby ciągle nie konwetować w pętli */
    SET @cID = RTRIM(LTRIM(STR(@id,20,0))) -- konwersja na string


    SET @sql = N'USE [' + @db + N']; insert into DB_STAT.dbo.DB_FK (stat_id, constraint_name, referencing_table_name, referencing_column_name, referenced_table_name, referenced_column_name) '
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

EXEC DB_STAT.dbo.DB_TC_STORE_FK @commt = 'final test fk procedure', @db = N'pwx_db' -- Wywolanie procedury z baza @db

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


-- set @db = N'pwx_db'
--
-- SET @sql = N'USE [' + @db + N']; INSERT INTO #TC ([table]) '
--                 + N'SELECT
--                 ,f.name constraint_name
--                 ,OBJECT_NAME(f.parent_object_id) referencing_table_name
--                 ,COL_NAME(fc.parent_object_id, fc.parent_column_id) referencing_column_name
--                 ,OBJECT_NAME (f.referenced_object_id) referenced_table_name
--                 ,COL_NAME(fc.referenced_object_id, fc.referenced_column_id) referenced_column_name'
--                 + N' FROM sys.foreign_keys AS f'
--                 + N' JOIN sys.foreign_key_columns AS fc'
--                 + N' ON f.[object_id] = fc.constraint_object_id'
--                 + N' ORDER BY f.name'
--
-- EXEC sp_sqlexec @sql
--
-- DECLARE
--     @sql nvarchar(2000) -- tu będzie polecenie SQL wstawiajace wynik do tabeli
--     ,@db nvarchar(100)
--     ,@id int -- id nadane po wstawieniu rekordu do tabeli DB_STAT
--     ,@tab nvarchar(256) -- nazwa kolejne tabeli
--     ,@cID nvarchar(20) -- skonwertowane @id na tekst
--     ,@commt nvarchar(20) = '<unkn>'
--
-- set @db = N'pwx_db'
-- set @commt  = 'test FK with set'
--
-- SET @db = LTRIM(RTRIM(@db)) -- usuwamy spacje początkowe i koncowe z nazwy bazy
-- INSERT INTO DB_STAT.dbo.DB_STAT (comment, db_nam) VALUES (@commt, @db)
-- SET  @id = SCOPE_IDENTITY() -- jakie ID zostało nadane wstawionemu wierszowi
-- /* tekstowo ID aby ciągle nie konwetować w pętli */
-- SET @cID = RTRIM(LTRIM(STR(@id,20,0)))
--
-- SET @sql = N'USE [' + @db + N']; insert into DB_STAT.dbo.DB_FK (stat_id, constraint_name, referencing_table_name, referencing_column_name, referenced_table_name, referenced_column_name) '
--                 + N'SELECT '
--                 + @cID
--                 + N',f.name constraint_name
--                 ,OBJECT_NAME(f.parent_object_id) referencing_table_name
--                 ,COL_NAME(fc.parent_object_id, fc.parent_column_id) referencing_column_name
--                 ,OBJECT_NAME (f.referenced_object_id) referenced_table_name
--                 ,COL_NAME(fc.referenced_object_id, fc.referenced_column_id) referenced_column_name'
--                 + N' FROM sys.foreign_keys AS f'
--                 + N' JOIN sys.foreign_key_columns AS fc'
--                 + N' ON f.[object_id] = fc.constraint_object_id'
--                 + N' ORDER BY f.name'
--
-- EXEC sp_sqlexec @sql
--
--
--
-- use pwx_db
--
-- insert into DB_STAT.dbo.DB_FK (stat_id, constraint_name, referencing_table_name, referencing_column_name, referenced_table_name, referenced_column_name)
-- 	SELECT
--     @cID
-- 	,f.name constraint_name
-- 	,OBJECT_NAME(f.parent_object_id) referencing_table_name
-- 	,COL_NAME(fc.parent_object_id, fc.parent_column_id) referencing_column_name
-- 	,OBJECT_NAME (f.referenced_object_id) referenced_table_name
-- 	,COL_NAME(fc.referenced_object_id, fc.referenced_column_id) referenced_column_name
-- 		FROM sys.foreign_keys AS f
-- 		JOIN sys.foreign_key_columns AS fc
-- 		ON f.[object_id] = fc.constraint_object_id
-- 		ORDER BY f.name
