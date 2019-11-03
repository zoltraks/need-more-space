
--
-- Drop database catalog
--

IF EXISTS ( SELECT 1 FROM sys.sysdatabases WHERE [name] = 'ContactList' )
ALTER DATABASE [ContactList] SET SINGLE_USER WITH ROLLBACK IMMEDIATE ;

GO

IF EXISTS ( SELECT 1 FROM sys.sysdatabases WHERE [name] = 'ContactList' )
DROP DATABASE [ContactList] ;

GO
