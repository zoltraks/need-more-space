IF OBJECT_ID ( 'dbo.x_SystemConfiguration' ) IS NULL
EXEC sp_executesql N'CREATE PROCEDURE dbo.x_SystemConfiguration AS BEGIN RETURN 0; END' ;

GO

--
-- Show system configuration.
--
ALTER PROCEDURE dbo.x_SystemConfiguration ( @Script BIT = 0 , @Pretend BIT = 0 , @Help BIT = 0 )
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
            ( '@Script' , 'BIT' , 'Include extra column with SQL statements' )
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
            ( 'Show system configuration.' )
            ;
        SELECT [Description                                                                     ] = [Description] FROM @Description ;
        
        RETURN 0 ;
    END ;

    DECLARE @ServerFamily INT = CONVERT(INT,SUBSTRING(
        CONVERT(NVARCHAR(20) , SERVERPROPERTY('productversion')),1,
        CHARINDEX('.',CONVERT(NVARCHAR(20) , SERVERPROPERTY('productversion')),1)-1
    )) ;

    --SELECT @ServerFamily

    DECLARE @ReportDatabaseScopedConfiguration TABLE
    (
        [_] INT IDENTITY(1,1) NOT NULL ,
        [name] NVARCHAR(100) NULL ,
        [value] NVARCHAR(20) NULL ,
        [is_value_default] BIT NULL ,
        [script] NVARCHAR(200) NULL ,
        --INDEX UC UNIQUE CLUSTERED ( _ ) -- syntax will not work for 2012
        UNIQUE CLUSTERED ( _ )
    ) ;

    DECLARE @Q NVARCHAR(MAX) ;

    DECLARE @S NVARCHAR(MAX) ;

    SET @S = '' ;

    SET @Q = '' ;

    IF @ServerFamily >= 13 -- 2016 or newer
    BEGIN
        SET @Q = @Q + '
SELECT [name],CONVERT(VARCHAR(20) , [value]) AS [value],[is_value_default]' ;
        IF @Script = 1
            SET @Q = @Q + '
    , ''ALTER DATABASE SCOPED CONFIGURATION SET '' + [name] + '' = ''
    + CASE
        WHEN [name] = ''MAXDOP'' OR [name] LIKE ''%_MINUTES'' THEN CONVERT(VARCHAR(20) , [value])
        WHEN [value] = 1 THEN ''ON''
        WHEN [value] = 0 THEN ''OFF''
        ELSE CONVERT(VARCHAR(20) , [value])
    END AS [script]' ;
        SET @Q = @Q + '
FROM sys.database_scoped_configurations
ORDER BY [name]
' ;

    END ;

    SET @Q = @Q + '
SELECT
    UPPER([name]) AS [name],
	CONVERT(NVARCHAR(50) , [value_in_use]) AS [value],
	CASE WHEN [value] = [value_in_use] THEN 1 ELSE 0 END AS [is_value_default]
FROM sys.configurations
ORDER BY [name]
';

    SET @S = @S + @Q ;

    IF @Pretend = 0
    BEGIN
        IF @ServerFamily >= 13 -- 2016 or newer
        INSERT INTO @ReportDatabaseScopedConfiguration
        SELECT [name],CONVERT(VARCHAR(20) , [value]) AS [value],[is_value_default]
            , 'ALTER DATABASE SCOPED CONFIGURATION SET ' + [name] + ' = ' 
            + CASE
                WHEN [name] = 'MAXDOP' OR [name] LIKE '%_MINUTES' THEN CONVERT(VARCHAR(20) , [value])
                WHEN [value] = 1 THEN 'ON'
                WHEN [value] = 0 THEN 'OFF'
                ELSE CONVERT(VARCHAR(20) , [value])
            END AS [script]
        FROM sys.database_scoped_configurations
        ORDER BY [name]
    END ;

    IF @Pretend = 0
    BEGIN
        INSERT INTO @ReportDatabaseScopedConfiguration
        SELECT
            UPPER([name]) AS [name],
            CONVERT(NVARCHAR(50) , [value_in_use]) AS [value],
            CASE WHEN [value] = [value_in_use] THEN 1 ELSE 0 END AS [is_value_default],
            ''
        FROM sys.configurations
        ORDER BY [name]
    END ;

    IF @Pretend = 1
        PRINT @S ;
    ELSE
    BEGIN
        IF @Script = 1
            SELECT [name] , [value] , [is_value_default] , [script] FROM @ReportDatabaseScopedConfiguration ;
        ELSE
            SELECT [name] , [value] , [is_value_default] FROM @ReportDatabaseScopedConfiguration ;
    END ;

    RETURN 0 ;
END ;

GO
