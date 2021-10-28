-- use pwx_db
-- CREATE TABLE [dbo].WARTOSCI_CECH_TEST_DROP_KEY
-- (	id_wartosci	int		NOT NULL	IDENTITY
-- 	CONSTRAINT PK_WARTOSCI_CECH_TEST_DROP_KEY  PRIMARY KEY
-- ,	id_CECHY	int 		NOT NULL
-- 	CONSTRAINT FK_WARTOSCI_CECHY__CECHY_TEST_DROP_KEY FOREIGN KEY
-- 	REFERENCES CECHY(ID_CECHY)
-- ,	Opis_wartosci	varchar(40)	NOT NULL
-- )
--
--
--
-- alter table WARTOSCI_CECH_TEST_DROP_KEY  drop constraint FK_WARTOSCI_CECHY__CECHY_TEST_DROP_KEY
--
--
-- -- alter table WARTOSCI_CECH_TEST_DROP_KEY  add constraint FK_WARTOSCI_CECHY__CECHY_TEST_DROP_KEY foreign key(id_CECHY)
--
-- ALTER TABLE WARTOSCI_CECH_TEST_DROP_KEY
--    ADD CONSTRAINT FK_WARTOSCI_CECHY__CECHY_TEST_DROP_KEY FOREIGN KEY (id_CECHY)
--       REFERENCES CECHY(ID_CECHY)
--
-- drop table WARTOSCI_CECH_TEST_DROP_KEY


use DB_STAT

IF NOT EXISTS
(	SELECT 1
		from sysobjects o (NOLOCK)
		WHERE	(o.[name] = 'DB_TC_REMOVE_FK')
		AND		(OBJECTPROPERTY(o.[ID],'IsProcedure')=1)
)
BEGIN
	DECLARE @stmt nvarchar(100)
	SET @stmt = 'CREATE PROCEDURE dbo.DB_TC_REMOVE_FK AS '
	EXEC sp_sqlexec @stmt
END
GO

USE DB_STAT
GO

ALTER PROCEDURE dbo.DB_TC_REMOVE_FK(@db nvarchar(100))
AS

    SET @db = LTRIM(RTRIM(@db)) -- usuwamy spacje początkowe i koncowe z nazwy bazy

    EXEC DB_STAT.dbo.DB_TC_STORE_FK @commt = 'procedure remove fk', @db = N'pwx_db' -- Wywolanie procedury z baza @db

    DECLARE @sql nvarchar(2000),
            @constraint_name nvarchar(100), -- atrybuty potrzebne do usuniecia kluczy
            @referencing_table_name nvarchar(100)

    DECLARE l_cursor CURSOR FOR  -- zaladowanie do kursora tabeli, na ktorej podstawie zostana usuniete klucze opcje
        SELECT
               constraint_name,
               referencing_table_name
        from DB_STAT.DBO.DB_FK DF -- pelne nazwy tabeli,  aby nie uzywać use
        join DB_STAT.DBO.DB_STAT DS on DS.stat_id = DF.stat_id -- kluczy obcych ostatnio zapisanych
        where DF.stat_id  = (select  MAX(DS2.stat_id)  -- MAX Z DB_fk A NIE Z DB_STAT
            FROM DB_STAT.DBO.DB_FK DS2
            WHERE EXISTS (SELECT 1 FROM DB_STAT.DBO.DB_FK))
    OPEN l_cursor
    FETCH NEXT FROM l_cursor INTO @constraint_name, @referencing_table_name -- zaladowanie do zmiennych,atrybutów pierwszego wiersza


    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- usuwamy spacje początkowe i koncowe z zmiennych
        set @referencing_table_name = LTRIM(RTRIM(@referencing_table_name))
        set @constraint_name = LTRIM(RTRIM(@constraint_name)) --

        --zmienna do usuniecie kluczy obcych z tabeli
        set @sql =   N'USE [' + @db + N']; alter table ' + @referencing_table_name  + N' drop constraint ' + @constraint_name

        --wykonanie  usuniecie kluczy obcych z tabeli
        EXEC sp_sqlexec @sql

        FETCH NEXT FROM l_cursor INTO @constraint_name, @referencing_table_name -- zaladowanie do zmiennych, atrybutów z kolejnego wiersza
    end
    CLOSE l_cursor
	DEALLOCATE l_cursor
go

EXEC DB_STAT.dbo.DB_TC_REMOVE_FK @db = N'pwx_db'

-- Sprawdzenie
use  pwx_db
SELECT
    f.name constraint_name
    ,OBJECT_NAME(f.parent_object_id) referencing_table_name
    ,COL_NAME(fc.parent_object_id, fc.parent_column_id) referencing_column_name
    ,OBJECT_NAME (f.referenced_object_id) referenced_table_name
    ,COL_NAME(fc.referenced_object_id, fc.referenced_column_id) referenced_column_name
        FROM sys.foreign_keys AS f
        JOIN sys.foreign_key_columns AS fc
        ON f.[object_id] = fc.constraint_object_id
        ORDER BY f.name

-- +---------------+----------------------+-----------------------+---------------------+----------------------+
-- |constraint_name|referencing_table_name|referencing_column_name|referenced_table_name|referenced_column_name|
-- +---------------+----------------------+-----------------------+---------------------+----------------------+

