use db_stat
CREATE TABLE dbo.test_us_kol
(
    [id]      nchar(6) not null,
    czy_wazny bit      NOT NULL default 0 /* to powoduje powstanie constrain
									** system nada unialną nazwę */
)
go

INSERT INTO test_us_kol ([id])
VALUES (N'ala')
INSERT INTO test_us_kol ([id], czy_wazny)
VALUES (N'kot', 1)

use master
exec REMOVE_COLUMN @db = 'db_stat', @table = 'test_us_kol', @col = 'czy_wazny'

use db_stat
drop TABLE test_us_kol