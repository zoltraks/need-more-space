Microsoft SQL Server
====================

Every stored procedure has at least one parameter **@Help** which may be used to display usage information.

You may also find **@Pretend** parameter useful to check what SQL query will be used to produce results.

Have fun.

[Installation script for all functions **SQLServer-All.sql** →](../../sql/SQLServer-All.sql)

Simple check if scripts are working correctly.

```sql
EXEC x_SystemVersion
```

```sql
EXEC dbo.x_SystemVersion
```

```sql
EXEC [DBAtools].dbo.x_SystemVersion
```

You may also remove all installed functions by using **SQLServer-Purge.sql** script.

[Script for removing all functions **SQLServer-Purge.sql** →](../../sql/SQLServer-Purge.sql)

[↑ Up ↑](#microsoft-sql-server)

Maintenance Tips
----------------

[↑ Up ↑](#microsoft-sql-server)

## Basic configuration

```sql
SELECT  
  SERVERPROPERTY('MachineName') AS Computer
  ,
  SERVERPROPERTY('ServerName') AS Instance
  , 
  SERVERPROPERTY('Collation') AS Collation
```

## Default paths

```sql
SELECT 
  DefaultDataPath = SERVERPROPERTY('InstanceDefaultDataPath')
  ,
  DefaultLogPath = SERVERPROPERTY('InstanceDefaultLogPath')
  ,
  DefaultBackupPath = SERVERPROPERTY('InstanceDefaultBackupPath')
```

[↑ Up ↑](#microsoft-sql-server)

Database Preparation
--------------------

[↑ Up ↑](#microsoft-sql-server)

You may skip this option if you already have database catalog needed for installation scripts.

Or you might choose to follow some of following examples to create **[monitor]** user and **[DBAtools]** catalog with desired configuration.

### Catalog ###

It is recommended to create separate database catalog like **DBAtools** for utility scripts.

``` 
CREATE DATABASE [DBAtools] ON PRIMARY 
( NAME = N'DBAtools', FILENAME = N'C:\DATA\Microsoft SQL Server\DBAtools.mdf'
, SIZE = 2048KB , FILEGROWTH = 10240KB )
LOG ON 
( NAME = N'DBAtools_log', FILENAME = N'C:\DATA\Microsoft SQL Server\DBAtools_log.ldf'
, SIZE = 1024KB , FILEGROWTH = 10240KB )
```

### User ###

```sql
CREATE LOGIN [monitor] WITH PASSWORD=N'SecretPassword', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
```

```sql
CREATE USER [monitor] FOR LOGIN [monitor]
```

To change password for existing user use this example.

```sql
ALTER LOGIN [monitor] WITH PASSWORD=N'Secret123'
```

Enable **Activity Monitor** in **SQL Server Management Studio**.

```sql
GRANT VIEW SERVER STATE TO [monitor]
```

Allow trace in **SQL Server Profiler**. 

```sql
GRANT ALTER TRACE TO [monitor]
```

Enable advanced monitoring usage.

```sql
USE [model]
GO
CREATE USER [monitor] FOR LOGIN [monitor]
GO
USE [msdb]
GO
CREATE USER [monitor] FOR LOGIN [monitor]
GO
USE [msdb]
GO
ALTER ROLE [db_datareader] ADD MEMBER [monitor]
GO
```

### Owner ###

Probably better to have different user like **[dba]** for operational access and this user should be owner of **[DBAtools]** database. For other users like **[monitor]** execution permission permission should be granted (sww below).

Unsafe, but if you still need, here you have a template.

```sql
USE [DBAtools]
GO
CREATE USER [monitor] FOR LOGIN [monitor]
ALTER ROLE [db_owner] ADD MEMBER [monitor]
```

### Access ###

Additional execution permissions may be needed for users.

```sql
GRANT EXECUTE ON [DBAtools].dbo.x_CopyData TO [monitor]
GRANT EXECUTE ON [DBAtools].dbo.x_DefaultConstraint TO [monitor]
GRANT EXECUTE ON [DBAtools].dbo.x_FileConfiguration TO [monitor]
GRANT EXECUTE ON [DBAtools].dbo.x_FindDuplicates TO [monitor]
GRANT EXECUTE ON [DBAtools].dbo.x_IdentitySeed TO [monitor]
GRANT EXECUTE ON [DBAtools].dbo.x_OperationStatus TO [monitor]
GRANT EXECUTE ON [DBAtools].dbo.x_ShowIndex TO [monitor]
GRANT EXECUTE ON [DBAtools].dbo.x_ShowIndexColumn TO [monitor]
GRANT EXECUTE ON [DBAtools].dbo.x_SystemMemory TO [monitor]
GRANT EXECUTE ON [DBAtools].dbo.x_SystemVersion TO [monitor]
```

```sql
GRANT SELECT ON [DBAtools].dbo.v_WaitType TO [monitor]
```

### Check ###

```sql
EXEC dbo.x_SystemVersion
```

[↑ Up ↑](#microsoft-sql-server)

Show index column
-----------------

[↑ Up ↑](#microsoft-sql-server)

[Installation script for x_ShowIndexColumn →](../../sql/SQLServer/x_ShowIndexColumn.sql)

Show index columns for tables in database.

``` 
EXEC x_ShowIndexColumn @Help = 1 ;
```

| Parameter | Type | Description |                                                            
| --------- | ---- | ----------- |
| @Database | NVARCHAR(128) | Database name |
| @Schema | NVARCHAR(128) | Schema name |
| @Table | NVARCHAR(128) | Table name |
| @Clustered | BIT | Show only clustered or nonclustered indexes |
| @Unique | BIT | Show only unique or nonunique indexes |
| @Primary | BIT | Show only primary or nonprimary indexes |
| @Pretend | BIT | Print query to be executed but don't do anything |
| @Help | BIT | Show this help |

``` 
EXEC x_ShowIndexColumn @Pretend = 1 ;
```

```sql
SELECT
    [Schema] = s.name , [Table] = t.name , [Index] = i.name , [Column] = c.name
    ,
    [Clustered] = CASE WHEN i.index_id = 1 THEN 1 ELSE 0 END , [Unique] = i.is_unique , [Primary] = i.is_primary_key
FROM
    sys.tables t
INNER JOIN 
    sys.indexes i ON t.object_id = i.object_id
INNER JOIN 
    sys.index_columns ic ON i.index_id = ic.index_id AND i.object_id = ic.object_id
INNER JOIN 
    sys.columns c ON ic.column_id = c.column_id AND ic.object_id = c.object_id
INNER JOIN
    sys.schemas s ON t.schema_id = s.schema_id
WHERE
    i.name IS NOT NULL
ORDER BY
    s.name , t.name , i.name
```

``` 
EXEC x_ShowIndexColumn ;
```

| Schema | Table | Index | Column | Clustered | Unique | Primary |
| ------ | ----- | ----- | ------ | --------- | ------ | ------- |
| dbo | BlitzCache | PK_EB450450-26B6-4AB4-AFF3-4D773F3C5C38 | ID | 1 | 1 | 1 |
| dbo | BlitzFirst | PK__BlitzFir__3214EC270DAF0CB0 | ID | 1 | 1 | 1
| dbo | BlitzFirst_FileStats | PK__BlitzFir__3214EC27117F9D94 | ID | 1 | 1 | 1 |
| dbo | BlitzFirst_PerfmonStats | PK__BlitzFir__3214EC27164452B1 | ID | 1 | 1 | 1 |
| dbo | BlitzFirst_WaitStats | IX_ServerName_wait_type_CheckDate_Includes | ServerName | 0 | 0 | 0 |
| dbo | BlitzFirst_WaitStats | IX_ServerName_wait_type_CheckDate_Includes | wait_type | 0 | 0 | 0 |
| dbo | BlitzFirst_WaitStats | IX_ServerName_wait_type_CheckDate_Includes | CheckDate | 0 | 0 | 0 |
| dbo | BlitzFirst_WaitStats | IX_ServerName_wait_type_CheckDate_Includes | wait_time_ms | 0 | 0 | 0 |
| dbo | BlitzFirst_WaitStats | IX_ServerName_wait_type_CheckDate_Includes | signal_wait_time_ms | 0 | 0 | 0 |
| dbo | BlitzFirst_WaitStats | IX_ServerName_wait_type_CheckDate_Includes | waiting_tasks_count | 0 | 0 | 0 |
| dbo | BlitzFirst_WaitStats | PK__BlitzFir__3214EC271BFD2C07 | ID | 1 | 1 | 1 |
| dbo | CommandLog | PK_CommandLog | ID | 1 | 1 | 1 |

[↑ Up ↑](#microsoft-sql-server)

Operation status
----------------

[↑ Up ↑](#microsoft-sql-server)

[Installation script for x_OperationStatus →](../../sql/SQLServer/x_OperationStatus.sql)

Show system operation status.

Simply display what database server is doing now.

This procedure has no relevant parameters.

``` 
EXEC x_OperationStatus ;
```

| Database | Command | Status | % | Wait type | Start time | Reads | Writes | Time taken | CPU Time | Time left | Session | Query text |                      
| -------- | ------- | ------ | - | --------- | ---------- | ----- | ------ | ---------- | -------- | --------- | ------- | ---------- |         
| master | RESTORE&nbsp; DATABASE | suspended | 5.60 | BACKUPTHREAD | 2019-11-01 09:52:34.973 | 2 | 0 | 00:50 | 00:00 | 14:03 | 87 | RESTORE DATABASE [ExampleTemp] FROM  DISK = N'E:\SQLBackups\Example\Example_backup_2019_10_30_160003_0084574.tlog' WITH  FILE = 2, MOVE N' Example' TO N'E:\Temp\ExampleTemp.mdf', MOVE N' Example_log' TO N'E:\Temp\ExampleTemp_log.ldf', NORECOVERY, NOUNLOAD, REPLACE, STATS = 10 | 
| master | SELECT | suspended | 0.00 | TRACEWRITE | 2019-11-01 07:40:00.500 | 0 | 0 | 33:25 | 00:00 | 00:00 | 76 | create procedure sys.sp_trace_getdata | (@traceid int, |  @records int = 0 | )asselect * from OpenRowset(TrcData, @traceid, @records) | 
|  ExampleTemp | UPDATE | suspended | 0.00 | WRITELOG | 2019-11-01 09:53:25.357 | 0 | 0 | 00:00 | 00:00 | 00:00 | 71 | (@data datetime)UPDATE SomeTable SET stamp=@data WHERE id = 229074 | 
| ExampleTemp | CONDITIONAL | running | 0.00 | NULL | 2019-11-01 10:08:10.717 | 0 | 0 | 00:00 | 00:00 | 00:00 | 97 | IF NOT EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA. COLUMNS WHERE TABLE_NAME = 'ExampleTable' AND COLUMN_NAME = 'MissingColumn' ) | ALTER TABLE [ExampleTable] ADD [MissingColumn] FLOAT NULL... 
| ExampleTemp | ALTER TABLE | running | 0.00 | NULL | 2019-11-01 10:08:12.067 | 713075 | 1884865 | 02:16 | 01:46 | 00:00 | 97 | UPDATE [ExampleTemp].[dbo].[ExampleTable] SET [CounterColumn] = [CounterColumn] | 
| OtherDb | CONDITIONAL | suspended | 0.00 | PAGEIOLATCH_SH | 2019-11-01 10:16:00.437 | 47445 | 0 | 00:14 | 00:00 | 00:00 | 97 | IF EXISTS ( SELECT TOP 1 1 FROM [a_batch] WHERE [stamp] IS NULL ) UPDATE [a_batch] SET [stamp] = GETDATE()... | 

Identity seed
------------------

Show identity seed value for tables in database.

Generate report for all tables and identity column seed value together
with DBCC CHECKIDENT ( '[table]' , RESEED , 434342 ) script pattern to recreate it manually.

```sql
EXEC x_IdentitySeed @Help = 1 ;
```

```sql
EXEC x_IdentitySeed @Database = 'DbName' ;
```

[↑ Up ↑](#microsoft-sql-server)

Find duplicates
---------------

[↑ Up ↑](#microsoft-sql-server)

[Installation script for x_FindDuplicates →](../../sql/SQLServer/x_FindDuplicates.sql)

Find duplicates in table.

``` 
EXEC x_FindDuplicates @Help = 1 ;
```

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| @Table | NVARCHAR(515) | Table name |
| @Columns | NVARCHAR(MAX) | Column list separated by comma, semicolon or whitespace (i.e."col1, [Other One] , col2") |
| @Expand | NVARCHAR(MAX) | Expand results by including additional columns for duplicated records |
| @Where | NVARCHAR(MAX) | Optional filter for WHERE |
| @Top | INT | Maximum count of rows |
| @Pretend | BIT | Print query to be executed but don't do anything |
| @Help | BIT | Show this help |

``` 
EXEC x_FindDuplicates @Table = 'MyDb.dbo.MyTable' , @Columns = 'column1 , [Other One] , Col3' , @Pretend = 1 ;
```

```sql
SELECT
    [column1] , [Other One] , [Col3]
    ,
    [Count] = COUNT(*)
FROM
    MyDb.dbo.MyTable
GROUP BY
    [column1] , [Other One] , [Col3]
HAVING
    COUNT(*) > 1
ORDER BY
    [column1] , [Other One] , [Col3]
```

You may want to expand your results by showing each duplicate record for further analysis.

``` 
EXEC x_FindDuplicates @Table = 'MyDb.dbo.MyTable' , @Columns = 'year,day' , @Expand = 'id , stamp' , @Pretend = 1 ;
```

```sql
WITH __X__ AS
(
    SELECT
    [year] , [day]
    FROM
        MyDb.dbo.MyTable
    GROUP BY
        [year] , [day]
    HAVING
        COUNT(*) > 1
)
SELECT
    __X__.* , __Y__.[id] , __Y__.[stamp]
FROM
    __X__
LEFT JOIN
    MyDb.dbo.MyTable __Y__ ON __X__.[year] = __Y__.[year] AND __X__.[day] = __Y__.[day]
ORDER BY
    __X__.[year] , __X__.[day] , __Y__.[id] , __Y__.[stamp]
```

[↑ Up ↑](#microsoft-sql-server)

File configuration
------------------

[↑ Up ↑](#microsoft-sql-server)

[Installation script for x_FileConfiguration →](../../sql/SQLServer/x_FileConfiguration.sql)

Show database files configuration.

``` 
EXEC x_FileConfiguration @Help = 1 ;
```

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| @Database | NVARCHAR(257) | Database name | 
| @Pretend | BIT | Print query to be executed but don't do anything |
| @Help | BIT | Show this help |

``` 
EXEC x_FileConfiguration @Database = 'TempDB' , @Pretend = 1 ;
```

```sql
SELECT
    [Name] = [name]
    ,
    [Size (MB)] = CONVERT(INT , [size] / 128.0)
    ,
    [Autogrowth] = CASE [max_size] WHEN 0 THEN 'OFF' WHEN -1 THEN 'UNLIMITED' ELSE 'LIMITED' END
    ,
    [Growth (MB)] = CASE WHEN [is_percent_growth] = 0 THEN CONVERT(BIGINT , [growth] / 128.0) ELSE 0 END
    ,
    [Growth (%)] = CASE WHEN [is_percent_growth] = 1 THEN CONVERT(INT , [growth]) ELSE 0 END
    ,
    [State] = [state_desc]
    ,
    [Limit (MB)] = CASE WHEN [max_size] <= 0 THEN [max_size] ELSE CONVERT(INT , [max_size] / 128.0 / 1024.0 ) END
    ,
    [Number] = [file_id]
    ,
    [Type] = CASE WHEN [type] = 0 THEN 'DATA' ELSE 'LOG' END
    ,
    [File] = [physical_name]
FROM
    [TempDB].sys.database_files
```

``` 
EXEC x_FileConfiguration @Database = 'TempDB' ;
```

| Name | Size (MB) | Autogrowth | Growth (MB) | Growth (%) | State | Limit (MB) | Number | Type | File |
| ---- | --------- | ---------- | ----------- | ---------- | ----- | ---------- | ------ | ---- | ---- |
| tempdev | 1278 | UNLIMITED | 10 | 0 | ONLINE | -1 | 1 | DATA | F:\DATABASE\TempDB\tempdev.mdf |
| templog | 50 | UNLIMITED | 10 | 0 | ONLINE | -1 | 2 | LOG | F:\DATABASE\TempDB\templog.ldf |
| tempdev02 | 1268 | UNLIMITED | 10 | 0 | ONLINE | -1 | 3 | DATA | F:\DATABASE\TempDB\tempdev02.mdf |
| tempdev03 | 1268 | UNLIMITED | 10 | 0 | ONLINE | -1 | 4 | DATA | F:\DATABASE\TempDB\tempdev03.mdf |
| tempdev04 | 1268 | UNLIMITED | 10 | 0 | ONLINE | -1 | 5 | DATA | F:\DATABASE\TempDB\tempdev04.mdf |
| tempdev05 | 1268 | UNLIMITED | 10 | 0 | ONLINE | -1 | 6 | DATA | F:\DATABASE\TempDB\tempdev05.mdf |
| tempdev06 | 1268 | UNLIMITED | 10 | 0 | ONLINE | -1 | 7 | DATA | F:\DATABASE\TempDB\tempdev06.mdf |
| tempdev07 | 1268 | UNLIMITED | 10 | 0 | ONLINE | -1 | 8 | DATA | F:\DATABASE\TempDB\tempdev07.mdf |
| tempdev08 | 1268 | UNLIMITED | 10 | 0 | ONLINE | -1 | 9 | DATA | F:\DATABASE\TempDB\tempdev08.mdf |
| tempdev09 | 1268 | UNLIMITED | 10 | 0 | ONLINE | -1 | 10 | DATA | F:\DATABASE\TempDB\tempdev09.mdf |
| tempdev10 | 1268 | UNLIMITED | 10 | 0 | ONLINE | -1 | 11 | DATA | F:\DATABASE\TempDB\tempdev10.mdf |
| tempdev11 | 1268 | UNLIMITED | 10 | 0 | ONLINE | -1 | 12 | DATA | F:\DATABASE\TempDB\tempdev11.mdf |
| tempdev12 | 1278 | UNLIMITED | 10 | 0 | ONLINE | -1 | 13 | DATA | F:\DATABASE\TempDB\tempdev12.mdf |
| tempdev01 | 1278 | UNLIMITED | 10 | 0 | ONLINE | -1 | 14 | DATA | F:\DATABASE\TempDB\tempdev01.mdf |

[↑ Up ↑](#microsoft-sql-server)

System memory
-------------

[↑ Up ↑](#microsoft-sql-server)

[Installation script for x_SystemMemory →](../../sql/SQLServer/x_SystemMemory.sql)

Show basic information about memory amount and state.

This procedure has no relevant parameters.

``` 
EXEC x_SystemMemory ;
```

| Physical memory (MB) | Available memory (MB) | Total page file (MB) | Available page file (MB) | System cache (MB) | Memory used (MB) | Memory state |
| -------------------- | --------------------- | -------------------- | ------------------------ | ----------------- | ---------------- | ------------ |
| 65535 | 5795 | 131069 | 70972 | 1435 | 56484 | Available physical memory is high |

System version
--------------

[Installation script for x_SystemVersion →](../../sql/SQLServer/x_SystemVersion.sql)

Show version information.

This procedure has no relevant parameters.

``` 
EXEC x_SystemVersion ;
```

| Name | Value |
| ---- | ----- |
| Version | 15.0.2000.5 |
| Product | Microsoft SQL Server 2019 (RTM) - 15.0.2000.5 (X64)   Sep 24 2019 13:48:23   Copyright (C) 2019 Microsoft Corporation  Developer Edition (64-bit) on Windows 10 Pro 10.0 <X64> (Build 18362: ) (Hypervisor) 
| Edition | Developer Edition (64-bit) |
| Level | RTM |

[↑ Up ↑](#microsoft-sql-server)

Default constraint
------------------

[↑ Up ↑](#microsoft-sql-server)

[Installation script for x_DefaultConstraint →](../../sql/SQLServer/x_DefaultConstraint.sql)

Show default constraint.

This procedure may be used to show default constraints for specific tables and columns.

``` 
EXEC x_DefaultConstraint @Help = 1 ;
```

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| @Database | NVARCHAR(128) | Database name |
| @Schema | NVARCHAR(128) | Schema name |
| @Table | NVARCHAR(128) | Table name |
| @Column | NVARCHAR(128) | Column name |
| @Constraint | NVARCHAR(128) | Constraint name |
| @Pretend | BIT | Print query to be executed but don't do anything |
| @Help | BIT | Show this help |

``` 
EXEC x_DefaultConstraint @Database = 'ContactList' , @Column = 'DisplayOrder' ;
```

| Schema | Table | Constraint | Column | Object | Create | Modify |
| ------ | ----- | ---------- | ------ | ------ | ------ | ------ |
| dbo | MessengerService | DF__Messenger__Displ__0519C6AF | DisplayOrder | 85575343 | 2019-11-03 14:29:17.890 | 2019-11-03 14:29:17.890 |

[↑ Up ↑](#microsoft-sql-server)

Copy data
---------

[↑ Up ↑](#microsoft-sql-server)

[Installation script for x_CopyData →](../../sql/SQLServer/x_CopyData.sql)

Copy data from one table to another.

Copying is made with simple query INSERT INTO ... SELECT FROM ... with full list of columns.

This procedure may optionally create destination table, drop it first, or delete existing data.

Will also work with linked servers.

``` 
EXEC x_CopyData @Help = 1 ;
```

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| @Pretend | BIT | Print queries to be executed but don't do anything. Will however read column definition from source table.|
| @Help | BIT | Show this help |
| @SourceDatabase | NVARCHAR(128) | Source database name. Optional.|
| @SourceSchema | NVARCHAR(128) | Source schema name. If omited, default "dbo" will be used.|
| @SourceTable | NVARCHAR(128) | Source table name. Required.|
| @SourceServer | NVARCHAR(128) | Source linked server. Optional.|
| @DestinationDatabase | NVARCHAR(128) | Destination database name. If not specified, source database name will be used.|
| @DestinationSchema | NVARCHAR(128) | Destination schema name. If omited, default "dbo" will be used.|
| @DestinationTable | NVARCHAR(128) | Destination table name. If not specified, source table name will be used.|
| @DestinationServer | NVARCHAR(128) | Destination linked server. Optional. Be aware that trying to create or drop table will require linked server to be configured for RPC.|
| @Copy | BIT | Copy data with simple query INSERT INTO ... SELECT FROM ... with full list of columns.|
| @Create | BIT | Create destination table if not exists.|
| @Drop | BIT | Drop destination table if exists.|
| @Delete | BIT | Delete data from destination table first.|
| @Where | NVARCHAR(2000) | Optional WHERE clausule for SELECT operation.|
| @IncludeIdentity | BIT | Include identity columns for copying.|
| @IncludeComputed | BIT | Include computed columns for copying. By default computed columns are not copied nor created.|
| @IdentityNullable | BIT | Force identity column to be nullable in create table script.|

Use pretend mode to see what will be done.

``` 
EXEC x_CopyData @SourceDatabase = 'MyDb' , @SourceTable = 'Table1' , @DestinationDatabase = 'Backup'
  , @Pretend = 1 ;
```

```sql
INSERT INTO [Backup].[dbo].[Table1]
( [id] , [ancestor] , [line] , [description] )
SELECT
  [id] , [ancestor] , [line] , [description]
FROM [MyDb].[dbo].[Table1]
```

This little trick allows to generate CREATE TABLE script only.

``` 
EXEC x_CopyData @Copy = 0 , @Create = 1 , @SourceTable='Table1' , @SourceDatabase = 'MyDb' , @Pretend = 1;
```

```sql
IF OBJECT_ID(N'[MyDb].[dbo].[Table1]') IS NULL
CREATE TABLE [MyDb].[dbo].[Table1]
(
  [id] BIGINT NOT NULL ,
  [ancestor] BIGINT NULL ,
  [line] SMALLINT NULL ,
  [description] NVARCHAR(50) NULL
)
```

You may also copy data between two servers.

``` 
EXEC x_CopyData @Pretend = 1 , @Copy = 1 , @Create = 1 , @Drop = 1 , @Delete = 1
    , @SourceDatabase='MyDb' , @SourceTable='Table1'
    , @DestinationServer='LinkedSrv' , @DestinationDatabase='Backup' ;
```

``` 
EXEC (N'
IF OBJECT_ID(N''[Backup].[dbo].[Table1]'') IS NOT NULL
DROP TABLE [Backup].[dbo].[Table1]
') AT [LinkedSrv]

EXEC (N'
IF OBJECT_ID(N''[Backup].[dbo].[Table1]'') IS NULL
CREATE TABLE [Backup].[dbo].[Table1]
(
  [id] BIGINT NULL ,
  [ancestor] BIGINT NULL ,
  [line] SMALLINT NULL ,
  [description] NVARCHAR(50) NULL
)
') AT [LinkedSrv]

DELETE FROM [LinkedSrv].[Backup].[dbo].[Table1]

INSERT INTO [LinkedSrv].[Backup].[dbo].[Table1]
( [id] , [ancestor] , [line] , [description] )
SELECT
  [id] , [ancestor] , [line] , [description]
FROM [MyDb].[dbo].[Table1]
```

However linked server needs to be configured for RPC if you want to use **@Create** or **@Drop** options.

```sql
EXEC master.dbo.sp_serveroption @server=N'LinkedSrv', @optname=N'rpc', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'LinkedSrv', @optname=N'rpc out', @optvalue=N'true'
GO
```

It might be handy to use **@Where** parameter to filter data.

```
EXEC x_CopyData @SourceDatabase = 'MyDb' , @SourceTable = 'Table1' , @DestinationDatabase = 'Backup'
  , @Where = '[id] > 123 AND [id] < 567' , @Pretend = 1 ;
```

```sql
INSERT INTO [Backup].[dbo].[Table1]
( [id] , [ancestor] , [line] , [description] )
SELECT
  [id] , [ancestor] , [line] , [description]
FROM [MyDb].[dbo].[Table1]
WHERE [id] > 123 AND [id] < 567
```

[↑ Up ↑](#microsoft-sql-server)

Schedule Job
------------

[↑ Up ↑](#microsoft-sql-server)

[Installation script for x_ScheduleJob →](../../sql/SQLServer/x_ScheduleJob.sql)

Add job and schedule execution plan.

``` 
EXEC x_ScheduleJob @Help = 1 ;
```

| Parameter | Type | Description |                                                            
| --------- | ---- | ----------- |
| @Help | BIT | Show this help. |
| @Pretend | BIT | Print queries to be executed but don't do anything. |
| @Name | NVARCHAR(128) | Database name |
| @Name | NVARCHAR(128) | Desired job name. It will be used for step name too. |
| @Command | NVARCHAR(MAX) | Command text for job step. |
| @Database | NVARCHAR(128) | Database job will be run on. Current database will be used if not specified. |
| @Owner | NVARCHAR(128) | Owner name. |
| @Enable | BIT | Enable job. |
| @Type | NVARCHAR(10) | A value indicating when a job is to be executed. Valid value is one of 'DAILY', 'WEEKLY', 'MONTHLY', 'RELATIVE', 'START', 'IDLE', 'ONCE' or 'NONE'. |
| @Interval | INT | Days that a job is executed. |
| @Repeat | NVARCHAR(10) | Specifies units for repeat interval. Valid value is one of 'HOURS', 'MINUTES', 'SECONDS', 'ONCE' or 'NONE'. |
| @Every | INT | Specifies value for repeat interval. That is number of hours, minutes or seconds depending on chosen repeat interval unit. |
| @Relative | INT | When schedule type is relative, this value indicates job's occurrence in each month. |
| @StartDate | INT | Start date written in YYMMDD format. |
| @EndDate | INT | End date written in YYMMDD format. |
| @StartTime | INT | Start time written in HHMMSS 24 hour format. |
| @EndTime | INT | End time written in HHMMSS 24 hour format. |

```sql
EXEC dbo.x_ScheduleJob @Pretend=1 , @Name=N'Nächste Żółw'
  , @Type='D', @Interval = 2 , @Repeat = 'M' , @Every = 15 , @Relative = 2
  , @Owner = 'sa'
  , @StartTime = 130000 , @EndTime = 143000
  , @Command = N'SELECT N''Nächste Żółw'''
  ;
```

```sql
IF EXISTS ( SELECT 1 FROM msdb.dbo.sysjobs WHERE [name] = N'Nächste Żółw' )
EXEC sp_executesql N'EXEC msdb.dbo.sp_delete_job @job_name = N''Nächste Żółw'' , @delete_unused_schedule = 0' ;

EXEC msdb.dbo.sp_add_job @job_name = N'Nächste Żółw' ;

EXEC msdb.dbo.sp_add_jobstep
  @job_name = N'Nächste Żółw' ,
  @step_name = N'Nächste Żółw' ,
  @database_name = N'DBAtools' ,
  @subsystem = N'TSQL' ,
  @command = N'SELECT N''Nächste Żółw''' ;

IF EXISTS ( SELECT 1 FROM msdb.dbo.sysschedules WHERE [name] = N'Nächste Żółw' )
EXEC sp_executesql N'EXEC msdb.dbo.sp_delete_schedule @schedule_name = N''Nächste Żółw'' , @force_delete = 1'  ;

EXEC msdb.dbo.sp_add_schedule
  @schedule_name = N'Nächste Żółw' ,
  @freq_type = 4 ,
  @freq_interval = 2 ,
  @freq_subday_type = 4 ,
  @freq_subday_interval = 15 ,
  @freq_relative_interval = 2 ,
  @active_start_date = 20000101 ,
  @active_end_date = 99991231 ,
  @active_start_time = 130000 ,
  @active_end_time = 143000 ,
  @owner_login_name = N'sa' ,
  @enabled = 0 ;

EXEC msdb.dbo.sp_attach_schedule @job_name = N'Nächste Żółw' , @schedule_name = N'Nächste Żółw' ;

EXEC msdb.dbo.sp_add_jobserver @job_name = N'Nächste Żółw' ;
```

For more informations about possible values of ``@Interval`` or ``@Every`` parameter values read official documentation about **sp_add_schedule** function.

https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-add-schedule-transact-sql

[↑ Up ↑](#microsoft-sql-server)

Wait types
----------

[↑ Up ↑](#microsoft-sql-server)

[Installation script for v_WaitType →](../../sql/SQLServer/v_WaitType.sql)

This function will return description table for wait types which may be handy in your reports.

```sql
SELECT [Name] , [Text]
FROM [DBAtools].dbo.v_WaitType()
WHERE [Name] LIKE 'ASYNC_%' 
ORDER BY [Name]
```

| Name | Text |
| ---- | ---- |
| ASYNC_DISKPOOL_LOCK | Attempt to synchronize parallel threads that are performing tasks such as creating or initializing a file. |
| ASYNC_IO_COMPLETION | Task is waiting for I/Os to finish. |
| ASYNC_NETWORK_IO | Occurs on network writes when the task is blocked behind the network. Verify that the client is processing data from the server. |
| ASYNC_OP_COMPLETION | Internal use only. |
| ASYNC_OP_CONTEXT_READ | Internal use only. |
| ASYNC_OP_CONTEXT_WRITE | Internal use only. |
| ASYNC_SOCKETDUP_IO | Internal use only. |

This dictionary was made from official Microsoft document about **sys.dm_os_wait_stats**.

[https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-os-wait-stats-transact-sql](https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-os-wait-stats-transact-sql)

Original data were extracted using regular expression replace.

```
^\s*([^\t]+?)\s*\t\s*([^\t]+?)\s*$
```

[↑ Up ↑](#microsoft-sql-server)
