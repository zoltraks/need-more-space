IF OBJECT_ID ( 'dbo.x_ShowIndex' ) IS NULL
EXEC sp_executesql N'CREATE PROCEDURE dbo.x_ShowIndex AS BEGIN RETURN 0; END' ;

GO

--
-- Show indexes and optionally columns included for one or more tables.
--
ALTER PROCEDURE dbo.x_ShowIndex ( @Database NVARCHAR(128) = NULL , @Table NVARCHAR(128) = NULL , @Schema NVARCHAR(128) = NULL , @Expand BIT = NULL , @Clustered BIT = NULL , @Unique BIT = NULL , @Primary BIT = NULL , @Pretend BIT = 0 , @Help BIT = 0 )
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
        ) ;
        INSERT INTO @Parameter ( [Parameter] , [Type] , [Description] )
        VALUES
            ( '@Database' , 'NVARCHAR(128)' , 'Database name' )
            ,
            ( '@Schema' , 'NVARCHAR(128)' , 'Schema name' )
            ,
            ( '@Table' , 'NVARCHAR(128)' , 'Table name' )
            ,
            ( '@Expand' , 'BIT' , 'Show index columns' )
            ,
            ( '@Clustered' , 'BIT' , 'Show clustered (1) or non-clustered (0) indexes' )
            ,
            ( '@Unique' , 'BIT' , 'Show unique (1) or non-unique (0) indexes' )
            ,
            ( '@Primary' , 'BIT' , 'Show primary (1) or non-primary (0) indexes' )
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
            ( 'Show indexes and optionally columns included for one or more tables.' )
        ;
        SELECT [Description                                                                     ] = [Description] FROM @Description ;
  
        RETURN 0 ;
    END ;

    DECLARE @SQL NVARCHAR(2000) = '' ;

    IF @Database IS NOT NULL
        SET @SQL = @SQL + 'USE ' + QUOTENAME(@Database) + CHAR(13) + CHAR(10) ;

    SET @SQL = @SQL +
'SELECT
    [Schema] = s.name , [Table] = t.name , [Index] = i.name' ;

    IF @Expand IS NOT NULL AND @Expand = 1
      SET @SQL = @SQL + ' , [Column] = c.name';

    SET @SQL = @SQL +
'
    ,
    [Clustered] = CASE WHEN i.index_id = 1 THEN 1 ELSE 0 END
    ,
    [Unique] = i.is_unique
    ,
    [Primary] = i.is_primary_key
FROM
    sys.tables t
INNER JOIN 
    sys.indexes i ON t.object_id = i.object_id
INNER JOIN
    sys.schemas s ON t.schema_id = s.schema_id
' ;

    IF @Expand IS NOT NULL AND @Expand = 1
      SET @SQL = @SQL + 
'INNER JOIN 
    sys.index_columns ic ON i.index_id = ic.index_id AND i.object_id = ic.object_id
INNER JOIN 
    sys.columns c ON ic.column_id = c.column_id AND ic.object_id = c.object_id
' ;

    SET @SQL = @SQL + 
'WHERE
    i.name IS NOT NULL
' ;

    IF @Schema IS NOT NULL AND @Schema <> ''
        SET @SQL = @SQL + 'AND
    s.name = N' + QUOTENAME(@Schema , '''') + CHAR(13) + CHAR(10) ;
    IF @Table IS NOT NULL AND @Table <> ''
        SET @SQL = @SQL + 'AND
    t.name = N' + QUOTENAME(@Table , '''') + CHAR(13) + CHAR(10) ;
    IF @Clustered IS NOT NULL
    BEGIN
        IF @Clustered = 1
            SET @SQL = @SQL + 'AND
    i.index_id = 1' + CHAR(13) + CHAR(10) ;
        ELSE
            SET @SQL = @SQL + 'AND
    i.index_id <> 1' + CHAR(13) + CHAR(10) ;
    END ;
    IF @Unique IS NOT NULL
        SET @SQL = @SQL + 'AND
    i.is_unique = ' + CONVERT(CHAR , @Unique) + CHAR(13) + CHAR(10) ;
    IF @Primary IS NOT NULL
        SET @SQL = @SQL + 'AND
    i.is_primary_key = ' + CONVERT(CHAR , @Primary) + CHAR(13) + CHAR(10) ;

    SET @SQL = @SQL + 'ORDER BY' + CHAR(13) + CHAR(10) + '    s.name , t.name , i.name'

    IF @Pretend = 1
        PRINT @SQL ;
    ELSE
        EXECUTE sp_executesql @SQL ;

    RETURN 0;
END

GO
