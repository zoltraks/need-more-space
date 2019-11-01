IF OBJECT_ID ( 'dbo.x_OperationStatus' ) IS NULL
EXECUTE (N'CREATE PROCEDURE dbo.x_OperationStatus AS BEGIN RETURN 0; END')

GO

--
-- Show system operation status.
-- Simply display what database server is doing now.
--
ALTER PROCEDURE dbo.x_OperationStatus ( @Pretend BIT = 0 , @Help BIT = 0 )
AS
BEGIN
    IF @Help = 1
    BEGIN
        DECLARE @Parameter TABLE
        (
            [Parameter] NVARCHAR(10) ,
            [Type] NVARCHAR(20) ,
            [Description] NVARCHAR(200)
        );
        INSERT INTO @Parameter ( [Parameter] , [Type] , [Description] )
        VALUES
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
    END

    DECLARE @SQL NVARCHAR(2000) = '';

    SET @SQL = @SQL +
'SELECT
    [Database] = DB_NAME(R.database_id) , [Command] = R.Command , [Status] = R.Status
    ,
    [%] = CONVERT(DECIMAL(9, 2) , R.percent_complete)
    ,
    [Wait type] = R.wait_type
    ,
    [Start time] = R.start_time
    ,
    [Reads] = R.reads , [Writes] = R.writes
    ,
    [Time taken] = CONVERT(VARCHAR , R.total_elapsed_time / 60000) + '':'' + RIGHT(''00'' + CONVERT(VARCHAR , CONVERT(INT , R.total_elapsed_time / 1000 % 60)) , 2)
    ,
    [CPU Time] = CONVERT(VARCHAR , R.cpu_time / 60000) + '':'' + RIGHT(''00'' + CONVERT(VARCHAR , CONVERT(INT , R.cpu_time / 1000 % 60)) , 2)
    ,
    [Time left] = CONVERT(VARCHAR , R.estimated_completion_time / 60000) + '':'' + RIGHT(''00'' + CONVERT(VARCHAR , CONVERT(INT , R.estimated_completion_time / 1000 % 60)) , 2)
    ,
    [Session] = R.session_id
    ,
    [Operation                                                                                                               ] = T.text
FROM sys.dm_exec_requests R
CROSS APPLY sys.dm_exec_sql_text(R.sql_handle) T
WHERE R.session_id <> @@SPID
ORDER BY R.command
'

    IF @Pretend = 1
        PRINT @SQL ;
    ELSE
        EXECUTE sp_executesql @SQL ;

    RETURN 0;
END

GO
