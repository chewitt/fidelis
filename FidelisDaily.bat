rem Script for Daily maintenance of Fidelis Endpoint management DB when
rem deployed with MS SQL Express. This is not part of a Fidelis product
rem and is provided as-is with no warranty!. Please have an experienced
rem DBA review the script before implementing.

sqlcmd -S SERVER\FIDELIS_ENDPOINT -i"C:\SQLMAINT\FidelisDaily.sql"
