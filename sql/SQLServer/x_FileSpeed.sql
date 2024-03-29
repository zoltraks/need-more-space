IF OBJECT_ID ( 'dbo.x_FileSpeed' ) IS NULL
EXEC sp_executesql N'CREATE PROCEDURE dbo.x_FileSpeed AS BEGIN RETURN 0; END' ;

GO

--
-- Show I/O speed of database files.
--
ALTER PROCEDURE dbo.x_FileSpeed ( @Database NVARCHAR(260) = NULL , @Sample INT = NULL 
  , @CountPerSecond BIT = NULL , @ActivityOnly BIT = NULL , @Output NVARCHAR(260) = NULL , @Retain INT = NULL
  , @Now BIT = NULL 
  , @Pretend BIT = NULL , @Help BIT = NULL 
  )
AS
BEGIN
    SET NOCOUNT ON ;

    IF @Help = 1
    BEGIN
        DECLARE @Parameter TABLE
        (
            [Parameter] NVARCHAR(20) ,
            [Type] NVARCHAR(20) ,
            [Description] NVARCHAR(200)
        ) ;
        INSERT INTO @Parameter ( [Parameter] , [Type] , [Description] )
        VALUES
            ( '@Database' , 'NVARCHAR(260)' , 'Database name' )
            ,
            ( '@Sample' , 'INT' , 'Sample time in seconds. Default is 30 seconds and minimum value is 10 seconds.' )
            ,
            ( '@CountPerSecond' , 'BIT' , 'Display total reads and writes per second rather than per minute which is default.' )
            ,
            ( '@ActivityOnly' , 'BIT' , 'Exclude rows where there is no activity' )
            ,
            ( '@Output' , 'NVARCHAR(260)' , 'If this parameter is supplied, results will be inserted to destination table instead of displaying result. Destination table will be created if not exists.' )
            ,
            ( '@Retain' , 'INT' , 'Number of days to keep data in destination table. Default is 7 days after which data will be deleted after execution. When set to 0 or negative value, no data will be deleted.' )
            ,
            ( '@Now' , 'BIT' , 'Include column with current date and time' )
            ,
            ( '@Pretend' , 'BIT' , 'Print query to be executed but don''t do anything' )
            ,
            ( '@Help' , 'BIT' , 'Show this help' )
            ;
        SELECT [Parameter] , [Type] , [Description                                                                     ] = [Description] FROM @Parameter ;

        DECLARE @Description TABLE
        (
            [Description] NVARCHAR(200)
        ) ;
        INSERT INTO @Description ( [Description] )
        VALUES
            ( 'Show I/O speed of database files.' ) 
            ;
        SELECT [Description                                                                     ] = [Description] FROM @Description ;
        
        RETURN 0 ;
    END ;

    DECLARE @SQL NVARCHAR(MAX) = '' ;

    IF @Output IS NOT NULL AND @Output <> ''
    BEGIN
        DECLARE @N01 NVARCHAR(50) = '' ;
        DECLARE @I01 INT = LEN(@Output) ;
        DECLARE @C01 CHAR ;
        WHILE @I01 > 1 AND LEN(@N01) < 50
        BEGIN
            SET @C01 = SUBSTRING(@Output , @I01 , 1) ;
            IF @C01 = '.'
            BREAK ;
            IF @C01 >= 'A' AND @C01 <= 'Z' OR @C01 >= 'a' AND @C01 <= 'z' OR @C01 >= '0' AND @C01 <= '9' OR @C01 = '_'
            SET @N01 = @C01 + @N01 ;
            SET @I01 = @I01 - 1 ;
        END ;
        IF @N01 = '' SET @N01 = 'FileSpeed' ;

        DECLARE @PK_NAME NVARCHAR(60) = 'PK_' + @N01 ;
        DECLARE @DF_TIME_NAME NVARCHAR(60) = 'DF_' + @N01 + '_Time' ;

        SET @SQL = @SQL + 'IF ( SELECT OBJECT_ID(N''' ;
        SET @SQL = @SQL + REPLACE(@Output , '''' , '''''') ;
        SET @SQL = @SQL + ''' , ''U'') ) IS NULL' ;
        SET @SQL = @SQL +
