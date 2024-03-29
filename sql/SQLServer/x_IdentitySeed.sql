IF OBJECT_ID ( 'dbo.x_IdentitySeed' ) IS NULL
EXEC sp_executesql N'CREATE PROCEDURE dbo.x_IdentitySeed AS BEGIN RETURN 0 ; END' ;

GO

--
-- Show identity seed value for tables in database.
--
-- Generate report for all tables and identity column seed value together
-- with DBCC CHECKIDENT ( '[table]' , RESEED , 434342 ) script pattern to recreate it manually.
--
ALTER PROCEDURE dbo.x_IdentitySeed ( @Database NVARCHAR(128) = NULL , @Table NVARCHAR(128) = NULL , @Schema NVARCHAR(128) = NULL
  , @Operation BIT = 1 , @Plus BIT = 1
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
        ( '@Schema' , 'NVARCHAR(128)' , 'Schema name' )
        ,
        ( '@Table' , 'NVARCHAR(128)' , 'Table name' )
        ,
        ( '@Operation' , 'BIT' , 'Generate list of DBCC CHECKIDENT operations' )
        ,
        ( '@Plus' , 'BIT' , 'Use ''+'' in column names to for wide view' )
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
        ( 'Show identity seed value for tables in database.' )
        ,
        ( 'This procedure will show record count, identity seed value and generated script with DBCC to set current identity value for tables.' )
    ;
    SELECT [Description                                                                     ] = [Description] FROM @Description ;

    RETURN 0 ;
  END

  DECLARE @SQL NVARCHAR(2000) = '' ;
  DECLARE @SQL_1 NVARCHAR(2000) = '' ;

  SET @SQL = '' ;

  SET @SQL = @SQL +
'SELECT 1 [+]
  , [Schema] = SCHEMA_NAME(o.schema_id)
  , [Table] = o.[name]
  , [Count] = d.row_count
  , [Seed] = IDENT_CURRENT(REPLACE(QUOTENAME(SCHEMA_NAME(o.schema_id)) + ''.'' + QUOTENAME(o.[name]) , '''''''' , ''''''''''''))
FROM sys.indexes AS i
INNER JOIN sys.objects AS o ON i.OBJECT_ID = o.OBJECT_ID
INNER JOIN sys.dm_db_partition_stats AS d ON i.OBJECT_ID = d.OBJECT_ID AND i.index_id = d.index_id
WHERE i.index_id < 2 AND o.is_ms_shipped = 0
'
  IF @Schema IS NOT NULL AND @Schema <> ''
      SET @SQL = @SQL + '  AND SCHEMA_NAME(o.schema_id) = N' + QUOTENAME(@Schema , '''') + CHAR(13) + CHAR(10) ;
  IF @Table IS NOT NULL AND @Table <> ''
      SET @SQL = @SQL + '  AND o.[name] = N' + QUOTENAME(@Table , '''') + CHAR(13) + CHAR(10) ;

  SET @SQL = @SQL + 'ORDER BY SCHEMA_NAME(o.schema_id) , o.[name]' ;

  SET @SQL_1 = @SQL ;

  IF @Database <> ''
  BEGIN
    SET @SQL = ''
      + 'USE '
      + CASE WHEN SUBSTRING(@Database , 1 , 1) = '[' THEN @Database ELSE QUOTENAME(@Database) END
      + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) 
      + @SQL 
      ;
  END

  IF @Plus = 1
  BEGIN
      SET @SQL = REPLACE(@SQL , '[Schema]' , '[Schema         +]') ;
      SET @SQL = REPLACE(@SQL , '[Table]' , '[Table                                        +]') ;
      SET @SQL = REPLACE(@SQL , '[Count]' , '[Count               +]') ;
      SET @SQL = REPLACE(@SQL , '[Seed]' , '[Seed                +]') ;
  END

  IF @Pretend = 1
    PRINT @SQL ;
  ELSE
    EXECUTE sp_executesql @SQL ;

  -- Generate DBCC scripts

  IF @Operation = 1
  BEGIN
    SET @SQL = '' ;

    IF @Database <> ''
    BEGIN
      SET @SQL = @SQL + 'USE ' ;
      SET @SQL = @SQL + CASE WHEN SUBSTRING(@Database , 1 , 1) = '[' THEN @Database ELSE QUOTENAME(@Database) END ;
      SET @SQL = @SQL + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) ;
    END ;

    SET @SQL = @SQL + 'DECLARE C1 CURSOR FOR' + CHAR(13) + CHAR(10) ;
    SET @SQL = @SQL + @SQL_1 ;

    SET @SQL = @SQL + '

DECLARE @_ NVARCHAR(1)
DECLARE @_schema NVARCHAR(200)
DECLARE @_table NVARCHAR(200)
DECLARE @_count BIGINT
DECLARE @_seed BIGINT

DECLARE @TABLE_1 TABLE
(
  _ NVARCHAR(500)
) ;

DECLARE @TABLE_2 TABLE
(
  _ NVARCHAR(500)
) ;

DECLARE @sql NVARCHAR(4000)
DECLARE @_name NVARCHAR(500)

OPEN C1

WHILE 1 = 1
BEGIN
  FETCH NEXT FROM C1 INTO @_ , @_schema , @_table , @_count , @_seed ;
  IF @@FETCH_STATUS <> 0
    BREAK ;
  IF @_seed IS NULL
    CONTINUE ;
  SET @_name = QUOTENAME(@_schema) + ''.'' + QUOTENAME(@_table) ;
  SET @sql = ''DBCC CHECKIDENT ( '''''' + REPLACE(@_name , '''''''' , '''''''''''') + '''''' , RESEED , '' + CONVERT(VARCHAR(18) , @_seed) + '' )'' ;
  INSERT INTO @TABLE_1 VALUES ( @sql ) ;
  SET @sql = ''SELECT [Name] = '''''' + @_name + '''''' , [Seed] = IDENT_CURRENT ( '''''' + REPLACE(@_name , '''''''' , '''''''''''') + '''''' )'' ;
  INSERT INTO @TABLE_2 VALUES ( @sql ) ;
  --BREAK ;
END

CLOSE C1
DEALLOCATE C1

SELECT _ ____________________________________________________________ FROM @TABLE_1 ;

--SELECT _ ____________________________________________________________ FROM @TABLE_2 ;
' ;

    IF @Pretend = 1
    BEGIN
      PRINT CHAR(13) + CHAR(10) + '----------------------------------------' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) ;
      PRINT @SQL ;
    END
    ELSE
      EXECUTE sp_executesql @SQL ;
  END

  RETURN 0 ;
END

GO
