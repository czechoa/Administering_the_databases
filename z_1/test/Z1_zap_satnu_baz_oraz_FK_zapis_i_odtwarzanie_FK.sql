/* maciej.stodolski@gmail.com  Administrowanie Bazami Danych Z1 04.10.2021 */

/* Z1
** Stworzymy narzędzia
** 0) Tabele/procedury mają działać dla wszyskich baz na naszym serwerze
**   dlatego można stworzyć specjalną bazę lub użyć DB_STAT - jak ja
** Narzędzia mają służyć do (wszystko procedurami SQL zapamiętanymi na uprzednio wspomnianej bazie):
** WA) Zapamiętywania stanu bazy
** - liczby rekordów
** - indeksow w tabeli
** - kluczy obcych
** WB) Ma być możliwość skasowania wszystkich kluczy obcych za pomocą procedury
**   W zadanie bazie !!!
**   Taka procedure ma najpierw zapamietac w tabeli jakie są klucze
**   a potem je skasowac
** WC) Ma być możliwość odtworzenia kluczy obcych procedurą na wybranej bazie
**  podajemy według jakiego stanu (ID stanu) jak NULL to 
**  - procedura szuka ostatniego stanu dla tej bazy i odtwarza ten stan
** Sprawozdanie umieszczmy w iSOD do 25.10.2020 do godziny 20.00 w kolumnie Z1
** Sprawozdanie w PDF lub pliku Z1_num_indeksu_imie_nazw(bez PL znakow).sql:
** Opis wymagan
** Opis sposobu realizacji
** Kod SQL z komentarzami
** Dowód ze dziala (np zapamietany stan liczby wierszy w bazie, skasowane klucze obce,odtworzone według stanu X)
*/

/*
CREATE DATABASE DB_STAT
*/
IF NOT EXISTS (SELECT d.name 
					FROM sys.databases d 
					WHERE	(d.database_id > 4) -- systemowe mają ID poniżej 5
					AND		(d.[name] = N'DB_STAT')
)
BEGIN
	CREATE DATABASE DB_STAT
END
GO

USE DB_STAT
GO

IF NOT EXISTS 
(	SELECT 1
		from sysobjects o (NOLOCK)
		WHERE	(o.[name] = N'DB_STAT')
		AND		(OBJECTPROPERTY(o.[ID],N'IsUserTable')=1)
)
BEGIN
	/* czyszczenie jak trzeba od nowa
		DROP TABLE DB_RCOUNT
		DROP TABLE DB_STAT
	*/
	/*
	Szukanie ostatniego stat_id dla ostatniego zrzutu kluczy
	SELECT MAX(o.stat_id)
		FROM DB_STAT o
		WHERE o.[db_nam] = @jaka_baza
		AND EXISTS ( SELECT 1 FROM db_fk f WHERE f.stat_id = o.stat_id)
	*/
	CREATE TABLE dbo.DB_STAT
	(	stat_id		int				NOT NULL IDENTITY /* samonumerująca kolumna */
			CONSTRAINT PK_DB_STAT PRIMARY KEY
	,	[db_nam]	nvarchar(20)	NOT NULL
	,	[comment]	nvarchar(20)	NOT NULL
	,	[when]		datetime		NOT NULL DEFAULT GETDATE()
	,	[usr_nam]	nvarchar(100)	NOT NULL DEFAULT USER_NAME()
	,	[host]		nvarchar(100)	NOT NULL DEFAULT HOST_NAME()
	)
END
GO

USE DB_STAT
GO

IF NOT EXISTS 
(	SELECT 1 
		from sysobjects o (NOLOCK)
		WHERE	(o.[name] = N'DB_RCOUNT')
		AND		(OBJECTPROPERTY(o.[ID], N'IsUserTable')=1)
)
BEGIN
	CREATE TABLE dbo.DB_RCOUNT
	(	stat_id		int				NOT NULL CONSTRAINT FK_DB_STAT__RCOUNT FOREIGN KEY
											REFERENCES dbo.DB_STAT(stat_id)
	,	[table]		nvarchar(100)	NOT NULL
	,	[RCOUNT]	int				NOT NULL DEFAULT 0
	,	[RDT]		datetime		NOT NULL DEFAULT GETDATE()
	)
END
GO

USE DB_STAT
GO

