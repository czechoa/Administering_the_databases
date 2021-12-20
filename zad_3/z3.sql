create database faktury_db

use faktury_db

SELECT *
FROM
  SYSOBJECTS
WHERE
  xtype = 'U';


drop table Faktura

drop table Klient

drop table Pozycje

drop table LOG_FA

create table dbo.Klient
(
    id_klienta int IDENTITY  NOT NULL
        constraint pk_Klient primary key,
    NIP        nvarchar(20)  NOT NULL,
    nazwa      nvarchar(100) NOT NULL,
    adres      nvarchar(100) NOT NULL
)

create table dbo.Faktura
(
    id_faktury int IDENTITY NOT NULL
        constraint pk_Faktura primary key,
    id_klienta int          NOT NULL
        constraint fk_Faktura_Klient foreign key
            references Klient (id_klienta),
    data       datetime     NOT NULL,
    numer      int          NOT NULL,
    anulowana  bit          NOT NULL
)

create table dbo.Pozycje
(
    id_faktury int IDENTITY  NOT NULL
        constraint pk_Pozycje primary key,
    opis       nvarchar(100) NOT NULL,
    cena       money         NOT NULL
)

/* Dane krytczne , ktore trzeba zapamietac */

create table LOG_FA
(
    id_LOG_FA int IDENTITY NOT NULL
        constraint pk_LOG_FA primary key, -- Dodanie id LOG_FA  aby moc powtarzac ten sam numer numer faktury w roznych akordach (insert a potem update)
    numer_faktry int          NOT NULL,
    nip_klienta  nvarchar(20) NOT NULL,
    data         datetime     NOT NULL,
    anulowana    bit          not null
)




/*
 tworzymy dwa trygiery insert i na update
 Nie mozna kasowac
 */
CREATE TRIGGER dbo.UPD_FA  On Faktura AFTER UPDATE
    AS
    IF UPDATE(anulowana) -- update dotyczył tego pola
        AND  EXISTS(SELECT 1
             FROM inserted i
                      join deleted d ON (i.id_faktury = d.id_faktury)
             WHERE NOT (i.anulowana = d.anulowana)
       )
    BEGIN
        INSERT INTO LOG_FA (numer_faktry, nip_klienta, data, anulowana )
        SELECT  i.numer,k.NIP, i.data, i.anulowana
        FROM inserted i
        join Klient k on k.id_klienta = i.id_klienta
        join deleted d ON (i.id_faktury = d.id_faktury )
			WHERE NOT (i.anulowana = d.anulowana)
    END
GO

CREATE TRIGGER  dbo.INSERT_FA On Faktura AFTER INSERT
    AS
    insert into LOG_FA (numer_faktry, nip_klienta, data, anulowana)
    Select i.numer,
           k.NIP,
           i.data,
           i.anulowana
    FROM INSERTED i
             JOIN dbo.Klient k on k.id_klienta = i.id_klienta -- Potrzebuje wziać nip klienta a  nie id.klienta
    ;
Go

-- Test

-- - wstawiacie minimum 6 faktur i 3 klientów
insert into Klient (NIP, nazwa, adres)
values (N'abcsd12444', 'testowy 1', 'gdzies daleko'),(N'abcsd12qw', 'testowy 2', 'gdzies bardzo daleko'),(N'abcsd12', 'testowy 3', 'nie daleko') ;


insert into Faktura (id_klienta, data, numer, anulowana)
values (1, GETDATE(), 11, 0),(1, GETDATE(), 12, 0)
,(1, GETDATE(), 13, 0),(3, GETDATE(), 31, 0)
,(2, GETDATE(), 21, 0),(2, GETDATE(), 22, 0);



-- backup bazy
EXEC master.dbo.DB_BACKUP @db = N'faktury_db', @path = N'/var/opt/mssql/backups/faktury/'


-- - wstawiacie minimum 3 faktur i 1  klientów

insert into Klient (NIP, nazwa, adres)
values (N'abcsd12444T4', 'testowy 4', 'gdzies daleko stad');

insert into Faktura (id_klienta, data, numer, anulowana)
values (4, GETDATE(), 41, 0),(4, GETDATE(), 42, 0)
,(2, GETDATE(), 23, 0)
-- oraz zmnienie statusu faktury
update Faktura
set anulowana = 1
where id_faktury = 1;

-- odtwarzacie backup pod nazwą BK_XX

RESTORE DATABASE BK_XX
FROM  DISK = N'/var/opt/mssql/backups/faktury/faktury_db2021_11_28T16_10_09.bak' WITH  FILE = 1,
MOVE 'faktury_db' TO '/var/opt/mssql/data/BK_XX.mdf',
MOVE 'faktury_db_log' TO '/var/opt/mssql/data/BK_XX_log.mdf',
RECOVERY, NOUNLOAD, STATS = 5;
-- zapytanie pokazujące co jest w LOGU a czego nie ma w bazie BK_XX

use BK_XX

select *
from faktury_db..LOG_FA log
where log.id_LOG_FA not IN (
select id_LOG_FA
from BK_XX..Faktura bk_f
join faktury_db..LOG_FA log on log.numer_faktry = bk_f.numer
where log.anulowana = bk_f.anulowana);









