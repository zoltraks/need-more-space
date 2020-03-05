IF OBJECT_ID ( 'dbo.x_FileConfiguration' ) IS NULL
EXECUTE (N'CREATE PROCEDURE dbo.x_FileConfiguration AS BEGIN RETURN 0; END')

GO

--
-- Show database files configuration.
--
ALTER PROCEDURE dbo.x_FileConfiguration ( @Database NVARCHAR(257) = NULL , @Pretend BIT = 0 , @Help BIT = 0 )
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
            ( '@Database' , 'NVARCHAR(257)' , 'Database name' )
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
            ( 'Show database files configuration.' ) 
            ;
        SELECT [Description                                                                     ] = [Description] FROM @Description ;
        
        RETURN;
    END

    DECLARE @_from NVARCHAR(257) = @Database ;
    IF @_from IS NOT NULL AND @_from <> ''
        SET @_from = CASE WHEN SUBSTRING(@_from , 1 , 1) = '[' THEN @_from ELSE QUOTENAME(@_from) END + '.' ;

    DECLARE @SQL NVARCHAR(2000) = '';

    SET @SQL = @SQL +
'
SELECT
    [Name] = [name]
  ,
  [Size (MB)] = CONVERT(INT , [size] / 128.0)
  ,
  [Autogrowth] = CASE [max_size] WHEN 0 THEN ''OFF'' WHEN -1 THEN ''UNLIMITED'' ELSE ''LIMITED'' END
  ,
  [Growth (MB)] = CASE WHEN [is_percent_growth] = 0 THEN CONVERT(BIGINT , [growth] / 128.0) ELSE 0 END
  ,
  [Growth (%)] = CASE WHEN [is_percent_growth] = 1 THEN CONVERT(INT , [growth]) ELSE 0 END
  ,
  [State] = [state_desc]
  ,
  [Limit (MB)] = CASE WHEN [max_size] <= 0 THEN [max_size] ELSE CONVERT(INT , [max_size] / 128.0 / 1024.0 ) END
  ,
  [Number] = [file_id]
  ,
  [Type] = CASE WHEN [type] = 0 THEN ''DATA'' ELSE ''LOG'' END
  ,
  [File] = [physical_name]
FROM
  ' + @_from + 'sys.database_files
'

    IF @Pretend = 1
        PRINT @SQL ;
    ELSE
        EXECUTE sp_executesql @SQL ;

    RETURN 0;
END

GO

IF OBJECT_ID ( 'dbo.x_FindDuplicates' ) IS NULL
EXECUTE (N'CREATE PROCEDURE dbo.x_FindDuplicates AS BEGIN RETURN 0; END')

GO

