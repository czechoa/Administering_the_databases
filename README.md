# Administering_the_databases
Common tasks in ms SQL databaase

Taks
===========

Foreign keys
---------
1. Create a table to store ALL foreign keys in a given database
2. Create a procedure to remember all aliens using the tables - see item 1
3. Procedure for deleting foreign keys - first start the procedure from point 2 and then delete the keys
4. Writing a procedure to recreate the last saved foreign keys

Backup of all databases
---------
1. bk_db - single database backup (database name and directory)
2. bk_all_db - backup of all databases (directory name)
3. Schedule backups of all databases to run through

LOG for critical data and comparison of the LOG with the content of the reconstructed database backup
---------

Creating indexes to foreign keys (for the relationship MASTER -> DETAIL)
---------
1. Select all columns from the database (and the names of the tables in which they are located and the names of the tables they refer to - for the purpose of naming the key)
2. But only those columns for which there are no indexes yet
3. Only for columns from 2 we create indexes

Procedure for deleting a restricted column
---------
1. We check if the column exists
2. As there is, we check if there are certain limitations (e.g. DEFAULT was founded)
3. How YES - we remove restrictions
4. We remove the columns
