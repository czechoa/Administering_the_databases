/* usuwanie kolumny z tabeli
** Procedura BD z 3 par
** nazwa bazy, nazwa tabeli, nazwa kol
**
** 1. Sprawdzamy czy kolumna istnieje (zapytanie z syscolumns połaczone z sysobjects po ID)
** 1.1. Jak istnieje sprawdzamy czy są pewne ograniczenia (np DEFAULT był założony)
** 1.2 Jak TAK - usuwamy ograniczenia
** 1.3. Usuwamy kolumne
*/


/*
 1. Sprawdzamy czy kolumna istnieje (zapytanie z syscolumns połaczone z sysobjects po ID)
 */
use db_stat
/* tworzenie tabeli do testu */
CREATE TABLE dbo.test_us_kol
(	[id] nchar(6) not null
,	czy_wazny bit NOT NULL default 0 /* to powoduje powstanie constrain
									** system nada unialną nazwę */
)
go
INSERT INTO test_us_kol ([id]) VALUES (N'ala')
INSERT INTO test_us_kol ([id], czy_wazny) VALUES (N'kot', 1)

DECLARE
    @table nvarchar(100),
    @col nvarchar(100)

set @table = N'test_us_kol'
set @col = N'czy_wazny'

SELECT obj_table.NAME      AS 'table',
        columns.NAME        AS 'column',
        obj_Constraint.NAME AS 'constraint',
        obj_Constraint.type AS 'type'

    FROM   sys.objects obj_table
        JOIN sys.objects obj_Constraint
            ON obj_table.object_id = obj_Constraint.parent_object_id
        JOIN sys.sysconstraints constraints
             ON constraints.constid = obj_Constraint.object_id
        JOIN sys.columns columns
             ON columns.object_id = obj_table.object_id
            AND columns.column_id = constraints.colid
    WHERE obj_table.NAME=@table

select * /* tabela z nazwa columny */
     from sys.objects t /* łaczenie tabel przez obejct id oraz columny, index id*/
              inner join sys.columns col
                         on t.object_id = col.object_id
     where t.name = @table
       and col.name = @col

INSERT INTO test_us_kol ([id]) VALUES (N'ala')
INSERT INTO test_us_kol ([id], czy_wazny) VALUES (N'kot', 1)

DECLARE
    @table nvarchar(100),
    @col nvarchar(100)

set @table = N'test_us_kol'
set @col = N'czy_wazny'

IF EXISTS
    (select 1 /* tabela z nazwa columny */
     from sys.objects t /* łaczenie tabel przez obejct id oraz columny, index id*/
              inner join sys.columns col
                         on t.object_id = col.object_id
     where t.name = @table
       and col.name = @col
    )
    BEGIN

        SELECT @table
    end



declare  @constraint nvarchar(100)

        SELECT @constraint =  obj_Constraint.NAME

        FROM sys.objects obj_table
                 JOIN sys.objects obj_Constraint
                      ON obj_table.object_id = obj_Constraint.parent_object_id
                 JOIN sys.sysconstraints constraints
                      ON constraints.constid = obj_Constraint.object_id
                 JOIN sys.columns columns
                      ON columns.object_id = obj_table.object_id
                          AND columns.column_id = constraints.colid
        WHERE obj_table.NAME = 'Db_stat'

IF @constraint IS NOT NULL
BEGIN
    SELECT @constraint
end


set @sql = N'USE [' + @db + N']; select 1 ' +
           N' from sys.objects t ' +
           N'inner join db_stat.sys.columns col ' +
           N'on t.object_id = col.object_id ' +
           N'where t.name = ' + @table +
           N' and col.name = ' + @col

-- wykonanie polecenia

EXEC sp_sqlexec @sql