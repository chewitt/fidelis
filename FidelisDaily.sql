/* 

Script for Daily maintenance of Fidelis Endpoint management DB when
deployed with MS SQL Express. This is not part of a Fidelis product
and is provided as-is with no warranty!. Please have an experienced
DBA review the script before implementing.

*/

SET QUOTED_IDENTIFIER ON;

-- Set the DB name:
USE [Fidelis];

-- FileZoo Maintenance:
DELETE FROM [FileZoo] WHERE [ReportingDate] < DATEADD(DAY, -90, GETDATE());
DELETE FROM [FileZoo] WHERE [ReportingFileName] = 'script.vbs';

-- Alerts Maintenance:
DELETE FROM [Alerts] WHERE [CreateDate] < DATEADD(DAY, -90, GETDATE());
