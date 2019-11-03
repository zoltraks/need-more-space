
--
-- Create database catalog
--

IF NOT EXISTS ( SELECT 1 FROM sys.sysdatabases WHERE [name] = 'ContactList' )
CREATE DATABASE [ContactList]
--ON PRIMARY
--( NAME = N'ContactList' , FILENAME = N'C:\DATA\Microsoft SQL Server\DATA\ContactList.mdf' , SIZE = 2048KB , FILEGROWTH = 1024KB )
--LOG ON
--( NAME = N'ContactList_log' , FILENAME = N'C:\DATA\Microsoft SQL Server\LOG\ContactList_log.ldf' , SIZE = 1024KB , FILEGROWTH = 1024KB )
;

GO
