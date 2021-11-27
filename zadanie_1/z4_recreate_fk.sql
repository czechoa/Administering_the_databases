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

use DB_STAT

ALTER PROCEDURE dbo.DB_TC_RECREATE_FK
AS

    -- decklaracja zmiennych
DECLARE
    @sql                     nvarchar(2000),
    @db                      nvarchar(100), -- nazwa bazy danych
    @constraint_name         nvarchar(100), -- -- atrybuty tabeli DB_TC_STORE_FK potrzebne do odtworzenia kluczy
    @referencing_table_name  nvarchar(100),
    @referencing_column_name nvarchar(100),
    @referenced_table_name   nvarchar(100),
    @referenced_column_name  nvarchar(100)

DECLARE
    l_cursor CURSOR FOR -- zaladowanie kursora do tabelki
        select db_nam, -- potrzebuje wiedzieć jakiej bazy danej, stworzyc ponownie klucze
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