/* stworzyć tabelę do przechowywania kluczy obcych na bazie */
IF NOT EXISTS 
(	SELECT 1 
		from sysobjects o (NOLOCK)
		WHERE	(o.[name] = N'DB_FK')
		AND		(OBJECTPROPERTY(o.[ID], N'IsUserTable')=1)
)
BEGIN
	SELECT N'tu tworzymy tabelę z tyloma kolumnami ile trzeba aby odtworzyć klucze obce' AS [msg]

	CREATE TABLE dbo.DB_FK
	(	stat_id		int		NOT NULL CONSTRAINT FK_DB_STAT__FK FOREIGN KEY
											REFERENCES dbo.DB_STAT(stat_id)
	,  constraint_name nvarchar(100)	NOT NULL
	,   referencing_table_name nvarchar(100)	NOT NULL -- Z jakiej tabeli klucz obcy
	,   referencing_column_name nvarchar(100)	NOT NULL --  z jakiej kolumny
	,   referenced_table_name nvarchar(100)	    NOT NULL -- do jakiej tabeli klucz obcy
	,   referenced_column_name nvarchar(100)	NOT NULL -- nazwa kolumny w tabeli do ktorej sie odwojujemy
	,  [RDT]		datetime		NOT NULL DEFAULT GETDATE() -- stepel czasowy
	)
	/* przykładowe zapytanie dla kluczy obcych na wybranej bazie */

END
GO

USE DB_STAT 
GO

/* stworzyć procedurę do przechowywania liczby wierszy w wybranej bazie */
IF NOT EXISTS 
(	SELECT 1 
		from sysobjects o (NOLOCK)
		WHERE	(o.[name] = 'DB_TC_STORE')
		AND		(OBJECTPROPERTY(o.[ID],'IsProcedure')=1)
)
BEGIN
	DECLARE @stmt nvarchar(100)
	SET @stmt = 'CREATE PROCEDURE dbo.DB_TC_STORE AS '
	EXEC sp_sqlexec @stmt
END
GO

USE DB_STAT
GO

ALTER PROCEDURE dbo.DB_TC_STORE (@db nvarchar(100), @commt nvarchar(20) = '<unkn>')
AS
	DECLARE @sql nvarchar(2000) -- tu będzie polecenie SQL wstawiajace wynik do tabeli
	,		@id int -- id nadane po wstawieniu rekordu do tabeli DB_STAT 
	,		@tab nvarchar(256) -- nazwa kolejne tabeli
	,		@cID nvarchar(20) -- skonwertowane @id na tekst
	
	SET @db = LTRIM(RTRIM(@db)) -- usuwamy spacje początkowe i koncowe z nazwy bazy

	/* wstawiamy rekord do tabeli DB_STAT i zapamiętujemy ID jakie nadano nowemu wierszowi */
	INSERT INTO DB_STAT.dbo.DB_STAT (comment, db_nam) VALUES (@commt, @db)
	SET  @id = SCOPE_IDENTITY() -- jakie ID zostało nadane wstawionemu wierszowi
	/* tekstowo ID aby ciągle nie konwetować w pętli */
	SET @cID = RTRIM(LTRIM(STR(@id,20,0)))

	/* przechodzimy do wybranej bazy */
