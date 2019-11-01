
IF OBJECT_ID ( 'dbo.x_ShowIndex' ) IS NULL
EXECUTE (N'CREATE PROCEDURE dbo.x_ShowIndex AS BEGIN RETURN 0; END')

GO

--
-- Show indexes in database.
--
ALTER PROCEDURE dbo.x_ShowIndex ( @Database NVARCHAR(128) = NULL , @Table NVARCHAR(128) = NULL , @Schema NVARCHAR(128) = NULL , @Clustered BIT = NULL , @Unique BIT = NULL , @Primary BIT = NULL , @Pretend BIT = 0 , @Help BIT = 0 )
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
            ( '@Database' , 'NVARCHAR(128)' , 'Database name' )
            ,
            ( '@Schema' , 'NVARCHAR(128)' , 'Schema name' )
            ,
            ( '@Table' , 'NVARCHAR(128)' , 'Table name' )
            ,
            ( '@Clustered' , 'BIT' , 'Show only clustered or nonclustered indexes' )
            ,
            ( '@Unique' , 'BIT' , 'Show only unique or nonunique indexes' )
            ,
            ( '@Primary' , 'BIT' , 'Show only primary or nonprimary indexes' )
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
            ( 'Show indexes in database.' )
        ;
        SELECT [Description                                                                     ] = [Description] FROM @Description ;
  
        RETURN;
    END

    DECLARE @SQL NVARCHAR(2000) = '';

    IF @Database IS NOT NULL
        SET @SQL = @SQL + 'USE ' + QUOTENAME(@Database) + CHAR(13) + CHAR(10) ;
    SET @SQL = @SQL +
'SELECT
    [Schema] = s.name , [Table] = t.name , [Index] = i.name , [Clustered] = CASE WHEN i.index_id = 1 THEN 1 ELSE 0 END , [Unique] = i.is_unique , [Primary] = i.is_primary_key
FROM
    sys.tables t
INNER JOIN 
    sys.indexes i ON t.object_id = i.object_id
INNER JOIN
    sys.schemas s ON t.schema_id = s.schema_id
WHERE
    i.name IS NOT NULL
'
    IF @Schema IS NOT NULL AND @Schema <> ''
        SET @SQL = @SQL + '    AND s.name = N' + QUOTENAME(@Schema , '''') + CHAR(13) + CHAR(10) ;
    IF @Table IS NOT NULL AND @Table <> ''
        SET @SQL = @SQL + '    AND t.name = N' + QUOTENAME(@Table , '''') + CHAR(13) + CHAR(10) ;
    IF @Clustered IS NOT NULL
    BEGIN
        IF @Clustered = 1
            SET @SQL = @SQL + '    AND i.index_id = 1' + CHAR(13) + CHAR(10) ;
        ELSE
            SET @SQL = @SQL + '    AND i.index_id <> 1' + CHAR(13) + CHAR(10) ;
    END
    IF @Unique IS NOT NULL
        SET @SQL = @SQL + '    AND i.is_unique = ' + CONVERT(CHAR , @Unique) + CHAR(13) + CHAR(10) ;
    IF @Primary IS NOT NULL
        SET @SQL = @SQL + '    AND i.is_primary_key = ' + CONVERT(CHAR , @Primary) + CHAR(13) + CHAR(10) ;

    SET @SQL = @SQL + 'ORDER BY' + CHAR(13) + CHAR(10) + '    s.name , t.name , i.name'

    IF @Pretend = 1
        PRINT @SQL ;
    ELSE
        EXECUTE sp_executesql @SQL ;

    RETURN 0;
END

GO