--
-- Find duplicates in table.
--
ALTER PROCEDURE dbo.x_FindDuplicates ( @Table NVARCHAR(515) = NULL , @Columns NVARCHAR(MAX) = NULL  , @Expand NVARCHAR(MAX) = NULL , @Where NVARCHAR(MAX) = '' , @Top INT = 0 , @Pretend BIT = 0 , @Help BIT = 0 )
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
            ( '@Table' , 'NVARCHAR(515)' , 'Table name' )
            ,
            ( '@Columns' , 'NVARCHAR(MAX)' , 'Column list separated by comma, semicolon or whitespace (i.e. "col1, [Other One] , col2")' )
            ,
            ( '@Expand' , 'NVARCHAR(MAX)' , 'Expand results by including additional columns for duplicated records' )
            ,
            ( '@Where' , 'NVARCHAR(MAX)' , 'Optional filter for WHERE' )
            ,
            ( '@Top' , 'INT' , 'Maximum count of rows' )
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
            ( 'Find duplicates in table.' ) 
            ;
        SELECT [Description                                                                     ] = [Description] FROM @Description ;
        
        RETURN 0;
    END

    IF @Table IS NULL OR @Table = ''
    BEGIN
        RAISERROR ( 'Table name not specified' , 18 , 1 ) ;
    END

    IF @Columns IS NULL OR @Columns = ''
    BEGIN
        RAISERROR ( 'Column list not specified' , 18 , 1 ) ;
    END

    SET NOCOUNT ON

    -- Special names used when expansion list specified --

    DECLARE @_X NVARCHAR(5) = '__X__' ;
    DECLARE @_Y NVARCHAR(5) = '__Y__' ;

    -- Split column list by comma, semicolon or whitespace --

    DECLARE @_list TABLE ( _name NVARCHAR(128) ) ;
    DECLARE @_text NVARCHAR(MAX) ;
    DECLARE @_index INT ;
    DECLARE @_char NCHAR ;
    DECLARE @_next NCHAR ;
    DECLARE @_bracket BIT ;
    DECLARE @_length INT ;
    DECLARE @_start INT ;
    DECLARE @_end INT ;
    DECLARE @_skip NVARCHAR(10) ;

    SET NOCOUNT ON

    SET @_skip = ', ;' + CHAR(13) + CHAR(10) + CHAR(9) + CHAR(11) ;

    SET @_text = @Columns ;

    SET @_length = LEN(@_text) ;
    SET @_index = 0 ;
    SET @_bracket = 0 ;
    SET @_start = 0 ;
    SET @_end = 0 ;

    WHILE @_index < @_length
    BEGIN
        SET @_index = @_index + 1 ;
        SET @_char = SUBSTRING(@_text , @_index , 1) ;
        
        IF @_bracket = 0
        BEGIN
            IF @_char = '['
            BEGIN
                SET @_bracket = 1 ;
                SET @_start = @_index ;
                CONTINUE ;
            END
        END

        IF @_bracket = 1
        BEGIN
            IF @_char = ']'
            BEGIN
                IF @_index < @_length
                BEGIN
                    SET @_next = SUBSTRING(@_text , @_index + 1 , 1) ;
                    IF @_next = ']'
                    BEGIN
                        SET @_index = @_index + 1
                        CONTINUE ;
                    END
                END
                SET @_end = @_index ;
                INSERT INTO @_list ( _name ) VALUES ( SUBSTRING(@_text , @_start , 1 + @_end - @_start) ) ;
                SET @_start = 0 ;
                SET @_bracket = 0 ;
                CONTINUE ;
            END
            ELSE
            BEGIN
                CONTINUE ;
            END
        END

        IF 0 < CHARINDEX(@_char , @_skip)
        BEGIN
            IF 0 < @_start
            BEGIN
                SET @_end = @_index ;
                INSERT INTO @_list ( _name ) VALUES ( SUBSTRING(@_text , @_start , @_end - @_start) ) ;
                SET @_start = 0 ;
            END
            CONTINUE ;
        END
        ELSE
        BEGIN
            IF 0 = @_start
            BEGIN
                SET @_start = @_index
            END
            CONTINUE ;
        END
    END

    IF 0 < @_start
    BEGIN
        SET @_end = @_index ;
        INSERT INTO @_list ( _name ) VALUES ( SUBSTRING(@_text , @_start , 1 + @_end - @_start) ) ;
    END

    UPDATE @_list SET _name = CASE WHEN SUBSTRING(_name , 1 , 1) = '[' THEN _name ELSE QUOTENAME(_name) END

    -- Create column selection list --

    DECLARE @_first BIT ;
    DECLARE @_column NVARCHAR(128) ;

    DECLARE @_columnLine NVARCHAR(MAX) = '' ;
    DECLARE @_columnLineJoin NVARCHAR(MAX) = '' ;
    DECLARE @_columnLineOrder NVARCHAR(MAX) = '' ;

    SET @_first = 1 ;
    DECLARE C1 CURSOR FOR SELECT _name FROM @_list ;
    OPEN C1 ;
    WHILE 1 = 1
    BEGIN
        FETCH NEXT FROM C1 INTO @_column ;
        IF @@FETCH_STATUS <> 0 BREAK ;
        IF 1 = @_first
        BEGIN
            SET @_first = 0 ;
        END
        ELSE
        BEGIN
            SET @_columnLine = @_columnLine + ' , ' ;
            SET @_columnLineJoin = @_columnLineJoin + ' AND ' ;
            SET @_columnLineOrder = @_columnLineOrder + ' , ' ;
        END

        SET @_columnLine = @_columnLine + @_column ;
        SET @_columnLineJoin = @_columnLineJoin + @_X + '.' + @_column + ' = ' + @_Y + '.' + @_column ;
        SET @_columnLineOrder = @_columnLineOrder + @_X + '.' + @_column ;
    END
    CLOSE C1 ;
    DEALLOCATE C1 ;

    -- Do the same for optional expansion list --

    DECLARE @_expansionLine NVARCHAR(MAX) = '' ;

    IF @Expand IS NOT NULL AND @Expand <> ''
    BEGIN
        DELETE FROM @_list ;

        SET @_text = @Expand ;

        SET @_length = LEN(@_text) ;
        SET @_index = 0 ;
        SET @_bracket = 0 ;
        SET @_start = 0 ;
        SET @_end = 0 ;

        WHILE @_index < @_length
        BEGIN
            SET @_index = @_index + 1 ;
            SET @_char = SUBSTRING(@_text , @_index , 1) ;
            
            IF @_bracket = 0
            BEGIN
                IF @_char = '['
                BEGIN
                    SET @_bracket = 1 ;
                    SET @_start = @_index ;
                    CONTINUE ;
                END
            END

            IF @_bracket = 1
            BEGIN
                IF @_char = ']'
                BEGIN
                    IF @_index < @_length
                    BEGIN
                        SET @_next = SUBSTRING(@_text , @_index + 1 , 1) ;
                        IF @_next = ']'
                        BEGIN
                            SET @_index = @_index + 1
                            CONTINUE ;
                        END
                    END
                    SET @_end = @_index ;
                    INSERT INTO @_list ( _name ) VALUES ( SUBSTRING(@_text , @_start , 1 + @_end - @_start) ) ;
                    SET @_start = 0 ;
                    SET @_bracket = 0 ;
                    CONTINUE ;
                END
                ELSE
                BEGIN
                    CONTINUE ;
                END
            END

            IF 0 < CHARINDEX(@_char , @_skip)
            BEGIN
                IF 0 < @_start
                BEGIN
                    SET @_end = @_index ;
                    INSERT INTO @_list ( _name ) VALUES ( SUBSTRING(@_text , @_start , @_end - @_start) ) ;
                    SET @_start = 0 ;
                END
                CONTINUE ;
            END
            ELSE
            BEGIN
                IF 0 = @_start
                BEGIN
                    SET @_start = @_index
                END
                CONTINUE ;
            END
        END

        IF 0 < @_start
        BEGIN
            SET @_end = @_index ;
            INSERT INTO @_list ( _name ) VALUES ( SUBSTRING(@_text , @_start , 1 + @_end - @_start) ) ;
        END

        UPDATE @_list SET _name = CASE WHEN SUBSTRING(_name , 1 , 1) = '[' THEN _name ELSE QUOTENAME(_name) END

        -- Create column selection list --

        SET @_first = 1 ;
        DECLARE C2 CURSOR FOR SELECT _name FROM @_list ;
        OPEN C2 ;
        WHILE 1 = 1
        BEGIN
            FETCH NEXT FROM C2 INTO @_column ;
            IF @@FETCH_STATUS <> 0 BREAK ;
            IF 1 = @_first
            BEGIN
                SET @_first = 0 ;
            END
            ELSE
            BEGIN
                SET @_expansionLine = @_expansionLine + ' , ' ;
            END

            SET @_expansionLine = @_expansionLine + @_Y + '.' + @_column ;
            SET @_columnLineOrder = @_columnLineOrder + ' , ' + @_Y + '.' + @_column ;
        END
        CLOSE C2 ;
        DEALLOCATE C2 ;
    END

    -- Last train to Lhasa --

    IF @_columnLine = ''
    BEGIN
        RAISERROR ( 'Column list empty' , 18 , 1 ) ;
    END

    -- Generate query --

    DECLARE @SQL NVARCHAR(MAX) = '';

    IF '' = @_expansionLine
    BEGIN
        SET @SQL = @SQL +
