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
