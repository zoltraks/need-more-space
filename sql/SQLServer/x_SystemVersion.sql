IF OBJECT_ID ( 'dbo.x_SystemVersion' ) IS NULL
EXEC sp_executesql N'CREATE PROCEDURE dbo.x_SystemVersion AS BEGIN RETURN 0; END' ;

GO

--
-- Show version information.
--
ALTER PROCEDURE dbo.x_SystemVersion ( @Help BIT = 0 )
AS
BEGIN
    SET NOCOUNT ON ;

    DECLARE @Utility NVARCHAR(20) = '22.05.28' ;

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
            ( '@Help' , 'BIT' , 'Show this help' )
            ;
        SELECT [Parameter] , [Type] , [Description                                                                     ] = [Description] FROM @Parameter ;

        DECLARE @Description TABLE
        (
            [Description] NVARCHAR(200)
        );
        INSERT INTO @Description ( [Description] )
        VALUES
            ( 'Show version information.' )
            ;
        SELECT [Description                                                                     ] = [Description] FROM @Description ;
        
        RETURN 0 ;
    END ;

    DECLARE @Report TABLE
    (
        [_] INT IDENTITY(1,1),
        [Name] NVARCHAR(50) ,
        [Value] NVARCHAR(4000)
    ) ;

    DECLARE @VersionNumber VARCHAR(20) ;
    DECLARE @VersionUpdate VARCHAR(20) ;
    DECLARE @VersionFamily VARCHAR(50) ;

    SET @VersionNumber = CONVERT(VARCHAR(20) , SERVERPROPERTY('ProductVersion')) ;

    IF OBJECT_ID('v_VersionList', 'TF') IS NOT NULL
    BEGIN TRY
        SELECT @VersionUpdate = v.[Update] , @VersionFamily = v.[Family] FROM v_VersionList() v WHERE v.[Version] = @VersionNumber ;
    END TRY
    BEGIN CATCH
    END CATCH ;

    INSERT INTO @Report ( [Name] , [Value] ) VALUES ( 'Version' , CONVERT(NVARCHAR , SERVERPROPERTY('ProductVersion')) ) ;
    IF @VersionFamily IS NOT NULL  
        INSERT INTO @Report ( [Name] , [Value] ) VALUES ( 'Family' , @VersionFamily ) ;
    IF @VersionUpdate IS NOT NULL  
        INSERT INTO @Report ( [Name] , [Value] ) VALUES ( 'Update' , @VersionUpdate ) ;
    INSERT INTO @Report ( [Name] , [Value] ) VALUES ( 'Edition' , CONVERT(NVARCHAR(100) , SERVERPROPERTY('Edition')) ) ;
    INSERT INTO @Report ( [Name] , [Value] ) VALUES ( 'Level' , CONVERT(NVARCHAR(100) , SERVERPROPERTY('ProductLevel')) ) ;

    INSERT INTO @Report ( [Name] , [Value] ) VALUES ( 'Product' , @@VERSION ) ;

    INSERT INTO @Report ( [Name] , [Value] ) VALUES ( 'Utility' , @Utility ) ;

    SELECT
       [Name _____________] = [Name]
       ,
       [Value __________________________________________________________________________________________________________________________] = [Value]
    FROM @Report 
    ORDER BY [_]

    RETURN 0 ;
END ;

GO
