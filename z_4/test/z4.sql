/*
** W większości baz definicja klucza głownego automatycznie tworzy indeks do tej kolumny
** Dlaczego ??
** Unikalna wartosc - trzeba szybko sprawdzić czy już takiej nie ma
** Często się szuka po kluczu głownym aby wybrać rekord do edycji
**
** Druga mozliwosc optymalizacji to klucze obce
** Standardowo założenie klucza obcego nie powoduje utworzenia indeksu !!!
**
** KLUCZ OBCY - standard
**
** Nie pozwala dodać rekordu do tabeli DETAIL ja w nadrzednej MASTER takowy nie istnieje
** OPTYMALNE bo w MASTER jest kucz głowny i szukanie szybkie
** Przyklad - wstawiamy POzFa z ID_FAKTURY = 5 -> Baza sprawdza sprawdza czy faktura z
** ID=5 istnieje. Jest to błyskawiczne ponieważ w tabeli Faktury jest to lucz głowny (ma indeks)
**
** Nie pozwala skasowac jak są rekordy podrzędne
*/

/* Kucz obcy to nie tylko kasowanie
** zakladam ze 99% zapytan ma warunki po kluczu obcym
** Przyklad - edytujemy Fakture, na formularzu pokazujemy dane faktury (szukanie po kluczu gł)
** Oraz jej pozycje -> warunek po kluczu obcym
** SELECT * FROM PozFa WHERE id_faktury = 5
*/
/*
** Zadanie numer 4 (Z4 isOD)
** Napisac procedurę, która ma parametr @NazwaBazy
** Dla podanej bazy wyszukuje wszystkie klucze obce
**  kolumny w tabeli podrzędnej będące kluczami obcymi
**  przypominam, ze jedno z zadan polegało na zapisaniu kluczy obcych do bazy
** Potrzebujemy nazwę tabeli podrzędnej  i kolumny w tej tabeli będącej kluczem obcym
** Ale tylko takie do których nie ma indeksów (sysindexes)
** Dla nich w pęti (kursor pojedynczo tworzymy)
** Indeksy o nazwie takim jak klucz FKI_TabMaster__TabDetails
** Details -tabela w której jest kolumna będąca kluczem obcym
** Master - tabela do której odwołuje się klucz
**
** U1. Wybieramy z danej bazy wszystie kolmny (i nazwy tabel w ktorych się znajdują
** oraz nazwy tabel do których się odnoszą - w celach nazwania klucza)
** takie zapytanie było do zrobienia w Z1
** U2. Ale tylko te kolumny dla których nie ma jeszcze indeksów
** U3. Tylko dla kolumn z U2 tworzymy indeksy
*/

/* sprawdzenie poprawnosci w sprawozdaniu - ze są potem INDEKSY
** I po 2 uruchomieniach nie powielonych indeksów
** Napisac polecenie SQL z 2 tabel gdzie wymusimy uzycie zrobionego indeksu
** Np. ze wspomnianych PozycjiFaktur gdzie id_faktury ma byc jakieś
*/

USE
    DB_STAT
GO

IF NOT EXISTS
    (select o.name AS tabelaDetail, i.name AS nazwa_klucza /* nazwę kolumny */
     from sysindexes i
              join sysobjects o ON (o.[id] = i.[id])
--         JOIN sys.foreign_key_columns fc  ON f.[object_id] = fc.constraint_object_id
     WHERE i.[name] = N'DB_STAT'
    )
    BEGIN
        CREATE INDEX FKI_DB_STAT__DB_RCOUNT ON DB_RCOUNT (stat_id)
    END
GO

SELECT *
FROM DB_RCOUNT d WITH (INDEX (FKI_DB_STAT__DB_RCOUNT))
WHERE d.stat_id = 2

use DB_STAT

SELECT i.name                               AS index_name
     , COL_NAME(ic.object_id, ic.column_id) AS column_name
     , ic.index_column_id
     , ic.key_ordinal
     , ic.is_included_column
FROM sys.indexes AS i
         INNER JOIN sys.index_columns AS ic
                    ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID('DB_STAT');


select o.name AS tabelaDetail, i.name AS nazwa_klucza /* nazwę kolumny */
from sys.indexes i
         join sys.objects o ON (o.id = i.id)
         INNER JOIN sys.index_columns AS ic
                    ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.[name] = N'DB_STAT'

select * /* nazwę kolumny */
from sys.indexes i

select DISTINCT o.type /* nazwę kolumny */
from sys.objects o

select * /* nazwę kolumny */
from sys.objects o
where type = N'U'
   or type = N'F'

select f.name                                                     constraint_name
     , OBJECT_NAME(f.parent_object_id)                            referencing_table_name
     , COL_NAME(fc.parent_object_id, fc.parent_column_id)         referencing_column_name
     , OBJECT_NAME(f.referenced_object_id)                        referenced_table_name
     , COL_NAME(fc.referenced_object_id, fc.referenced_column_id) referenced_column_name
FROM sys.foreign_keys AS f
         JOIN sys.foreign_key_columns AS fc
              ON f.[object_id] = fc.constraint_object_id

SELECT i.name                               AS index_name
     , COL_NAME(ic.object_id, ic.column_id) AS column_name
     , ic.index_column_id
     , ic.key_ordinal
     , ic.is_included_column
