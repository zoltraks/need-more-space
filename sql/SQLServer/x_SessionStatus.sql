IF OBJECT_ID ( 'dbo.x_SessionStatus' ) IS NULL
EXEC sp_executesql N'CREATE PROCEDURE dbo.x_SessionStatus AS BEGIN RETURN 0 ; END' ;

GO

--
-- Show current active sessions with information about state and transaction isolation level.
--
ALTER PROCEDURE dbo.x_SessionStatus ( @Database NVARCHAR(128) = NULL , @SPID BIGINT = -1
  , @Host NVARCHAR(128) = NULL
  , @Now BIT = NULL
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
        ( '@Database' , 'NVARCHAR(128)' , 'Database name' )
        ,
        ( '@Host' , 'NVARCHAR(128)' , 'Filter results by host. Set to ''+'' to include only remote sessions. Set to ''-'' to include only local sessions.' )
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
        ( 'Show current active sessions with information about state and transaction isolation level.' )
    ;
    SELECT [Description                                                                     ] = [Description] FROM @Description ;

    RETURN 0 ;
  END ;

  IF @Host IS NULL 
    SET @Host = '' ;

  IF ISNULL(@SPID , 0) =  0
  BEGIN
    SET @SPID = @@SPID ;
  END ;

  DECLARE @SQL NVARCHAR(MAX) = '' ;

  IF @Database <> ''
  BEGIN
    SET @SQL = @SQL + 'USE ' ;
    SET @SQL = @SQL + CASE WHEN SUBSTRING(@Database , 1 , 1) = '[' THEN @Database ELSE QUOTENAME(@Database) END ;
    SET @SQL = @SQL + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) ;
  END ;

  SET @SQL = @SQL +
'SELECT
' ;

  IF @Now = 1
    SET @SQL = @SQL +
'  GETDATE() AS [Now] ,
' ;

  SET @SQL = @SQL + 
'  session_id AS [SESSION] ,
  UPPER(status) AS [STATUS] ,
  DB_NAME(database_id) AS [DATABASE] ,
  host_name AS [HOST] ,
  CASE transaction_isolation_level
    WHEN 0 THEN ''UNSPECIFIED''
    WHEN 1 THEN ''READ UNCOMMIITTED''
    WHEN 2 THEN ''READ COMMITTED''
    WHEN 3 THEN ''REPEATABLE''
    WHEN 4 THEN ''SERIALIZABLE''
    WHEN 5 THEN ''SNAPSHOT'' 
  END
    AS [ISOLATION]
FROM sys.dm_exec_sessions
' ;

  DECLARE @has_where BIT ;
  SET @has_where = 0 ;

  IF @SPID > 0
  BEGIN

    IF @has_where = 1
      SET @SQL = @SQL + 'AND ' ;
    ELSE
    BEGIN
      SET @SQL = @SQL + 'WHERE ' ;
      SET @has_where = 1 ;
    END

    SET @SQL = @SQL + 'session_id = ' ;
  
    SET @SQL = @SQL + CONVERT(VARCHAR , @SPID) ;
  
    SET @SQL = @SQL + CHAR(13) + CHAR(10) ;

  END ;

  IF @Host IS NOT NULL AND @Host <> '' AND @Host <> '*'
  BEGIN

    IF @has_where = 1
      SET @SQL = @SQL + 'AND ' ;
    ELSE
    BEGIN
      SET @SQL = @SQL + 'WHERE ' ;
      SET @has_where = 1 ;
    END ;

    IF @Host = '-'
      SET @SQL = @SQL + 'host_name IS NULL ' ;
  
    IF @Host = '+'
      SET @SQL = @SQL + 'host_name IS NOT NULL ' ;
  
    IF CHARINDEX(@Host , '-+') = 0
    BEGIN
      
      SET @SQL = @SQL + 'host_name LIKE N''' ;
      SET @SQL = @SQL + REPLACE(@Host , '''' , '''''') ;
      SET @SQL = @SQL + '''' ;
      
      SET @SQL = @SQL + CHAR(13) + CHAR(10) ;
    END ;

  END ;


  IF @Database IS NOT NULL AND @Database <> '' AND @Database <> '*'
  BEGIN

    IF @has_where = 1
      SET @SQL = @SQL + 'AND ' ;
    ELSE
    BEGIN
      SET @SQL = @SQL + 'WHERE ' ;
      SET @has_where = 1 ;
    END ;

    SET @SQL = @SQL + 'DB_NAME(database_id) LIKE N''' ;
    SET @SQL = @SQL + REPLACE(@Database , '''' , '''''') ;
    SET @SQL = @SQL + '''' ;
    
    SET @SQL = @SQL + CHAR(13) + CHAR(10) ;

  END ;

  IF @SPID < 0
  BEGIN

    SET @SQL = @SQL + 
'ORDER BY session_id
' ;

  END ;

  IF @Pretend = 1
    PRINT @SQL ;
  ELSE
    EXECUTE sp_executesql @SQL ;

  RETURN 0 ;
END ;

GO
