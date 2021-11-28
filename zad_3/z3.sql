create database faktury_db

use faktury_db

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
    numer_faktry int  NOT NULL
        constraint pk_LOG_FA primary key,
    nip_klienta  nvarchar(20) NOT NULL,
    data         datetime     NOT NULL,
    anulowana    bit          not null
)

drop table Faktura

drop table klient

drop table Pozycje

drop table LOG_FA


/*
 tworzymy dwa trygiery insert i na update
 Nie mozna kasowac
 */
CREATE TRIGGER UPD_FA On Faktura AFTER UPDATE
AS
    IF UPDATE(anulowana) -- update dotyczył tego pola
        AND (SELECT 1
             FROM inserted i
                      join deleted d ON (i.id_faktury = d.id_faktury)
             WHERE NOT (i.ANULOAWANA = d.anulowana)
       )
        INSERT INTO LOG_FA (numer_faktry, nip_klienta, data, anulowana )
        SELECT  i.,i.anulowana
        FROM inserted i
        join deleted d ON (i.id_faktury = d.id_faktury )
			WHERE NOT (i.ANULOAWANA = d.anulowana)

ALTER TRIGGER dbo.UPD_FA On Faktura AFTER INSERT
AS
    insert into LOG_FA (numer_faktry,nip_klienta,data,anulowana)
    Select
    i.numer,k.NIP, i.data, i.anulowana
    FROM INSERTED i
    JOIN dbo.Klient k on k.id_klienta = i.id_klienta -- Potrzebuje wziać nip klijenta a nie nie id.klienta
    ;
Go

insert into Klient (NIP, nazwa, adres)
values (N'abcsd12','testowy','gdzies daleko');


insert into Faktura (id_klienta, data, numer, anulowana)
values (1,GETDATE(),123335,0);

