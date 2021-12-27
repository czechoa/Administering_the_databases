use master
/* tworzenie procedury jesli nie itnieje */
IF NOT EXISTS
    (SELECT 1
     from sysobjects o (NOLOCK)
     WHERE (o.[name] = 'REMOVE_COLUMN')
       AND (OBJECTPROPERTY(o.[ID], 'IsProcedure') = 1)
    )
    BEGIN
        DECLARE @stmt nvarchar(100)
        SET @stmt = 'CREATE PROCEDURE dbo.REMOVE_COLUMN AS '
        EXEC sp_sqlexec @stmt
    END
GO

ALTER PROCEDURE dbo.REMOVE_COLUMN(@db nvarchar(100), @table nvarchar(100), @col nvarchar(100)) AS
    declare @exec_procedure nvarchar(4000) /* aby moc użyc use @db, uzyłem zmiennej gdzie zapisze kod procedury */

    set @exec_procedure = 'use [' + @db + '];
IF EXISTS
    (select 1 /* tabela z nazwa columny */
     from sys.objects t /* łaczenie tabel przez obejct id oraz columny, index id*/
              inner join sys.columns col
                         on t.object_id = col.object_id
     where t.name = ''' +@table+''' and col.name = '''+@col+'''
    )
    BEGIN
        declare @constraint nvarchar(100),
            @sql nvarchar(2000)

        SELECT @constraint = obj_Constraint.NAME -- Przypis wartosc obj_Constraint
        FROM sys.objects obj_table
                 JOIN sys.objects obj_Constraint
                      ON obj_table.object_id = obj_Constraint.parent_object_id
                 JOIN sys.sysconstraints constraints
                      ON constraints.constid = obj_Constraint.object_id
                 JOIN sys.columns columns
                      ON columns.object_id = obj_table.object_id
                          AND columns.column_id = constraints.colid
        WHERE obj_table.NAME = ''' +@table + '''

        IF @constraint IS NOT NULL /*  sprawdzamy czy są pewne ograniczenia (np DEFAULT był założony)*/
            BEGIN /* Jak TAK - usuwamy ograniczenia */
                select @constraint
                set @sql = '' alter table '' + ''' +@table+''' +
                           N'' drop constraint '' + @constraint
                -- wykonanie polecenia
                EXEC sp_sqlexec @sql
            END
        /* usuwanie kolumny */
        set @sql = '' alter table '' + '''+ @table +'''+
                   N'' drop column '' +'''+ @col + '''

        -- wykonanie polecenia
        EXEC sp_sqlexec @sql

    end'

    exec sp_sqlexec @exec_procedure; /* wykonanie procedury*/
GO
/* test procedury */

use db_stat
CREATE TABLE dbo.test_us_kol
(
    [id]      nchar(6) not null,
    nie_wazne nchar(6) not null,
    czy_wazny bit      NOT NULL default 0 /* to powoduje powstanie constrain
									** system nada unialną nazwę */
)
go

INSERT INTO test_us_kol ([id],nie_wazne)
VALUES (N'ala','nie')
INSERT INTO test_us_kol ([id],nie_wazne, czy_wazny)
VALUES (N'kot','nie', 1)

select *
from test_us_kol;
/*
+------+---------+---------+
|id    |nie_wazne|czy_wazny|
+------+---------+---------+
|ala   |nie      |false    |
|kot   |nie      |true     |
+------+---------+---------+

 */
/* usuniecie kolumny z ograniczami czy_wany  */

use master
exec REMOVE_COLUMN @db = 'db_stat', @table = 'test_us_kol', @col = 'czy_wazny'
/*
+------------------------------+
|                              |
+------------------------------+
|DF__test_us_k__czy_w__65370702|
+------------------------------+
 */

use db_stat
select *
from test_us_kol;
/*
+------+---------+
|id    |nie_wazne|
+------+---------+
|ala   |nie      |
|kot   |nie      |
+------+---------+
 */

/* usuniecie kolumny z bez ograniczen */
use master
exec REMOVE_COLUMN @db = 'db_stat', @table = 'test_us_kol', @col = 'nie_wazne'

use db_stat
select *
from test_us_kol;
/*
 +------+
|id    |
+------+
|ala   |
|kot   |
+------+
 */

/* po tescie usuniecie tabeli */
use db_stat
drop TABLE test_us_kol