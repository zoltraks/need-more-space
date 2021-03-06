IF OBJECT_ID ( 'dbo.x_CopyData' ) IS NULL
EXEC sp_executesql N'CREATE PROCEDURE dbo.x_CopyData AS BEGIN RETURN 0 ; END' ;

GO

--
-- Copy data from one table to another.
--
-- Copying is made with simple query INSERT INTO ... SELECT FROM ... with full list of columns.
-- Optionally create destination table, drop it first, or delete existing data.
-- Will also work with linked servers. 
--
ALTER PROCEDURE dbo.x_CopyData
( 
    @SourceDatabase NVARCHAR(128) = '' , @SourceSchema NVARCHAR(128) = '' , @SourceTable NVARCHAR(128) = '' , @SourceServer NVARCHAR(128) = ''
    ,
    @DestinationDatabase NVARCHAR(128) = '' , @DestinationSchema NVARCHAR(128) = '' , @DestinationTable NVARCHAR(128) = '' , @DestinationServer NVARCHAR(128) = ''
    ,
    @Create BIT = 0 , @Drop BIT = 0 , @Copy BIT = 1 , @Delete BIT = 0 , @Where NVARCHAR(2000) = ''
    ,
    @IncludeIdentity BIT = 1 , @IncludeComputed BIT = 0 , @IdentityNullable BIT = 0
    ,
    @Pretend BIT = 0 , @Help BIT = 0 
)
AS
BEGIN
    IF @Help = 1
    BEGIN
        DECLARE @Parameter TABLE
        (
            [Parameter] NVARCHAR(20) ,
            [Type] NVARCHAR(20) ,
            [Description] NVARCHAR(500)
        );
        INSERT INTO @Parameter ( [Parameter] , [Type] , [Description] )
        VALUES
            ( '@Pretend' , 'BIT' , 'Print queries to be executed but don''t do anything. Will however read column definition from source table.' )
            ,
            ( '@Help' , 'BIT' , 'Show this help' )
            ,
            ( '@SourceDatabase' , 'NVARCHAR(128)' , 'Source database name. Optional.' )
            ,
            ( '@SourceSchema' , 'NVARCHAR(128)' , 'Source schema name. If omited, default "dbo" will be used.' )
            ,
            ( '@SourceTable' , 'NVARCHAR(128)' , 'Source table name. Required.' )
            ,
            ( '@SourceServer' , 'NVARCHAR(128)' , 'Source linked server. Optional.' )
            ,
            ( '@DestinationDatabase' , 'NVARCHAR(128)' , 'Destination database name. If not specified, source database name will be used.' )
            ,
            ( '@DestinationSchema' , 'NVARCHAR(128)' , 'Destination schema name. If omited, default "dbo" will be used.' )
            ,
            ( '@DestinationTable' , 'NVARCHAR(128)' , 'Destination table name. If not specified, source table name will be used.' )
            ,
            ( '@DestinationServer' , 'NVARCHAR(128)' , 'Destination linked server. Optional. Be aware that trying to create or drop table will require linked server to be configured for RPC.' )
            ,
            ( '@Copy' , 'BIT' , 'Copy data with simple query INSERT INTO ... SELECT FROM ... with full list of columns.' )
            ,
            ( '@Create' , 'BIT' , 'Create destination table if not exists.' )
            ,
            ( '@Drop' , 'BIT' , 'Drop destination table if exists.' )
            ,
            ( '@Delete' , 'BIT' , 'Delete data from destination table first.' )
            ,
            ( '@Where' , 'NVARCHAR(2000)' , 'Optional WHERE clausule for SELECT operation.' )
            ,
            ( '@IncludeIdentity' , 'BIT' , 'Include identity columns for copying.' )
            ,
            ( '@IncludeComputed' , 'BIT' , 'Include computed columns for copying. By default computed columns are not copied nor created.' )
            ,
            ( '@IdentityNullable' , 'BIT' , 'Force identity column to be nullable in create table script.' )
            ;
        SELECT [Parameter] , [Type] , [Description ____________________________________________________________________________________________] = [Description] FROM @Parameter ;

        DECLARE @Description TABLE
        (
            [Description] NVARCHAR(200)
        );
        INSERT INTO @Description
        VALUES
            ( 'Copy data from one table to another.' )
            ,
            ( 'Copying is made with simple query INSERT INTO ... SELECT FROM ... with full list of columns.' )
            ,
            ( 'Optionally create destination table, drop it first, or delete existing data.' )
            ,
            ( 'Will also work with linked servers.' )
            ;
        SELECT [Description ____________________________________________________________________________________________] = [Description] FROM @Description ;
        
        RETURN;
    END

    IF @SourceTable IS NULL OR @SourceTable = ''
    BEGIN
        RAISERROR ( 'Source table must be specified' , 18 , 1 ) ;
        RETURN -1 ;
    END

    IF ( @DestinationTable IS NULL OR @DestinationTable = '' ) AND ( @DestinationDatabase IS NULL OR @DestinationDatabase = '' )
        AND ( @Pretend IS NULL OR @Pretend <> 1 )
    BEGIN
        RAISERROR ( 'Destination table or destination database must be specified' , 18 , 1 ) ;
        RETURN -1 ;
    END

    IF @Copy = 0 AND @Create = 0 AND @Drop = 0 AND @Delete = 0
    BEGIN
        RAISERROR ( 'No operation specified' , 18 , 1 ) ;
        RETURN -1 ;
    END

    SET @Create = ISNULL(@Create , 0) ;
    SET @Drop = ISNULL(@Drop , 0) ;
    SET @Copy = ISNULL(@Copy , 0) ;
    SET @Delete = ISNULL(@Delete , 0) ;

    SET @IncludeIdentity = ISNULL(@IncludeIdentity , 0) ;
    SET @IncludeComputed = ISNULL(@IncludeComputed , 0) ;
    SET @IdentityNullable = ISNULL(@IdentityNullable , 0) ;

    SET NOCOUNT ON ;

    DECLARE @SourceLink NVARCHAR(500) ;
    DECLARE @DestinationLink NVARCHAR(500) ;
    DECLARE @SourceFull NVARCHAR(1000) ;
    DECLARE @DestinationFull NVARCHAR(1000) ;
    DECLARE @SourceShort NVARCHAR(1000) ;
    DECLARE @DestinationShort NVARCHAR(1000) ;

    IF @SourceServer IS NULL SET @SourceServer = '' ;
    IF ISNULL(@SourceDatabase , '') = '' SET @SourceDatabase = DB_NAME() ;

    IF @DestinationServer IS NULL SET @DestinationServer = '' ;
    IF ISNULL(@DestinationDatabase , '') = '' SET @DestinationDatabase = DB_NAME() ;

    IF ISNULL(@DestinationTable , '') = '' SET @DestinationTable = @SourceTable ;

    IF ISNULL(@SourceSchema , '') = '' SET @SourceSchema = 'dbo' ;
    IF ISNULL(@DestinationSchema , '') = '' SET @DestinationSchema = 'dbo' ;

    SET @SourceLink = QUOTENAME(@SourceDatabase) ;
    IF @SourceServer <> '' AND SUBSTRING(@SourceServer , 1 , 1) <> '[' SET @SourceServer = QUOTENAME(@SourceServer) ;
    IF @SourceServer <> '' SET @SourceLink = @SourceServer + '.' + @SourceLink ;

    SET @DestinationLink = QUOTENAME(@DestinationDatabase) ;
    IF @DestinationServer <> '' AND SUBSTRING(@DestinationServer , 1 , 1) <> '[' SET @DestinationServer = QUOTENAME(@DestinationServer) ;
    IF @DestinationServer <> '' SET @DestinationLink = @DestinationServer + '.' + @DestinationLink ;

    SET @SourceFull = @SourceLink + '.' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@SourceTable) ;
    SET @DestinationFull = @DestinationLink + '.' + QUOTENAME(@DestinationSchema) + '.' + QUOTENAME(@DestinationTable) ;

    SET @SourceShort = QUOTENAME(@SourceDatabase) + '.' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@SourceTable) ;
    SET @DestinationShort = QUOTENAME(@DestinationDatabase) + '.' + QUOTENAME(@DestinationSchema) + '.' + QUOTENAME(@DestinationTable) ;

    IF @SourceFull = @DestinationFull AND ( @Pretend IS NULL OR @Pretend <> 1 )
    BEGIN
        RAISERROR ( 'Source and destination are the same' , 18 , 1 ) ;
        RETURN -1 ;
    END

    DECLARE @Query NVARCHAR(MAX) ;

    SET @Query = '
