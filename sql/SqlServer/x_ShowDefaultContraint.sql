IF OBJECT_ID ( 'dbo.x_ShowDefaultContraint' ) IS NULL
EXECUTE (N'CREATE PROCEDURE dbo.x_ShowDefaultContraint AS BEGIN RETURN 0; END')

GO

--
-- Show default contraints.
--
ALTER PROCEDURE dbo.x_ShowDefaultContraint ( @Database NVARCHAR(128) = NULL , @Table NVARCHAR(128) = NULL , @Schema NVARCHAR(128) = NULL , @Column NVARCHAR(128) = NULL , @Constraint NVARCHAR(128) = NULL , @Pretend BIT = 0 , @Help BIT = 0 )
AS
BEGIN
    IF @Help = 1
    BEGIN
        DECLARE @Parameter TABLE
        (
            [Parameter] NVARCHAR(20) ,
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
            ( '@Column' , 'NVARCHAR(128)' , 'Column name' )
            ,
            ( '@Constraint' , 'NVARCHAR(128)' , 'Constraint name' )
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
            ( 'Show default contraints.' )
        ;
        SELECT [Description                                                                     ] = [Description] FROM @Description ;
  
        RETURN;
    END

    DECLARE @SQL NVARCHAR(2000) = '';

    IF @Database IS NOT NULL
        SET @SQL = @SQL + 'USE ' + QUOTENAME(@Database) + CHAR(13) + CHAR(10) ;
    SET @SQL = @SQL +
'SELECT
  [Schema] = s.[name]
  ,
  [Table] = t.[name]
  ,
  [Constraint] = d.[name]
  ,
  [Column] = c.[name]
  ,
  [Object] = d.[object_id]
  ,
  [Create] = d.[create_date]
  ,
  [Modify] = d.[modify_date]
FROM sys.default_constraints d
JOIN sys.columns c ON c.[column_id] = d.[parent_column_id] AND c.[object_id] = d.[parent_object_id]
JOIN sys.tables t ON t.[object_id] = d.[parent_object_id]
JOIN sys.schemas s ON s.[schema_id] = t.[schema_id]
WHERE d.[type] = ''D''
'
    IF @Schema IS NOT NULL AND @Schema <> ''
        SET @SQL = @SQL + '    AND s.[name] = N' + QUOTENAME(@Schema , '''') + CHAR(13) + CHAR(10) ;
    IF @Table IS NOT NULL AND @Table <> ''
        SET @SQL = @SQL + '    AND t.[name] = N' + QUOTENAME(@Table , '''') + CHAR(13) + CHAR(10) ;
    IF @Column IS NOT NULL AND @Column <> ''
        SET @SQL = @SQL + '    AND c.[name] = N' + QUOTENAME(@Column , '''') + CHAR(13) + CHAR(10) ;
    IF @Constraint IS NOT NULL AND @Constraint <> ''
        SET @SQL = @SQL + '    AND d.[name] = N' + QUOTENAME(@Constraint , '''') + CHAR(13) + CHAR(10) ;

    --SET @SQL = @SQL + 'ORDER BY' + CHAR(13) + CHAR(10) + '    s.name , t.name , c.name'

    IF @Pretend = 1
        PRINT @SQL ;
    ELSE
        EXECUTE sp_executesql @SQL ;

    RETURN 0;
END

GO