FROM sys.indexes AS i
         INNER JOIN sys.index_columns AS ic
                    ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID('DB_STAT');

use DB_STAT

select *
FROM sys.indexes AS i
         INNER JOIN sys.index_columns AS ic
                    ON i.object_id = ic.object_id AND i.index_id = ic.index_id
         join sys.objects o on o.object_id =
WHERE i.object_id = OBJECT_ID('DB_STAT');

select *
from sys.objects o

select *
FROM sys.foreign_keys AS f
         JOIN sys.foreign_key_columns AS fc
              ON f.[object_id] = fc.constraint_object_id

select * from sys.foreign_key_columns

use pwx_db
select i.[name]                                          as index_name,
       substring(column_names, 1, len(column_names) - 1) as [columns],
       case
           when i.[type] = 1 then 'Clustered index'
           when i.[type] = 2 then 'Nonclustered unique index'
           when i.[type] = 3 then 'XML index'
           when i.[type] = 4 then 'Spatial index'
           when i.[type] = 5 then 'Clustered columnstore index'
           when i.[type] = 6 then 'Nonclustered columnstore index'
           when i.[type] = 7 then 'Nonclustered hash index'
           end                                           as index_type,
       case
           when i.is_unique = 1 then 'Unique'
           else 'Not unique' end                         as [unique],
       schema_name(t.schema_id) + '.' + t.[name]         as table_view,
       case
           when t.[type] = 'U' then 'Table'
           when t.[type] = 'V' then 'View'
           end                                           as [object_type]
from sys.objects t
         inner join sys.indexes i
                    on t.object_id = i.object_id
         cross apply (select col.[name] + ', '
                      from sys.index_columns ic
                               inner join sys.columns col
                                          on ic.object_id = col.object_id
                                              and ic.column_id = col.column_id
                      where ic.object_id = t.object_id
                        and ic.index_id = i.index_id
                      order by key_ordinal
                      for xml path ('')) D (column_names)
where t.is_ms_shipped <> 1
  and index_id > 0
order by i.[name]


use DB_STAT

CREATE INDEX test_index ON DB_FK(stat_id);

select
       i.[name]                                          as index_name,
      col.name as col_name,
       case
           when i.[type] = 1 then 'Clustered index'
           when i.[type] = 2 then 'Nonclustered unique index'
           when i.[type] = 3 then 'XML index'
           when i.[type] = 4 then 'Spatial index'
           when i.[type] = 5 then 'Clustered columnstore index'
           when i.[type] = 6 then 'Nonclustered columnstore index'
           when i.[type] = 7 then 'Nonclustered hash index'
           end                                           as index_type,
       case
           when i.is_unique = 1 then 'Unique'
           else 'Not unique' end                         as [unique],
       schema_name(t.schema_id) + '.' + t.[name]         as table_view,
       case
           when t.[type] = 'U' then 'Table'
           when t.[type] = 'V' then 'View'
           end                                           as [object_type]
from sys.objects t
         inner join sys.indexes i
                    on t.object_id = i.object_id
         inner join sys.index_columns ic on ic.object_id = t.object_id AND i.index_id = ic.index_id
         inner join sys.columns col
                    on ic.object_id = col.object_id
                        and ic.column_id = col.column_id
where  t.type = 'U'
  and i.is_primary_key = 0
--   and index_id > 0
order by i.[name]

DROP INDEX DB_FK.test_index;

select ic.object_id
        from sys.objects t
         inner join sys.indexes i
                    on t.object_id = i.object_id
         inner join sys.index_columns ic on ic.object_id = t.object_id
         inner join sys.columns col
                    on ic.object_id = col.object_id
                        and ic.column_id = col.column_id
-- where ic.object_id = t.object_id
--   and ic.index_id = i.index_id
where  t.type = 'U'
  and i.is_primary_key = 1
--   and index_id > 0
order by i.[name]


select * from  sys.columns


declare @sql nvarchar(4000)
set @sql = 'use db_stat; select f.name  as constraint_name
     , OBJECT_NAME(f.parent_object_id)  as referencing_table_name
     , COL_NAME(fc.parent_object_id, fc.parent_column_id) as referencing_column_name
     , OBJECT_NAME(f.referenced_object_id) as referenced_table_name
     , COL_NAME(fc.referenced_object_id, fc.referenced_column_id) referenced_column_name
FROM sys.foreign_keys AS f
         JOIN sys.foreign_key_columns AS fc
              ON f.[object_id] = fc.constraint_object_id
where OBJECT_NAME(f.parent_object_id) + ''.'' + COL_NAME(fc.parent_object_id, fc.parent_column_id)
          not in
      (
    select t.[name] + ''.'' + col.[name] as table_view /* tabela z nazwa columny */
    from DB_STAT.sys.objects t /* łaczenie tabel przez obejct id oraz columny, index id*/
             inner join sys.indexes i
                        on t.object_id = i.object_id
             inner join sys.index_columns ic on ic.object_id = t.object_id AND i.index_id = ic.index_id
             inner join sys.columns col
                        on ic.object_id = col.object_id
                            and ic.column_id = col.column_id
    where t.type = ''U'' /* tylko tabele uzytkownika */
      and i.is_primary_key = 0 /* bez tabel z kluczem głównym, ( powinno dobrze rowniez jesli i.is_primary_key = 1 )  */
              )'
exec sp_sqlexec @sql