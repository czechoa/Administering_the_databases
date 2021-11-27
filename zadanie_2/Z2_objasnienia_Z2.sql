USE DB_STAT
GO

/* 2021.10.25 maciej.stodolsi@ee.pw.edu.pl */
/* 11:00 poprawiłęm procedue do kluczy obcych teraz daje prawidłową składnie
USE [pwx_db];  ALTER TABLE etaty ADD CONSTRAINT fk_etaty__firmy 
FOREIGN KEY (id_firmy) REFERENCES firmy(nazwa_skr)
*/

/* stworzyć tabelę do przechowywania kluczy obcych na bazie */

/* test 
EXEC dbo.DB_FK_RESTORE  @db='pwx_db'
USE [pwx_db];  ALTER TABLE etaty ADD CONSTRAINT FK_ETATY_ETATY FOREIGN KEY (z_etatu) REFERENCES etaty(id_etatu)
USE [pwx_db];  ALTER TABLE etaty ADD CONSTRAINT fk_etaty__osoby FOREIGN KEY (id_osoby) REFERENCES osoby(id_osoby)
USE [pwx_db];  ALTER TABLE etaty ADD CONSTRAINT fk_etaty__firmy FOREIGN KEY (id_firmy) REFERENCES firmy(nazwa_skr)

*/

/* Z2 
** Napisac 2 procedury
** bk_db - backup pojedynczej bazy (2 par -> nazwa bazy i katalog)
** bk_all_db - backup wszystkich baz (nazwa katalogu)
** do plików na wyznaczonym katalogu, bk_all_db musi korzystać z bk_db i przekazywać jej nazwę bazy i nazwę katalogu
** nazwa kazdego pliku to nazwabazy PODKRESLENIE YYYYYMMDDHHMM

** Zaplanować uruchamianie procedury backupy wszystkich baz poprzez SQL Agent na co dzien
** Zdokumentowac i udowodnic, ze JOB zadzialał i pliki powstały
*/

/* wskazówka -> sładnia backupu do pliku 
*/

/* pierwsza procedura do napisnia tworzy i zapisuje backup bazy 
** (parametr @db) w katalogu @path - katalog serwera */

DECLARE @db nvarchar(100) -- to bedzie parametr procedury (nazwa bazy)
, @path nvarchar(200) -- drugi parametr np domyslnie C:\temp\ musi sie konczyc na \
/* @path to sciezka na dysku SERWERA do katalogu w którym zapiszemy backup */

/* normalnie to bedą parametry wywolania - sprawdzamy czy baza istnieje */
/* dla testów takie przypisałem dane - normalnie parametry procedury */
SET @db = N'PWX_DB'
-- SET @path = N'/home/testuser/Documents/'  -- powinien sie onczyc na /,
--  uzytkownik serwa musi miec dostep do tego katalogu  (
SET @path = N'/home/andrzej/DataGripProjects/admistrowanie_baz_danych'  -- powinien sie onczyc na /,

/* od tego momentu to jaby fragment Państwa procedury */

declare @fname nvarchar(1000)
SET @path = LTRIM(RTRIM(@path)) -- pomijamy spacje z obu stron

IF @path NOT LIKE N'%/' -- nie ma / ( linux a nie windows)  na końcu
	SET @path = @path + N'/'

SET @fname = REPLACE(REPLACE(CONVERT(nchar(19), GETDATE(), 126), N':', N'_'),'-','_')
SET @fname = @path + RTRIM(@db)  + @fname + N'.bak'

-- test
-- SELECT @fname
-- C:\temp\PWX_DB2021_10_25T13_33_55.bak

DECLARE @sql nvarchar(1000)

SET @sql = 'backup database ' + @db + ' to DISK= N''' + @fname + ''''
--backup database PWX_DB to DISK= 'C:\temp\PWX_DB2021_10_25T13_33_55.bak'
-- test
-- SELECT @sql
-- backup database PWX_DB to DISK= 'C:\temp\PWX_DB2021_10_25T13_33_55.bak'

EXEC sp_sqlexec @sql



