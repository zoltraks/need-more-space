
--
-- Create table structure
--

CREATE TABLE IF NOT EXISTS "Contact" (
  "Id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,

  "Title" TEXT,
  "FirstName" TEXT,
  "SecondName" TEXT,
  "LastName" TEXT
) ;

CREATE TABLE IF NOT EXISTS "MessengerAccount" (
  "Id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,

  "ContactId" INTEGER NOT NULL ,
  "MessengerServiceId" INTEGER NULL ,
  "AccountName" TEXT,
  "CustomServiceName" TEXT,
  "DisplayOrder" INTEGER DEFAULT 0
) ;

CREATE TABLE IF NOT EXISTS "MessengerService" (
  "Id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,

  "ServiceName" TEXT NOT NULL ,
  "AccountFormat" TEXT ,
  "DisplayOrder" INTEGER DEFAULT 0
) ;
