IF OBJECT_ID ( 'dbo.x_FindQuery' ) IS NULL
EXEC sp_executesql N'CREATE PROCEDURE dbo.x_FindQuery AS BEGIN RETURN 0 ; END' ;

GO

--
-- Find specific query in Query Store.
--
ALTER PROCEDURE dbo.x_FindQuery ( @Like NVARCHAR(MAX) = NULL , @Database NVARCHAR(128) = NULL
  , @Group BIT = NULL , @Top SMALLINT = NULL , @Now BIT = NULL
  , @Pretend BIT = 0 , @Help BIT = 0 )
AS
BEGIN
  SET NOCOUNT ON ;

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
        ( '@Like' , 'NVARCHAR(MAX)' , 'Query text filter for LIKE' )
        ,
        ( '@Database' , 'NVARCHAR(128)' , 'Database name' )
        ,
        ( '@Group' , 'BIT' , 'Group queries to show unique entries only' )
        ,
        ( '@Top' , 'BIT' , 'Limit report to maximum number of top records' )
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
    );
    INSERT INTO @Description ( [Description] )
    VALUES
        ( 'Find query in Query Store.' )
        ,
        ( 'Search Query Store for specific query.' )
    ;
    SELECT [Description                                                                     ] = [Description] FROM @Description ;

    RETURN 0 ;
  END ;

  IF ISNULL(@Like , '') = ''
  BEGIN
    RAISERROR ( 'Parameter @Like must be not empty. Use @Help=1 to see options.' , 18 , 1 ) ;
    RETURN -1 ;
  END ;

  DECLARE @SQL NVARCHAR(MAX) = '' ;

  IF @Database <> ''
  BEGIN
    SET @SQL = @SQL + 'USE ' ;
    SET @SQL = @SQL + CASE WHEN SUBSTRING(@Database , 1 , 1) = '[' THEN @Database ELSE QUOTENAME(@Database) END ;
    SET @SQL = @SQL + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) ;
  END ;

  SET @SQL = @SQL + 'SELECT' ;

  IF @Top > 0 SET @SQL = @SQL + ' TOP(' + CONVERT(VARCHAR , @Top) + ')' ;

  IF @Now = 1
    SET @SQL = @SQL + '
  GETDATE() as [now] ,' ;

  IF @Group = 1
  BEGIN
    SET @SQL = @SQL + '
  q.query_id , MAX(q.last_execution_time) AS last_execution_time , t.query_sql_text
FROM sys.query_store_query q
INNER JOIN sys.query_store_query_text t
  ON q.query_text_id = t.query_text_id
WHERE
  t.query_sql_text LIKE ' ;
  END
  ELSE
  BEGIN
    SET @SQL = @SQL + '
  q.query_id , q.last_execution_time , t.query_sql_text
FROM sys.query_store_query q
INNER JOIN sys.query_store_query_text t
  ON q.query_text_id = t.query_text_id
WHERE
  t.query_sql_text LIKE ' ;
  END ;
  
  SET @SQL = @SQL + 'N''' + REPLACE(@Like , '''' , '''''') + '''' ;
  
  SET @SQL = @SQL + CHAR(13) + CHAR(10) ;

  IF @Group = 1
  BEGIN
    SET @SQL = @SQL +
'GROUP BY
  q.query_id , t.query_sql_text
ORDER BY
  MAX(q.last_execution_time) DESC
' ;
  END
  ELSE
  BEGIN
    SET @SQL = @SQL +
'ORDER BY
  q.last_execution_time DESC
' ;
  END ;

  IF @Pretend = 1
    PRINT @SQL ;
  ELSE
    EXECUTE sp_executesql @SQL ;

  RETURN 0 ;
END ;

GO