'SELECT' + CASE WHEN 0 < @Top THEN ' TOP(' + CONVERT(VARCHAR , @Top) + ')' ELSE '' END +
'
    ' + @_columnLine + '
    ,
    [Count] = COUNT(*)
FROM
    ' +  @Table + '
' ;
        IF '' <> @Where
        BEGIN
            SET @SQL = @SQL + 
'WHERE
    ' + @Where ;
        END

        SET @SQL = @SQL +
'GROUP BY
    ' + @_columnLine + 
'
HAVING
    COUNT(*) > 1
ORDER BY
    ' + @_columnLine +
'
' ;
    END
    ELSE
    BEGIN
        SET @SQL = @SQL +
'WITH ' + @_X + ' AS
(
    SELECT
    ' + @_columnLine + '
    FROM
        ' +  @Table + '
' ;
        IF '' <> @Where
        BEGIN
            SET @SQL = @SQL + 
'    WHERE
        ' + @Where ;
        END

        SET @SQL = @SQL +
'    GROUP BY
        ' + @_columnLine + 
'
    HAVING
        COUNT(*) > 1
)
SELECT'  + CASE WHEN 0 < @Top THEN ' TOP(' + CONVERT(VARCHAR , @Top) + ')' ELSE '' END +
'
    ' + @_X + '.* , ' + @_expansionLine +
