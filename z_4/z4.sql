use master
go

IF NOT EXISTS
    (SELECT 1
     from sysobjects o (NOLOCK)
     WHERE (o.[name] = 'CRATE_INDEX_TO_FK_COLUMNS_IN_DB')
       AND (OBJECTPROPERTY(o.[ID], 'IsProcedure') = 1)
    )
    BEGIN
        DECLARE @stmt nvarchar(100)
        SET @stmt = 'CREATE PROCEDURE dbo.CRATE_INDEX_TO_FK_COLUMNS_IN_DB AS'
        EXEC sp_sqlexec @stmt
    END
GO

use master;

ALTER PROCEDURE dbo.CRATE_INDEX_TO_FK_COLUMNS_IN_DB(@db nvarchar(100))
AS

declare  @exec_procedure nvarchar(4000) /* aby moc użyc use @db, uzyłem zminnej gdzie zapisze kod procedury */

set @exec_procedure = 'use ['+@db+'];
DECLARE
    @sql nvarchar(2000),
    @db nvarchar(100), -- nazwa bazy danych
    @constraint_name nvarchar(100), -- atrybuty tabeli DB_TC_STORE_FK potrzebne do odtworzenia kluczy
    @referencing_table_name nvarchar(100),
    @referencing_column_name nvarchar(100),
    @referenced_table_name nvarchar(100),
    @referenced_column_name nvarchar(100),
    @index_name nvarchar(200)


DECLARE
    l_cursor CURSOR FOR -- zaladowanie kursora do tabelki
    select f.name                                                     constraint_name
         , OBJECT_NAME(f.parent_object_id)                            referencing_table_name
         , COL_NAME(fc.parent_object_id, fc.parent_column_id)         referencing_column_name
         , OBJECT_NAME(f.referenced_object_id)                        referenced_table_name
         , COL_NAME(fc.referenced_object_id, fc.referenced_column_id) referenced_column_name
    FROM sys.foreign_keys AS f
             JOIN sys.foreign_key_columns AS fc
                  ON f.[object_id] = fc.constraint_object_id
    where OBJECT_NAME(f.parent_object_id) + ''.'' + COL_NAME(fc.parent_object_id, fc.parent_column_id)
              not in
          (
              select t.[name] + ''.'' + col.[name] as table_view /* tabela z nazwa columny */
              from sys.objects t /* łaczenie tabel przez obejct id oraz columny, index id*/
                       inner join sys.indexes i
                                  on t.object_id = i.object_id
                       inner join sys.index_columns ic on ic.object_id = t.object_id AND i.index_id = ic.index_id
                       inner join sys.columns col
                                  on ic.object_id = col.object_id
                                      and ic.column_id = col.column_id
              where t.type = ''U'' /* tylko tabele uzytkownika */
                and i.is_primary_key = 0 /* bez tabel z kluczem głównym, ( powinno dobrze rowniez jesli i.is_primary_key = 1 )  */
          )
OPEN l_cursor;
FETCH NEXT
    FROM l_cursor
    INTO @constraint_name, @referencing_table_name, @referencing_column_name, @referenced_table_name, @referenced_column_name;
WHILE @@FETCH_STATUS = 0
    BEGIN
        set
            @referencing_table_name = LTRIM(RTRIM(@referencing_table_name));
        set @constraint_name = LTRIM(RTRIM(@constraint_name));
        set @referencing_column_name = LTRIM(RTRIM(@referencing_column_name));
        set @referenced_table_name = LTRIM(RTRIM(@referenced_table_name));
        set @referenced_column_name = LTRIM(RTRIM(@referenced_column_name));
        set @index_name = ''FKI_'' + @referenced_table_name + ''_'' + @referencing_table_name;
        -- Polecenie tworszenie indeksów
        set @sql = '' CREATE INDEX '' + @index_name + '' ON '' + @referencing_table_name + ''('' +
                   @referencing_column_name + '')'';
        -- wykonanie polecenia
        EXEC sp_sqlexec @sql;
        FETCH NEXT
            FROM l_cursor
            INTO @constraint_name, @referencing_table_name, @referencing_column_name, @referenced_table_name, @referenced_column_name;

    end
CLOSE l_cursor;
DEALLOCATE l_cursor;'
exec sp_sqlexec @exec_procedure; /* wykonanie procedury*/
go

use DB_STAT

/* Dodanie jednej testowej indeksu aby sprawidzic, czy procedura nie doda tego indeksu jescze raz */

CREATE INDEX test_index ON DB_FK(stat_id);

select f.name                                                     constraint_name
     , OBJECT_NAME(f.parent_object_id)                            referencing_table_name
     , COL_NAME(fc.parent_object_id, fc.parent_column_id)         referencing_column_name
     , OBJECT_NAME(f.referenced_object_id)                        referenced_table_name
     , COL_NAME(fc.referenced_object_id, fc.referenced_column_id) referenced_column_name
