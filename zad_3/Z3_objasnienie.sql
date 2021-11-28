/*

1. Tworzycie Państwo bazę z min 3 tabelami
Wszystie pola NOT NULL
klient(id_klienta int IDENTITY, NIP  nvarchar(20), nazwa nvarcar(100), adres nvarchar(100))
Faktura(id_faktury int IDENTITY, id_klienta int, data datetime, numer, anulowana bit)
Pozycje(id_faktury, opis, cena)

2. W Waszej bazie administracyjnej tworzycie tabelę 
LOG_FA(numer_faktry,nip_klienta,data,anulowana)

3. Piszecie triger do Faktury który zapamiętuje wystawianą fakturę w powyzszej bazie
do LOG_FA wpisuje dane: (numer_faktry,nip_klienta,data,anulowana) - trigger na INSERT to FAKTURY
Oraz TRIGGER na UPDATE w przypadku jak zmieni się wartość pola ANULOWANE (zakładamy, ze pozostałe pola
nie mogą się zmienić: numer_faktry,nip_klienta,data
Jedye pole które może się zmienić po INSERT do FAKTURY to własnie ANULOWANA

CREATE TRIGGER UPD_FA FOR Faktura ON UPDATE
AS
	IF UPDATE(anulowana) -- update dotyczył tego pola
	AND ( SELECT 1 FROM inserted i join deleted d ON (i.id_faktury = d.id_faktury )
			WHERE NOT (i.ANULOAWANA = d.anulowana)
			
	) INSERT INTO LOG_FA .....,anuloawan) SELECT ...,i.anulowana FROM inserted i join deleted d ON (i.id_faktury = d.id_faktury )
			WHERE NOT (i.ANULOAWANA = d.anulowana)

Powyższy fragment triggera czy była zmiana na polu ANULOWANA
	
Pamietajmy pisząc trigger aby
- sprawdzal TYLKO modyfikowane rekordy
- zakladal, ze wstawiamy/modyfikujemy wiele rekordów na raz
(tabele inserted - nowe dane, deleted - stare dane
- porowanie czy zmiana NIP w klient: trigger na klient porównujący inserted.nip z deleted.nip
  złączenie po id_klienta,
  inserted z deleted po kluczu tabeli złączamy
)

4. Trigger do zapamietania Faktury INSERT - zapamiętuje jaka wystawiona faktura
i zapisuje do LOG_FA 
- w triggerze musi być zaytanie z inserted (to Faktury) połaczone z Klient (NIP)
 
5. Test
- wstawiacie minimum 6 faktur i 3 klientów
- robicie backup bazy (mozna procedurą lub dowolnie)
- dodajecie 3 faktury i 1 klienta
- odtwarzacie backup pod nazwą BK_XX 
- robicie procedurę/zapytanie pokazujące co jest w LOGU a czego nie ma w bazie BK_XX
Jeśli procedura to przekazjecie nazwe bazy z odtworzony backupem


6. dokumentacja w PDF z kodami (na koncu)
- opisujecie jak dziala
- piszecie dokument techniczny nie dla mnie ale dla przyszłego administratora/opiekuna procesu

- opisac odtworzenie bazy z pliku
- opisac jak wylapac czego nie ma w bazie
- opisac jak dziala proces caly

*/