'
FROM
    ' + @_X +
'
LEFT JOIN
    ' + @Table + ' ' + @_Y + ' ON ' + @_columnLineJoin +
'
ORDER BY
    ' + @_columnLineOrder ;

    END

    IF @Pretend = 1
        PRINT @SQL ;
    ELSE
        EXECUTE sp_executesql @SQL ;

    RETURN 0;
END

GO

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


IF OBJECT_ID ( 'dbo.x_ShowIdentitySeed' ) IS NULL
EXECUTE (N'CREATE PROCEDURE dbo.x_ShowIdentitySeed AS BEGIN RETURN 0; END')

GO

--
-- Show identity seed value for tables in database.
--
ALTER PROCEDURE dbo.x_ShowIdentitySeed ( @Database NVARCHAR(128) = NULL , @Table NVARCHAR(128) = NULL , @Schema NVARCHAR(128) = NULL
  , @Operation BIT = 1 , @Plus BIT = 1
  , @Pretend BIT = 0 , @Help BIT = 0 )
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
  
        RETURN;
    END

    SET NOCOUNT ON

    DECLARE @SQL NVARCHAR(2000) = '';
    DECLARE @SQL_1 NVARCHAR(2000) = '';

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

    IF @Plus = 1
    BEGIN
        SET @SQL = REPLACE(@SQL , '[Schema]' , '[Schema         +]') ;
        SET @SQL = REPLACE(@SQL , '[Table]' , '[Table                                        +]') ;
        SET @SQL = REPLACE(@SQL , '[Count]' , '[Count               +]') ;
        SET @SQL = REPLACE(@SQL , '[Seed]' , '[Seed                +]') ;
    END

  IF @Database IS NOT NULL
    SET @SQL = 'USE ' + QUOTENAME(@Database) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + @SQL ;

  IF @Pretend = 1
    PRINT @SQL ;
  ELSE
    EXECUTE sp_executesql @SQL ;

  -- Generate DBCC scripts

  IF @Operation = 1
  BEGIN

    SET @SQL = '' ;

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
  SET @sql = ''DBCC CHECKIDENT ( '''''' + REPLACE(@_name , '''''''' , '''''''''''') + '''''' , RESEED , '' + CONVERT(VARCHAR(18) , @_seed) + '')'' ;
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

    IF @Database IS NOT NULL
      SET @SQL = 'USE ' + QUOTENAME(@Database) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + @SQL ;

    IF @Pretend = 1
    BEGIN
      PRINT CHAR(13) + CHAR(10) + '----------------------------------------' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) ;
      PRINT @SQL ;
    END
    ELSE
      EXECUTE sp_executesql @SQL ;

  END

  RETURN 0;