/* niepotrzebne, nie dziala
	SET @sql = 'USE ' + @db
	EXEC sp_sqlexec @sql
*/
	CREATE TABLE #TC ([table] nvarchar(100) )

	/* w procedurze sp_sqlExec USE jakas_baza tymczasowo przechodzi w ramach polecenia TYLO */
	SET @sql = N'USE [' + @db + N']; INSERT INTO #TC ([table]) '
			+ N' SELECT o.[name] FROM sysobjects o '
			+ N' WHERE (OBJECTPROPERTY(o.[ID], N''isUserTable'') = 1)'
	/* for debug reason not execute but select */
	-- SELECT @sql 
	EXEC sp_sqlexec @sql

	-- SELECT * FROM #TC

	/* kursor po wszystkich tabelach uzytkownika */
	DECLARE CC INSENSITIVE CURSOR FOR 
			SELECT o.[table]
				FROM #TC o
				ORDER BY 1

	OPEN CC -- stoimi przed pierwszym wierszem wyniu
	FETCH NEXT FROM CC INTO @tab -- NEXT ->przejdz do kolejnego wiersza i pobierz dane
								-- do zmiennych pamięciowych

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		SET @sql = N'USE [' + @db + N']; '
					+ N' INSERT INTO DB_STAT.dbo.DB_RCOUNT (stat_id,[table],rcount) SELECT '
					+ @cID 
					+ ',''' + RTRIM(@tab) + N''', COUNT(*) FROM [' +@db + ']..' + RTRIM(@tab)
		EXEC sp_sqlexec @sql
/*
USE [pwx_db]; 
--INSERT INTO DB_STAT.dbo.DB_RCOUNT (stat_id,[table],rcount) 
 SELECT  'etaty', COUNT(*) FROM [pwx_db]..etaty
*/
		--SELECT @sql as syntax
		/* przechodzimy do następnej tabeli */
		FETCH NEXT FROM CC INTO @tab
	END
	CLOSE CC
	DEALLOCATE CC
GO

/* test procedury */

EXEC DB_STAT.dbo.DB_TC_STORE @commt = 'test', @db = N'pwx_db'

SELECT * FROM DB_STAT
/*
stat_id     db_nam               comment              when                    usr_nam                                                                                              host
----------- -------------------- -------------------- ----------------------- ---------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------
1           pwx_db               test                 2021-10-04 15:18:42.717 dbo                                                                                                  MS-SOFT-TOSH

(1 row(s) affected)
*/

SELECT * FROM DB_STAT.dbo.DB_RCOUNT where stat_id = 1
/*
stat_id     table                                                                                                RCOUNT      RDT
----------- ---------------------------------------------------------------------------------------------------- ----------- -----------------------
1           CECHY                                                                                                2           2021-10-04 15:18:42.757
1           etaty                                                                                                10          2021-10-04 15:18:42.760
1           firmy                                                                                                3           2021-10-04 15:18:42.763
1           FIRMY_CECHY                                                                                          6           2021-10-04 15:18:42.763
1           miasta                                                                                               4           2021-10-04 15:18:42.767
1           osoby                                                                                                5           2021-10-04 15:18:42.770
1           sysdiagrams                                                                                          0           2021-10-04 15:18:42.770
1           WARTOSCI_CECH                                                                                        5           2021-10-04 15:18:42.773
1           woj                                                                                                  3           2021-10-04 15:18:42.777

(9 row(s) affected)

*/



/* mozna zrobić kursor po bazach i w petli wołąc procedurę i mieć zrzut dla wszystkich baz */

--SELECT d.name FROM sys.databases d WHERE d.database_id > 4 -- ponizej 5 są systemowe

USE DB_STAT
GO

/* Można stworzyć procedurę do przechowywania liczby wierszy w KAZDEJ !!! bazie */
IF NOT EXISTS 
(	SELECT 1 
		from sysobjects o (NOLOCK)
		WHERE	(o.[name] = 'DB_STORE_ALL')
		AND		(OBJECTPROPERTY(o.[ID],'IsProcedure')=1)
)
BEGIN
	DECLARE @stmt nvarchar(100)
	SET @stmt = 'CREATE PROCEDURE dbo.DB_STORE_ALL AS '
	EXEC sp_sqlexec @stmt
END
GO


USE DB_STAT
GO
-- dla wszytkich baz
ALTER PROCEDURE dbo.DB_STORE_ALL (@commt nvarchar(20) = N'<all>')
AS
	DECLARE CCA INSENSITIVE CURSOR FOR
			SELECT d.name 
			FROM sys.databases d 
			WHERE d.database_id > 4 -- ponizej 5 są systemowe
	DECLARE @db nvarchar(100)
	OPEN CCA
	FETCH NEXT FROM CCA INTO @db

	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC DB_STAT.dbo.DB_TC_STORE @commt = 'test', @db = @db
		FETCH NEXT FROM CCA INTO @db
	END
	CLOSE CCA
	DEALLOCATE CCA
GO

/* 
bezpieczne podglądanie pracy procedury:
1. Otwieramy nowe okno i wpisujemy 
SELECT * FROM DB_STAT (NOLOCK) 

SELECT * FROM DB_STAT.dbo.DB_RCOUNT (NOLOCK) WHERE stat_id=3
-- 3 bo takie ID chialem podejrzec

/* 
-- usuwanie klucza
ALTER TABLE NazwaTabeli DROP CONSTRAINT NazwaOgr

-- dodawanie kluczy do tabeli
USE baza;
ALTER TABLE dbo.nazwa_tabeli ADD CONSTRAINT nazwa_klucza FOREIGN KEY (kolumna) REFERENCES MasterTabela(kolumna_w_master)

*/
*/
Use DB_STAT

select *
from DB_STAT i

