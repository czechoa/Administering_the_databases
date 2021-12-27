use master
ALTER PROCEDURE dbo.REMOVE_COLUMN(@db nvarchar(100), @table nvarchar(100), @col nvarchar(100)) AS
    declare @exec_procedure nvarchar(4000) /* aby moc użyc use @db, uzyłem zminnej gdzie zapisze kod procedury */

    select @table
    set @exec_procedure = 'use [' + @db + '];' +
    N' select * from sys.objects t ' +
        N'inner join sys.columns col ' +
        N'on t.object_id = col.object_id' +
    N' where t.name =  '+@table+'  and col.name = '+@col

    select @exec_procedure
    exec sp_sqlexec @exec_procedure; /* wykonanie procedury*/
GO

use master
exec REMOVE_COLUMN @db = 'db_stat', @table = 'test_us_kol', @col = 'czy_wazny'

declare  @table nvarchar(100),
    @db nvarchar(100),
    @col nvarchar(100),
    @exec_procedure nvarchar(4000)
set @table = 'test_us_kol'
set @col = 'czy_wazny'
set @db = 'db_stat'
set @exec_procedure = 'use [' + @db + '];' +
N' select * from sys.objects t ' +
    N'inner join sys.columns col ' +
    N'on t.object_id = col.object_id' +
                      N' where t.type = ''U'' and t.name = '''+@table+''' '

select @exec_procedure
exec sp_sqlexec @exec_procedure;