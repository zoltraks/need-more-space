IF OBJECT_ID ( 'dbo.x_FindDuplicates' ) IS NULL
EXEC sp_executesql N'CREATE PROCEDURE dbo.x_FindDuplicates AS BEGIN RETURN 0; END' ;

GO

--
-- Find duplicates in table.
--
ALTER PROCEDURE dbo.x_FindDuplicates ( 
    @Database NVARCHAR(MAX) = NULL , @Table NVARCHAR(MAX) = NULL , @Columns NVARCHAR(MAX) = NULL
  , @Expand NVARCHAR(MAX) = NULL , @Where NVARCHAR(MAX) = '' , @Top INT = 0
  , @Sort NVARCHAR(MAX) = NULL , @Output NVARCHAR(MAX) = NULL
  , @OutputRankColumn NVARCHAR(MAX) = NULL
  , @Pretend BIT = 0 , @Help BIT = 0
  )
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
            ( '@Database' , 'NVARCHAR(MAX)' , 'Database name. This parameter is optional.' )
            ,
            ( '@Table' , 'NVARCHAR(MAX)' , 'Table name. This parameter is required.' )
            ,
            ( '@Columns' , 'NVARCHAR(MAX)' , 'Column list separated by comma, semicolon or whitespace (i.e. "col1, [Other One] , col2")' )
            ,
            ( '@Expand' , 'NVARCHAR(MAX)' , 'Expand results by including additional columns for duplicated records' )
            ,
            ( '@Where' , 'NVARCHAR(MAX)' , 'Optional filter for WHERE' )
            ,
            ( '@Sort' , 'NVARCHAR(MAX)' , 'Custom ORDER BY column list' )
            ,
            ( '@Top' , 'INT' , 'Maximum count of rows' )
            ,
            ( '@Output' , 'NVARCHAR(MAX)' , 'If this parameter is supplied, results will be inserted to destination table instead of displaying result. Destination table will be created if not exists.' )
            ,
            ( '@OutputRankColumn' , 'NVARCHAR(MAX)' , 'Create auto incremented rank column for @Output table' )
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
        
        RETURN 0 ;
    END ;

    IF @Table IS NULL OR @Table = ''
    BEGIN
        RAISERROR ( 'Error: Table name not specified. Parameter @Table not given. Use @Help=1 for more information.' , 18 , 1 ) ;
        RETURN -1 ;
    END ;

    IF @Columns IS NULL OR @Columns = ''
    BEGIN
        RAISERROR ( 'Error: Column list not specified. Parameter @Columns not given. Use @Help=1 for more information.' , 18 , 1 ) ;
        RETURN -1 ;
    END ;

    -- Special names used when expansion list specified --

    DECLARE @_X NVARCHAR(5) = '__X__' ;
    DECLARE @_Y NVARCHAR(5) = '__Y__' ;

    -- Other variables --

    DECLARE @_databasePrefix NVARCHAR(MAX) = ISNULL(@Database , '') ;
    IF @_databasePrefix <> '' SET @_databasePrefix = @_databasePrefix + '.' ;

    DECLARE @_outputRankColumn NVARCHAR(MAX) = @OutputRankColumn ;
    IF @_outputRankColumn <> '' AND LEFT(@_outputRankColumn , 1) <> '['
      SET @_outputRankColumn = QUOTENAME(@_outputRankColumn) ;

    DECLARE @_allList TABLE ( _name NVARCHAR(300) ) ;

    -- Local variables used for expanding column list --

    DECLARE @_text NVARCHAR(MAX) ;
    DECLARE @_element NVARCHAR(MAX) ;
    DECLARE @_index INT ;
    DECLARE @_char NCHAR ;
    DECLARE @_next NCHAR ;
    DECLARE @_bracket BIT ;
    DECLARE @_length INT ;
    DECLARE @_start INT ;
    DECLARE @_end INT ;
    DECLARE @_skip NVARCHAR(10) ;

    SET @_skip = ', ;' + CHAR(13) + CHAR(10) + CHAR(9) + CHAR(11) ;

    -- Split column list by comma, semicolon or whitespace --

    DECLARE @_list TABLE ( _name NVARCHAR(300) ) ;

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
            END ;
        END ;

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
                    END ;
                END ;
                SET @_end = @_index ;
                SET @_element = SUBSTRING(@_text , @_start , 1 + @_end - @_start) ;
                INSERT INTO @_list ( _name ) VALUES ( @_element ) ;
                INSERT INTO @_allList ( _name ) VALUES ( @_element ) ;
                SET @_start = 0 ;
                SET @_bracket = 0 ;
                CONTINUE ;
            END
            ELSE
            BEGIN
                CONTINUE ;
            END ;
        END ;

        IF 0 < CHARINDEX(@_char , @_skip)
        BEGIN
            IF 0 < @_start
            BEGIN
                SET @_end = @_index ;
                SET @_element = SUBSTRING(@_text , @_start , @_end - @_start) ;
                INSERT INTO @_list ( _name ) VALUES ( @_element ) ;
                INSERT INTO @_allList ( _name ) VALUES ( @_element ) ;
                SET @_start = 0 ;
            END ;
            CONTINUE ;
        END
        ELSE
        BEGIN
            IF 0 = @_start
            BEGIN
                SET @_start = @_index
            END ;
            CONTINUE ;
        END ;
    END ;

    IF 0 < @_start
    BEGIN
        SET @_end = @_index ;
        SET @_element = SUBSTRING(@_text , @_start , 1 + @_end - @_start) ;
        INSERT INTO @_list ( _name ) VALUES ( @_element ) ;
        INSERT INTO @_allList ( _name ) VALUES ( @_element ) ;
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
        END ;

        SET @_columnLine = @_columnLine + @_column ;
        SET @_columnLineJoin = @_columnLineJoin + @_X + '.' + @_column + ' = ' + @_Y + '.' + @_column ;
        SET @_columnLineOrder = @_columnLineOrder + @_X + '.' + @_column ;
    END ;
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
                END ;
            END ;

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
                        END ;
                    END ;
                    SET @_end = @_index ;
                    SET @_element = SUBSTRING(@_text , @_start , 1 + @_end - @_start) ;
                    IF NOT EXISTS ( SELECT 1 FROM @_allList WHERE _name = @_element )
                        INSERT INTO @_list ( _name ) VALUES ( @_element ) ;
                    IF NOT EXISTS ( SELECT 1 FROM @_allList WHERE _name = @_element )
                        INSERT INTO @_allList ( _name ) VALUES ( @_element ) ;
                    SET @_start = 0 ;
                    SET @_bracket = 0 ;
                    CONTINUE ;
                END
                ELSE
                BEGIN
                    CONTINUE ;
                END ;
            END ;

            IF 0 < CHARINDEX(@_char , @_skip)
            BEGIN
                IF 0 < @_start
                BEGIN
                    SET @_end = @_index ;
                    SET @_element = SUBSTRING(@_text , @_start , @_end - @_start) ;
                    IF NOT EXISTS ( SELECT 1 FROM @_allList WHERE _name = @_element )
                        INSERT INTO @_list ( _name ) VALUES ( @_element ) ;
                    IF NOT EXISTS ( SELECT 1 FROM @_allList WHERE _name = @_element )
                        INSERT INTO @_allList ( _name ) VALUES ( @_element ) ;
                    SET @_start = 0 ;
                END
                CONTINUE ;
            END
            ELSE
            BEGIN
                IF 0 = @_start
                BEGIN
                    SET @_start = @_index ;
                END ;
                CONTINUE ;
            END ;
        END ;

        IF 0 < @_start
        BEGIN
            SET @_end = @_index ;
            SET @_element = SUBSTRING(@_text , @_start , 1 + @_end - @_start) ;
            IF NOT EXISTS ( SELECT 1 FROM @_allList WHERE _name = @_element )
                INSERT INTO @_list ( _name ) VALUES ( @_element ) ;
            IF NOT EXISTS ( SELECT 1 FROM @_allList WHERE _name = @_element )
                INSERT INTO @_allList ( _name ) VALUES ( @_element ) ;
        END ;

        UPDATE @_list SET _name = CASE WHEN SUBSTRING(_name , 1 , 1) = '[' THEN _name ELSE QUOTENAME(_name) END ;

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
            END ;
            SET @_expansionLine = @_expansionLine + @_Y + '.' + @_column ;
            SET @_columnLineOrder = @_columnLineOrder + ' , ' + @_Y + '.' + @_column ;
        END ;
        CLOSE C2 ;
        DEALLOCATE C2 ;
    END ;

    -- Last train to Lhasa --

    IF @_columnLine = ''
    BEGIN
        RAISERROR ( 'Error: Column list is empty' , 18 , 1 ) ;
        RETURN -1 ;
    END ;

    IF @Sort <> '' SET @_columnLineOrder = @Sort ;

    -- Generate query --

    DECLARE @SQL NVARCHAR(MAX) = '' ;

    IF '' = @_expansionLine
    BEGIN
        SET @SQL = @SQL +
