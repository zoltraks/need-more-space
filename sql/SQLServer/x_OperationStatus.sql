IF OBJECT_ID ( 'dbo.x_OperationStatus' ) IS NULL
EXEC sp_executesql N'CREATE PROCEDURE dbo.x_OperationStatus AS BEGIN RETURN 0; END' ;

GO

--
-- Show system operation status.
--
-- Simply display what database server is doing now.
--
ALTER PROCEDURE dbo.x_OperationStatus ( @Now BIT = NULL , @Pretend BIT = 0 , @Help BIT = 0 )
AS
BEGIN
    IF @Help = 1
    BEGIN
        DECLARE @Parameter TABLE
        (
            [Parameter] NVARCHAR(10) ,
            [Type] NVARCHAR(20) ,
            [Description] NVARCHAR(200)
        ) ;
        INSERT INTO @Parameter ( [Parameter] , [Type] , [Description] )
        VALUES
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
        );
        INSERT INTO @Description ( [Description] )
        VALUES
            ( 'Show system operation status.' ) 
            ,
            ( 'Simply display what database server is doing now.' ) 
            ;
        SELECT [Description                                                                     ] = [Description] FROM @Description ;
        
        RETURN;
    END ;

    DECLARE @SQL NVARCHAR(2000) = '' ;

    SET @SQL = @SQL +
'SELECT
' ;

    IF @Now = 1
        SET @SQL = @SQL +
'    [Now] = GETDATE()
    ,
' ;

    SET @SQL = @SQL +
'    [Database] = DB_NAME(R.database_id)
    ,
    [Command] = R.command
    ,
    [Status] = R.status
    ,
    [%] = CONVERT(DECIMAL(9, 2) , R.percent_complete)
    ,
    [Wait type] = R.wait_type
    ,
    [Start time] = R.start_time
    ,
    [Reads] = R.reads
    ,
    [Writes] = R.writes
    ,
    [Time taken] = CONVERT(VARCHAR , R.total_elapsed_time / 60000) + '':'' + RIGHT(''00'' + CONVERT(VARCHAR , CONVERT(INT , R.total_elapsed_time / 1000 % 60)) , 2)
    ,
    [CPU time] = CONVERT(VARCHAR , R.cpu_time / 60000) + '':'' + RIGHT(''00'' + CONVERT(VARCHAR , CONVERT(INT , R.cpu_time / 1000 % 60)) , 2)
    ,
    [Time left] = CONVERT(VARCHAR , R.estimated_completion_time / 60000) + '':'' + RIGHT(''00'' + CONVERT(VARCHAR , CONVERT(INT , R.estimated_completion_time / 1000 % 60)) , 2)
    ,
    [Session] = R.session_id
    ,
    [Host] = S.[host_name]
    ,
    [Operation                                                                                                               ] = T.text
FROM sys.dm_exec_requests R
CROSS APPLY sys.dm_exec_sql_text(R.sql_handle) T
LEFT JOIN sys.dm_exec_sessions S ON S.session_id = R.session_id
WHERE R.session_id <> @@SPID
ORDER BY R.command
' ;

    IF @Pretend = 1
        PRINT @SQL ;
    ELSE
        EXECUTE sp_executesql @SQL ;

    RETURN 0 ;
END ;

GO