SELECT c.[name] AS [Name]
, UPPER(y.[name]) AS [Type]
, c.[is_nullable] AS [Null]
, c.[is_computed] AS [Computed]
, c.[is_identity] AS [Identity]
, CASE WHEN c.[precision] <> y.[precision] THEN c.[precision] ELSE NULL END AS [Precision]
, CASE WHEN c.[scale] <> y.[scale] THEN c.[scale] ELSE NULL END AS [Scale]
, CASE WHEN c.[max_length] <> y.[max_length] THEN c.[max_length] ELSE NULL END AS [Length]
FROM :source:.[sys].[tables] t
INNER JOIN :source:.[sys].[columns] c ON t.object_id = c.object_id
INNER JOIN :source:.[sys].[schemas] s ON t.schema_id = s.schema_id
INNER JOIN :source:.[sys].[types] y ON c.user_type_id = y.user_type_id
WHERE t.[name] = :table: AND s.[name] = :schema:
' ;

    SET @Query = REPLACE(@Query , ':source:' , @SourceLink) ;
    SET @Query = REPLACE(@Query , ':table:' , QUOTENAME(@SourceTable, '''')) ;
    SET @Query = REPLACE(@Query , ':schema:' , QUOTENAME(@SourceSchema, '''')) ;

    SET @Query = 'SET @CursorColumns = CURSOR FAST_FORWARD FOR' + CHAR(13) + CHAR(10) + @Query ;
    SET @Query = @Query + CHAR(13) + CHAR(10) + 'OPEN @CursorColumns ;' ;

    DECLARE @CursorColumns CURSOR ;

    DECLARE @Columns TABLE
    (
        [Name] NVARCHAR(128) ,
        [Type] NVARCHAR(128) ,
        [Null] BIT ,
        [Computed] BIT ,
        [Identity] BIT ,
        [Precision] INT ,
        [Scale] INT ,
        [Length] INT
    ) ;

    DECLARE @DefinitionList TABLE ( [_] NVARCHAR(500) ) ;

    DECLARE @ColumnName NVARCHAR(128) ;
    DECLARE @ColumnType NVARCHAR(128) ;
    DECLARE @ColumnNull BIT ;
    DECLARE @ColumnComputed BIT ;
    DECLARE @ColumnIdentity BIT ;
    DECLARE @ColumnPrecision INT ;
    DECLARE @ColumnScale INT ;
    DECLARE @ColumnLength INT ;

    DECLARE @Text NVARCHAR(4000) ;

    DECLARE @CreateScript NVARCHAR(MAX) = '' ;
    DECLARE @ColumnList NVARCHAR(MAX) = '' ;

    EXECUTE sp_executesql @Query , N'@CursorColumns CURSOR OUTPUT' , @CursorColumns = @CursorColumns OUTPUT ;

    WHILE 1 = 1
    BEGIN
        FETCH NEXT FROM @CursorColumns INTO @ColumnName , @ColumnType , @ColumnNull , @ColumnComputed , @ColumnIdentity , @ColumnPrecision , @ColumnScale , @ColumnLength ;
        IF @@FETCH_STATUS <> 0 BREAK ;

        IF @ColumnIdentity = 1 AND @IncludeIdentity <> 1 CONTINUE ;
        IF @ColumnComputed = 1 AND @IncludeComputed <> 1 CONTINUE ;

        INSERT INTO @Columns VALUES ( @ColumnName , @ColumnType , @ColumnNull , @ColumnComputed , @ColumnIdentity , @ColumnPrecision , @ColumnScale , @ColumnLength ) ;
        SET @Text = QUOTENAME(@ColumnName) + ' ' + @ColumnType ;

        IF @ColumnLength > 0 AND @ColumnType IN ('NCHAR' , 'NVARCHAR')
        BEGIN
          SET @ColumnLength = @ColumnLength / 2 ;
        END

        IF @ColumnType IN ('DATETIME2' , 'DATETIMEOFFSET' , 'TIME')
        BEGIN
          IF @ColumnScale IS NULL
            SET @Text = @Text + '(7)' ;
          IF @ColumnScale >= 0
            SET @Text = @Text + '(' + CONVERT(VARCHAR(10) , @ColumnScale) + ')' ;
        END
        ELSE
        IF @ColumnPrecision > 0
        BEGIN 
            SET @Text = @Text + '(' + CONVERT(VARCHAR(10) , @ColumnPrecision) ;
            IF @ColumnScale > 0 
              SET @Text = @Text + ',' + CONVERT(VARCHAR(10) , @columnScale ) ;
            IF @ColumnScale = 0 AND @ColumnType IN ('DECIMAL' , 'NUMERIC') 
              SET @Text = @Text + ',' + CONVERT(VARCHAR(10) , @columnScale ) ;
            SET @Text = @Text + ')'
        END
        ELSE IF @ColumnLength > 0
        BEGIN
            SET @Text = @Text + '(' + CONVERT(VARCHAR(10) , @ColumnLength) + ')' ;
        END
        ELSE IF @ColumnLength < 0
        BEGIN
            SET @Text = @Text + '(MAX)' ;
        END

        IF @ColumnIdentity = 1 AND @IdentityNullable = 1 SET @ColumnNull = 1 ;

        SET @Text = @Text + ' ' + CASE WHEN @ColumnNull = 1 THEN 'NULL' ELSE 'NOT NULL' END ;

        INSERT INTO @DefinitionList VALUES ( @Text ) ;

        IF @ColumnList <> '' SET @ColumnList = @ColumnList + ' , ' ;
        SET @ColumnList = @ColumnList + QUOTENAME(@ColumnName) ;

        IF @CreateScript <> '' SET @CreateScript = @CreateScript + ' ,' + CHAR(13) + CHAR(10) ;
        SET @CreateScript = @CreateScript + '  ' + @Text ;
    END

    CLOSE @CursorColumns ;
    DEALLOCATE @CursorColumns ;

    SET @CreateScript = 'CREATE TABLE ' + @DestinationShort + CHAR(13) + CHAR(10)
        + '(' + CHAR(13) + CHAR(10) + @CreateScript
        + CHAR(13) + CHAR(10) + ')' ;

    IF @Drop = 1
    BEGIN
        SET @Query = 'IF OBJECT_ID(N''' + + REPLACE(@DestinationShort, '''', '''''') + ''') IS NOT NULL' + CHAR(13) + CHAR(10) 
            + 'DROP TABLE ' + @DestinationShort ;

        IF @DestinationServer <> ''
            SET @Query = 'EXEC (N''' + CHAR(13) + CHAR(10) + REPLACE(@Query, '''', '''''') + CHAR(13) + CHAR(10) + ''') AT ' + @DestinationServer ;

        IF @Pretend = 1
            PRINT @Query ;
        ELSE
            EXECUTE sp_executesql @Query ;
    END

    IF @Create = 1
    BEGIN
        SET @Query = 'IF OBJECT_ID(N''' + + REPLACE(@DestinationShort, '''', '''''') + ''') IS NULL' + CHAR(13) + CHAR(10)
            + @CreateScript ;

        IF @DestinationServer <> ''
            SET @Query = 'EXEC (N''' + CHAR(13) + CHAR(10) + REPLACE(@Query, '''', '''''') + CHAR(13) + CHAR(10) + ''') AT ' + @DestinationServer ;

        IF @Pretend = 1
            PRINT @Query ;
        ELSE
            EXECUTE sp_executesql @Query ;
    END

    IF @Delete = 1
    BEGIN
        SET @Query = 'DELETE FROM ' + @DestinationFull ;

        IF @Pretend = 1
            PRINT @Query ;
        ELSE
            EXECUTE sp_executesql @Query ;
    END

    IF @Copy = 1
    BEGIN
        SET @Query = 'INSERT INTO ' + @DestinationFull + CHAR(13) + CHAR(10) + '( ' + @ColumnList + ' )' + CHAR(13) + CHAR(10)
            + 'SELECT' + CHAR(13) + CHAR(10) + '  ' + @ColumnList + CHAR(13) + CHAR(10)
            + 'FROM ' + @SourceFull ;

        IF ISNULL(@Where , '') <> ''
            SET @Query = @Query + CHAR(13) + CHAR(10) + 'WHERE ' + @Where ;

        IF @Pretend = 1
            PRINT @Query ;
        ELSE
            EXECUTE sp_executesql @Query ;
    END

    IF @Pretend = 1
        RETURN 0 ;
    ELSE
        RETURN 1 ;
END

GO
