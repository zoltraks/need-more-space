
--
-- Delete table structure
--

IF OBJECT_ID('dbo.[Contact]' , 'U') IS NOT NULL
DROP TABLE dbo.[Contact] ;

IF OBJECT_ID('dbo.[MessengerAccount]' , 'U') IS NOT NULL
DROP TABLE dbo.[MessengerAccount] ;

IF OBJECT_ID('dbo.[MessengerService]' , 'U') IS NOT NULL
DROP TABLE dbo.[MessengerService] ;