'SELECT' + CASE WHEN 0 < @Top THEN ' TOP(' + CONVERT(VARCHAR , @Top) + ')' ELSE '' END +
'
    ' + @_columnLine + '
    ,
    [Count] = COUNT(*)
FROM
    ' + @_databasePrefix + @Table + '
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
        ' + @_databasePrefix + @Table + '
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
    ' + @_databasePrefix + @Table + ' ' + @_Y + ' ON ' + @_columnLineJoin +
'
ORDER BY
    ' + @_columnLineOrder ;

    END ;

    -- If @Output parameter is provided check if table exists and if not, create proper structure --

    IF @Output <> ''
    BEGIN
        DECLARE @_outputExists BIT = 0 ;
        DECLARE @_outputFullName NVARCHAR(260) = @Output ;
        IF LEFT(@_outputFullName , 2) = '[#' OR LEFT(@_outputFullName , 1) = '#'
            SET @_outputFullName = 'tempdb..' + @_outputFullName ;
        --SELECT @_outputFullName ;

        DECLARE @_sourceTableName NVARCHAR(260) = @Table ;
        DECLARE @_sourceTableSchema NVARCHAR(260) = 'dbo' ;
        DECLARE @_parameterDefinition NVARCHAR(MAX) ;
        SET @_parameterDefinition = '@out NVARCHAR(MAX) OUTPUT' ;
        DECLARE @_queryTable NVARCHAR(MAX) ;
        DECLARE @_querySchema NVARCHAR(MAX) ;
        IF @Database <> ''
        BEGIN
            DECLARE @_fullTableName NVARCHAR(MAX) = @Table ;
            IF UPPER(LEFT(@_fullTableName , LEN(@Database))) <> UPPER(@Database)
                SET @_fullTableName = @Database + '.' + @_fullTableName ; 
            SET @_queryTable = 'SELECT @out = OBJECT_NAME(OBJECT_ID('''
                + REPLACE(@_fullTableName , '''' , '''''') + ''''
                + ') , DB_ID(''' + REPLACE(@Database , '''' , '''''') + '''))' ;
            SET @_querySchema = 'SELECT @out = OBJECT_SCHEMA_NAME(OBJECT_ID('''
                + REPLACE(@_fullTableName , '''' , '''''') + ''''
                + ') , DB_ID(''' + REPLACE(@Database , '''' , '''''') + '''))' ;
        END
        ELSE
        BEGIN
            SET @_queryTable = 'SELECT @out = OBJECT_NAME(OBJECT_ID(''' + REPLACE(@Table , '''' , '''''') + '''))' ;
            SET @_querySchema = 'SELECT @out = OBJECT_SCHEMA_NAME(OBJECT_ID(''' + REPLACE(@Table , '''' , '''''') + '''))' ;
        END ;
        EXECUTE sp_executesql @_queryTable , @_parameterDefinition , @out = @_sourceTableName OUTPUT ;
        EXECUTE sp_executesql @_querySchema , @_parameterDefinition , @out = @_sourceTableSchema OUTPUT ;
        --SELECT @_sourceTableName , @_sourceTableSchema ;
    END ;

    IF @Pretend = 1
        PRINT @SQL ;
    ELSE
        EXECUTE sp_executesql @SQL ;

    RETURN 0;
END

GO
