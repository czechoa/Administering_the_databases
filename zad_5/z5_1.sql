use master
declare @db nvarchar(100)
    ,@exec_procedure nvarchar(4000)
    ,@table nvarchar(100)
    ,@col nvarchar(100)

set @db = 'db_stat'
set @table = 'test_us_kol'
set @col = 'czy_wazny'

set @exec_procedure = 'use ['+@db+'];
declare
    @db nvarchar(100),
    @table nvarchar(100),
    @col nvarchar(100)
set @table = ' + @db + '
set @col = '+ @col +'

IF EXISTS
    (select 1 /* tabela z nazwa columny */
     from sys.objects t /* łaczenie tabel przez obejct id oraz columny, index id*/
              inner join sys.columns col
                         on t.object_id = col.object_id
     where t.name = @table
       and col.name = @col
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
        WHERE obj_table.NAME = @table


        IF @constraint IS NOT NULL
            BEGIN
                select @constraint
                set @sql = '' alter table '' + @table +
                           N'' drop constraint '' + @constraint
                -- wykonanie polecenia
                EXEC sp_sqlexec @sql
            END

        set @sql = '' alter table '' + @table +
                   N'' drop column '' + @col

        -- wykonanie polecenia
        EXEC sp_sqlexec @sql

    end'

exec sp_sqlexec @exec_procedure; /* wykonanie procedury*/
