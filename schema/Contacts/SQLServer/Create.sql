
--
-- Create database
--

IF NOT EXISTS ( SELECT 1 FROM sys.sysdatabases WHERE [name] = 'Contacts' )
CREATE DATABASE [Contacts]
--ON PRIMARY
--( NAME = N'Contacts' , FILENAME = N'C:\DATA\Microsoft SQL Server\DATA\Contacts.mdf' , SIZE = 2048KB , FILEGROWTH = 1024KB )
--LOG ON
--( NAME = N'Contacts_log' , FILENAME = N'C:\DATA\Microsoft SQL Server\LOG\Contacts_log.ldf' , SIZE = 1024KB , FILEGROWTH = 1024KB )
;

GO