END

GO


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


IF OBJECT_ID ( 'dbo.x_ShowIndexColumn' ) IS NULL
EXECUTE (N'CREATE PROCEDURE dbo.x_ShowIndexColumn AS BEGIN RETURN 0; END')

GO

--
-- Show index columns for tables in database.
--
ALTER PROCEDURE dbo.x_ShowIndexColumn ( @Database NVARCHAR(128) = NULL , @Table NVARCHAR(128) = NULL , @Schema NVARCHAR(128) = NULL , @Clustered BIT = NULL , @Unique BIT = NULL , @Primary BIT = NULL , @Pretend BIT = 0 , @Help BIT = 0 )
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
            ( 'Show index columns for tables in database.' )
        ;
        SELECT [Description                                                                     ] = [Description] FROM @Description ;
        
        RETURN;
    END

    DECLARE @SQL NVARCHAR(2000) = '';

    IF @Database IS NOT NULL
        SET @SQL = @SQL + 'USE ' + QUOTENAME(@Database) + CHAR(13) + CHAR(10) ;
    SET @SQL = @SQL +
'SELECT
    [Schema] = s.name , [Table] = t.name , [Index] = i.name , [Column] = c.name
    ,
    [Clustered] = CASE WHEN i.index_id = 1 THEN 1 ELSE 0 END , [Unique] = i.is_unique , [Primary] = i.is_primary_key
FROM
    sys.tables t
INNER JOIN 
    sys.indexes i ON t.object_id = i.object_id
INNER JOIN 
    sys.index_columns ic ON i.index_id = ic.index_id AND i.object_id = ic.object_id
INNER JOIN 
    sys.columns c ON ic.column_id = c.column_id AND ic.object_id = c.object_id
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

IF OBJECT_ID ( 'dbo.x_SystemMemory' ) IS NULL
EXECUTE (N'CREATE PROCEDURE dbo.x_SystemMemory AS BEGIN RETURN 0; END')

GO

--
-- Show basic information about memory amount and state.
--
ALTER PROCEDURE dbo.x_SystemMemory ( @Pretend BIT = 0 , @Help BIT = 0 )
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
            ( 'Show basic information about memory amount and state.' )
            ;
        SELECT [Description                                                                     ] = [Description] FROM @Description ;
        
        RETURN;
    END

    DECLARE @SQL NVARCHAR(2000) = '';

    SET @SQL = @SQL +
'SELECT
    sys.dm_os_sys_memory.total_physical_memory_kb / 1024 AS [Physical memory (MB)]
    ,
    sys.dm_os_sys_memory.available_physical_memory_kb / 1024 AS [Available memory (MB)]
    , 
    sys.dm_os_sys_memory.total_page_file_kb / 1024 AS [Total page file (MB)]
    ,
    sys.dm_os_sys_memory.available_page_file_kb / 1024 AS [Available page file (MB)]
    ,
    sys.dm_os_sys_memory.system_cache_kb / 1024 AS [System cache (MB)]
    ,
    sys.dm_os_process_memory.physical_memory_in_use_kb / 1024 AS [Memory used (MB)]
    ,
    sys.dm_os_sys_memory.system_memory_state_desc AS [Memory state]
FROM sys.dm_os_sys_memory 
CROSS JOIN sys.dm_os_process_memory
'

    IF @Pretend = 1
        PRINT @SQL ;
    ELSE
        EXECUTE sp_executesql @SQL ;

    RETURN 0;
END

GO
