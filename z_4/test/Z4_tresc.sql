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

USE DB_STAT 
GO

IF NOT EXISTS 
(	select o.name AS tabelaDetail, i.name AS nazwa_klucza /* nazwę kolumny */
		from sysindexes i
		join sysobjects o ON (o.[id] = i.[id])
		WHERE o.[name] = N'DB_STAT')
BEGIN
	CREATE INDEX FKI_DB_STAT__DB_RCOUNT ON DB_RCOUNT(stat_id)
END
GO

SELECT * 
	FROM DB_RCOUNT d  WITH (INDEX(FKI_DB_STAT__DB_RCOUNT)) 
	WHERE d.stat_id=2

use DB_STAT
SELECT i.name AS index_name
    ,COL_NAME(ic.object_id,ic.column_id) AS column_name
    ,ic.index_column_id
    ,ic.key_ordinal
,ic.is_included_column
FROM sys.indexes AS i
INNER JOIN sys.index_columns AS ic
    ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID('DB_RCOUNT')



