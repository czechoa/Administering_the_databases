use db_stat
declare @db nvarchar(50)
set @db = 'db_stat'

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
    from DB_STAT.sys.objects t /* łaczenie tabel przez obejct id oraz columny, index id*/
             inner join sys.indexes i
                        on t.object_id = i.object_id
             inner join sys.index_columns ic on ic.object_id = t.object_id AND i.index_id = ic.index_id
             inner join sys.columns col
                        on ic.object_id = col.object_id
                            and ic.column_id = col.column_id
    where t.type = 'U' /* tylko tabele uzytkownika */
      and i.is_primary_key = 0 /* bez tabel z kluczem głównym, ( powinno dobrze rowniez jesli i.is_primary_key = 1 )  */
              )

select * from  #TempDestinationTable

use master


