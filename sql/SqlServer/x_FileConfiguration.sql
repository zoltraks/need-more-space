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
