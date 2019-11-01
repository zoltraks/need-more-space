Microsoft SQL Server
====================

Operation status
----------------

Show system operation status.

Simply display what database server is doing now.

This procedure has no relevant parameters.

```sql
EXEC x_OperationStatus ;
```

| Database | Command | Status | % | Wait type | Start time | Reads | Writes | Time taken | CPU Time | Time left | Session | Query text |                      
| -------- | ------- | ------ | - | --------- | ---------- | ----- | ------ | ---------- | -------- | --------- | ------- | ---------- |         
| master | RESTORE&nbsp;DATABASE | suspended | 5.60 | BACKUPTHREAD | 2019-11-01 09:52:34.973 | 2 | 0 | 00:50 | 00:00 | 14:03 | 87 | RESTORE DATABASE [ExampleTemp] FROM  DISK = N'E:\SQLBackups\Example\Example_backup_2019_10_30_160003_0084574.tlog' WITH  FILE = 2,  MOVE N' Example' TO N'E:\Temp\ExampleTemp.mdf',  MOVE N' Example_log' TO N'E:\Temp\ExampleTemp_log.ldf',  NORECOVERY,  NOUNLOAD,  REPLACE,  STATS = 10 | 
| master | SELECT | suspended | 0.00 | TRACEWRITE | 2019-11-01 07:40:00.500 | 0 | 0 | 33:25 | 00:00 | 00:00 | 76 | create procedure sys.sp_trace_getdata | (@traceid int, |  @records int = 0 | )asselect * from OpenRowset(TrcData, @traceid, @records) | 
|  ExampleTemp | UPDATE | suspended | 0.00 | WRITELOG | 2019-11-01 09:53:25.357 | 0 | 0 | 00:00 | 00:00 | 00:00 | 71 | (@data datetime)UPDATE SomeTable SET stamp=@data WHERE id = 229074 | 
| ExampleTemp | CONDITIONAL | running | 0.00 | NULL | 2019-11-01 10:08:10.717 | 0 | 0 | 00:00 | 00:00 | 00:00 | 97 | IF NOT EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ExampleTable' AND COLUMN_NAME = 'MissingColumn' ) | ALTER TABLE [ExampleTable] ADD [MissingColumn] FLOAT NULL...
| ExampleTemp | ALTER TABLE | running | 0.00 | NULL | 2019-11-01 10:08:12.067 | 713075 | 1884865 | 02:16 | 01:46 | 00:00 | 97 | UPDATE [ExampleTemp].[dbo].[ExampleTable] SET [CounterColumn] = [CounterColumn] | 
| OtherDb | CONDITIONAL | suspended | 0.00 | PAGEIOLATCH_SH | 2019-11-01 10:16:00.437 | 47445 | 0 | 00:14 | 00:00 | 00:00 | 97 | IF EXISTS ( SELECT TOP 1 1 FROM [a_batch] WHERE [stamp] IS NULL ) UPDATE [a_batch] SET [stamp] = GETDATE()... | 

[Installation script for x_OperationStatus](../../sql/SqlServer/x_OperationStatus.sql)


Find duplicates
---------------

Find duplicates in table.

```sql
EXEC x_FindDuplicates @Table = 'MyDb.dbo.MyTable' , @Columns = 'column1 , [Other One] , Col3' , @Pretend = 1 ;
```

```
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

```sql
EXEC DBAtools.dbo.x_FindDuplicates @Table = 'MyDb.dbo.MyTable' , @Columns = 'year,day' , @Expand = 'id , stamp' , @Pretend = 1 ;
```

```
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

[Installation script for x_FindDuplicates](../../sql/SqlServer/x_FindDuplicates.sql)