'
CREATE TABLE ' + @Output + '
(
  [Time] DATETIMEOFFSET CONSTRAINT ' + @DF_TIME_NAME + ' DEFAULT GETDATE() NOT NULL ,
  [Database] NVARCHAR (128) NOT NULL ,
  [File] NVARCHAR(260) NOT NULL ,
  [Read speed] DECIMAL(9,2) NOT NULL ,
  [Write speed] DECIMAL(9,2) NOT NULL ,
  [Read count] INT NOT NULL ,
  [Write count] INT NOT NULL ,
  [Total wait] DECIMAL(9,1) NOT NULL ,
  [Read wait] DECIMAL(9,1) NOT NULL ,
  [Write wait] DECIMAL(9,1) NOT NULL ,
  [Type] NVARCHAR(10) NOT NULL ,
  [State] NVARCHAR(16) NOT NULL ,
  [Size] DECIMAL(18,1) NOT NULL ,
  CONSTRAINT ' + @PK_NAME + ' PRIMARY KEY CLUSTERED ( [Time] , [Database] , [File] )
) ;
' ;
        DECLARE @EXEC NVARCHAR(2000) = 'EXEC ' ;
        SET @EXEC = @EXEC + QUOTENAME(DB_NAME()) + '.' + QUOTENAME(OBJECT_SCHEMA_NAME(@@PROCID)) + '.' + QUOTENAME(OBJECT_NAME(@@PROCID)) ;

        IF @Database IS NOT NULL
            SET @EXEC = @EXEC + ' @Database=N''' + REPLACE(@Database , '''' , '''''') + ''' ,' ;
        IF @Sample IS NOT NULL
            SET @EXEC = @EXEC + ' @Sample=' + CONVERT(NVARCHAR(5) , @Sample) + ' ,' ;
        IF @CountPerSecond IS NOT NULL
            SET @EXEC = @EXEC + ' @CountPerSecond=' + CONVERT(NVARCHAR(1) , @CountPerSecond) + ' ,' ;
        IF @ActivityOnly IS NOT NULL
            SET @EXEC = @EXEC + ' @ActivityOnly=' + CONVERT(NVARCHAR(1) , @ActivityOnly) + ' ,' ;

        IF SUBSTRING(@EXEC , LEN(@EXEC) - 1 , 2) = ' ,'
            SET @EXEC = SUBSTRING(@EXEC , 1 , LEN(@EXEC) - 2) ;
            
        SET @EXEC = @EXEC + ' ;' ;

        SET @SQL = @SQL +
'
INSERT INTO [DBAtools].[dbo].[FileSpeed]
( [Database] , [File] , [Read speed] , [Write speed] , [Read count] , [Write count] , [Total wait] , [Read wait] , [Write wait] , [Type] , [State] , [Size] )
' ;

        SET @SQL = @SQL + @EXEC ;

        SET @Retain = ISNULL(@Retain , 7) ;
        IF @Retain > 0
        BEGIN
            SET @SQL = @SQL +
'

DELETE FROM ' + @Output + '
WHERE [Time] < CONVERT(DATETIMEOFFSET , DATEADD(DAY , -' + CONVERT(VARCHAR(5) , @Retain) + ' , CONVERT(DATE , GETDATE()))) ;
' ;
        END ;

        IF ISNULL(@Pretend , 0) = 1
            PRINT @SQL ;
        ELSE
            EXECUTE sp_executesql @SQL ;

        RETURN 0 ;
    END ;

    SET @Sample = ISNULL(@Sample , 30) ;
    
    IF @Sample < 10
        SET @Sample = 10 ;

    DECLARE @_database_text NVARCHAR(260) = 'DEFAULT' ;
    IF @Database IS NOT NULL AND @Database <> N''
        SET @_database_text = 'DB_ID(N''' + REPLACE(@Database , '''' , '''''') + N''')' ;

    SET @SQL = @SQL + 
'
DECLARE @_t_1 TABLE (
  [Database] NVARCHAR (128) ,
  [DatabaseID] INT ,
  [File] NVARCHAR(260) ,
  [FileID] INT ,
  [Sample] BIGINT ,
  [ReadBytes] BIGINT ,
  [WriteBytes] BIGINT ,
  [ReadCount] BIGINT ,
  [WriteCount] BIGINT ,
  [TotalWait] BIGINT ,
  [ReadWait] BIGINT ,
  [WriteWait] BIGINT
)
' ;

    SET @SQL = @SQL +
'
DECLARE @_t_2 TABLE (
  [Database] NVARCHAR (128) ,
  [DatabaseID] INT ,
  [File] NVARCHAR(260) ,
  [FileID] INT ,
  [Sample] BIGINT ,
  [ReadBytes] BIGINT ,
  [WriteBytes] BIGINT ,
  [ReadCount] BIGINT ,
  [WriteCount] BIGINT ,
  [TotalWait] BIGINT ,
  [ReadWait] BIGINT ,
  [WriteWait] BIGINT
)
' ;

    SET @SQL = @SQL + 
'
INSERT INTO @_t_1
SELECT     
    d.[name] [Database] ,
    d.[database_id] [DatabaseID] ,
    f.[physical_name] [File] ,
    f.[file_id] [FileID] ,
    s.[sample_ms] [Sample] ,
    s.[num_of_bytes_read] [ReadBytes] ,
    s.[num_of_bytes_written] [WriteBytes] ,
    s.[num_of_reads] [ReadCount] ,
    s.[num_of_writes] [WriteCount] ,
    s.[io_stall] [TotalWait] ,
    s.[io_stall_read_ms] [ReadWait] ,
    s.[io_stall_write_ms] [WriteWait]
FROM sys.dm_io_virtual_file_stats(' + @_database_text + ' , DEFAULT) s
INNER JOIN sys.master_files f ON s.database_id = f.[database_id] AND s.[file_id] = f.[file_id]
INNER JOIN sys.databases d ON d.[database_id] = s.[database_id]
' ;

    SET @SQL = @SQL +
'
WAITFOR DELAY ''' + SUBSTRING(CONVERT(VARCHAR(12), DATEADD(SECOND , @Sample , 0), 108) , 1 , 8) + '''
' ;

    SET @SQL = @SQL + 
'
INSERT INTO @_t_2
SELECT     
    d.[name] [Database] ,
    d.[database_id] [DatabaseID] ,
    f.[physical_name] [File] , 
    f.[file_id] [FileID] , 
    s.[sample_ms] [Sample] ,
    s.[num_of_bytes_read] [ReadBytes] , 
    s.[num_of_bytes_written] [WriteBytes] ,
    s.[num_of_reads] [ReadCount] ,
    s.[num_of_writes] [WriteCount] ,
    s.[io_stall] [TotalWait] , 
    s.[io_stall_read_ms] [ReadWait] ,
    s.[io_stall_write_ms] [WriteWait]
FROM sys.dm_io_virtual_file_stats(' + @_database_text + ' , DEFAULT) s
INNER JOIN sys.master_files f ON s.database_id = f.[database_id] AND s.[file_id] = f.[file_id]
INNER JOIN sys.databases d ON d.[database_id] = s.[database_id]
' ;

    DECLARE @_count_text NVARCHAR(10) = N' / 60.0' ;
    DECLARE @_count_read_title NVARCHAR(20) = N'[Reads [m]]]' ;
    DECLARE @_count_write_title NVARCHAR(20) = N'[Writes [m]]]' ;

    IF @CountPerSecond IS NOT NULL AND @CountPerSecond = 1
    BEGIN
        SET @_count_text = N'' ;
        SET @_count_read_title = N'[Reads [s]]]' ;
        SET @_count_write_title = N'[Writes [s]]]' ;
    END ;

    DECLARE @_sample_text NVARCHAR(50) ;
    SET @_sample_text = ' / ((b.[Sample] - a.[Sample]) / 1000.0)' ;

    SET @SQL = @SQL +
'SELECT
' ;

    IF @Now = 1
      SET @SQL = @SQL +
'    GETDATE() AS [Now]
    ,
' ;

    SET @SQL = @SQL +
'    a.[Database] , a.[File]
    ,
    CONVERT(DECIMAL(9,2) , (b.[ReadBytes] - a.[ReadBytes]) / 1024.0' + @_sample_text + ') [Read [KB/s]]]
    , 
    CONVERT(DECIMAL(9,2) , (b.[WriteBytes] - a.[WriteBytes]) / 1024.0' + @_sample_text + ') [Write [KB/s]]]
    , 
    CONVERT(INT , CEILING((b.[ReadCount] - a.[ReadCount])' + @_count_text + @_sample_text + ')) ' + @_count_read_title + '
    , 
    CONVERT(INT , CEILING((b.[WriteCount] - a.[WriteCount])' + @_count_text + @_sample_text + ')) ' + @_count_write_title + '
    ,
    CONVERT(DECIMAL(9,1) , (b.[TotalWait] - a.[TotalWait]) / 1000.0' + @_sample_text + ') [Total wait]
    ,
    CONVERT(DECIMAL(9,1) , (b.[ReadWait] - a.[ReadWait]) / 1000.0' + @_sample_text + ') [Read wait]
    ,
    CONVERT(DECIMAL(9,1) , (b.[WriteWait] - a.[WriteWait]) / 1000.0' + @_sample_text + ') [Write wait]
    , 
    f.[type_desc] [Type] , f.[state_desc] [State]
    ,
    CONVERT(DECIMAL(18,1) , 8.0 * f.[size] / 1024.0) [Size [MB]]]
FROM sys.master_files f
JOIN @_t_1 a ON f.[database_id] = a.[DatabaseID] AND f.[file_id] = a.[FileID]
JOIN @_t_2 b ON f.[database_id] = b.[DatabaseID] AND f.[file_id] = b.[FileID]
' ;

    IF ISNULL(@ActivityOnly , 0) = 1
    BEGIN
      SET @SQL = @SQL +
'WHERE 
    b.[ReadBytes] - a.[ReadBytes] > 0 OR
    b.[WriteBytes] - a.[WriteBytes] > 0 OR
    b.[ReadCount] - a.[ReadCount] > 0 OR
    b.[WriteCount] - a.[WriteCount] > 0 OR
    b.[TotalWait] - a.[TotalWait] > 50 OR
    b.[ReadWait] - a.[ReadWait] > 50 OR
    b.[WriteWait] - a.[WriteWait] > 50
' ;
    END ;

    IF @Pretend = 1
        PRINT @SQL ;
    ELSE
        EXECUTE sp_executesql @SQL ;

    RETURN 0 ;
END ;

GO