FROM sys.foreign_keys AS f
         JOIN sys.foreign_key_columns AS fc
              ON f.[object_id] = fc.constraint_object_id
where OBJECT_NAME(f.parent_object_id) + '.' + COL_NAME(fc.parent_object_id, fc.parent_column_id)
          not in
      (
    select t.[name] + '.' + col.[name] as table_view /* tabela z nazwa columny */
    from sys.objects t /* łaczenie tabel przez obejct id oraz columny, index id*/
             inner join sys.indexes i
                        on t.object_id = i.object_id
             inner join sys.index_columns ic on ic.object_id = t.object_id AND i.index_id = ic.index_id
             inner join sys.columns col
                        on ic.object_id = col.object_id
                            and ic.column_id = col.column_id
    where t.type = 'U' /* tylko tabele uzytkownika */
      and i.is_primary_key = 0 /* bez tabel z kluczem głównym, ( powinno dobrze rowniez jesli i.is_primary_key = 1 )  */
              )
/* Sprawdzenie czy wyswietla columny kluczów obcych, które nie posiadają indeksów indeksy */

/*
 +------------------+----------------------+-----------------------+---------------------+----------------------+
|constraint_name   |referencing_table_name|referencing_column_name|referenced_table_name|referenced_column_name|
+------------------+----------------------+-----------------------+---------------------+----------------------+
|FK_DB_STAT__RCOUNT|DB_RCOUNT             |stat_id                |DB_STAT              |stat_id               |
+------------------+----------------------+-----------------------+---------------------+----------------------+
 */



/* wykonanie procedury*/

exec master.dbo.CRATE_INDEX_TO_FK_COLUMNS_IN_DB @db = 'DB_STAT'
-- Sprawdzenie  indeksów w databasie
use DB_STAT

select
       i.[name]                                          as index_name
       ,t.[name] + '.' + col.[name] as table_view /* tabela z nazwa columny */
    from sys.objects t /* łaczenie tabel przez obejct id oraz columny, index id*/
             inner join sys.indexes i
                        on t.object_id = i.object_id
             inner join sys.index_columns ic on ic.object_id = t.object_id AND i.index_id = ic.index_id
             inner join sys.columns col
                        on ic.object_id = col.object_id
                            and ic.column_id = col.column_id
    where t.type = 'U' /* tylko tabele uzytkownika */
      and i.is_primary_key = 0 /* bez kolumn z kluczem głównym  */
/*
 +---------------------+-----------------+
|index_name           |table_view       |
+---------------------+-----------------+
|FKI_DB_STAT_DB_RCOUNT|DB_RCOUNT.stat_id|
|test_index           |DB_FK.stat_id    |
+---------------------+-----------------+
 */

select *
from DB_STAT join DB_RCOUNT DR on DB_STAT.stat_id = DR.stat_id
where dr.stat_id = 1;

/*
+-------+------+-------+-----------------------+-------+-----+-------+-------------+------+-----------------------+
|stat_id|db_nam|comment|when                   |usr_nam|host |stat_id|table        |RCOUNT|RDT                    |
+-------+------+-------+-----------------------+-------+-----+-------+-------------+------+-----------------------+
|1      |pwx_db|test   |2021-10-05 16:40:44.220|dbo    |Zenon|1      |CECHY        |2     |2021-10-05 16:40:44.387|
|1      |pwx_db|test   |2021-10-05 16:40:44.220|dbo    |Zenon|1      |etaty        |10    |2021-10-05 16:40:44.393|
|1      |pwx_db|test   |2021-10-05 16:40:44.220|dbo    |Zenon|1      |firmy        |3     |2021-10-05 16:40:44.400|
|1      |pwx_db|test   |2021-10-05 16:40:44.220|dbo    |Zenon|1      |FIRMY_CECHY  |6     |2021-10-05 16:40:44.410|
|1      |pwx_db|test   |2021-10-05 16:40:44.220|dbo    |Zenon|1      |miasta       |4     |2021-10-05 16:40:44.417|
|1      |pwx_db|test   |2021-10-05 16:40:44.220|dbo    |Zenon|1      |osoby        |5     |2021-10-05 16:40:44.423|
|1      |pwx_db|test   |2021-10-05 16:40:44.220|dbo    |Zenon|1      |WARTOSCI_CECH|5     |2021-10-05 16:40:44.430|
|1      |pwx_db|test   |2021-10-05 16:40:44.220|dbo    |Zenon|1      |woj          |3     |2021-10-05 16:40:44.440|
+-------+------+-------+-----------------------+-------+-----+-------+-------------+------+-----------------------+
 */



