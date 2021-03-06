IF OBJECT_ID ( 'dbo.x_SystemVersion' ) IS NULL
EXEC sp_executesql N'CREATE PROCEDURE dbo.x_SystemVersion AS BEGIN RETURN 0; END' ;

GO

--
-- Show version information.
--
ALTER PROCEDURE dbo.x_SystemVersion ( @Help BIT = 0 )
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
    END

	DECLARE @Report TABLE
	(
		[_] INT IDENTITY(1,1),
		[Name] NVARCHAR(50) ,
		[Value] NVARCHAR(4000)
	)

	INSERT INTO @Report ( [Name] , [Value] ) VALUES ( 'Version' , CONVERT(NVARCHAR , SERVERPROPERTY('ProductVersion')) ) ;
	INSERT INTO @Report ( [Name] , [Value] ) VALUES ( 'Product' , @@VERSION ) ;
	INSERT INTO @Report ( [Name] , [Value] ) VALUES ( 'Edition' , CONVERT(NVARCHAR(100) , SERVERPROPERTY('Edition')) ) ;
	INSERT INTO @Report ( [Name] , [Value] ) VALUES ( 'Level' , CONVERT(NVARCHAR(100) , SERVERPROPERTY('ProductLevel')) ) ;

	SELECT
	 [Name _____________] = [Name]
	 ,
	 [Value __________________________________________________________________________________________________________________________] = [Value]
	FROM @Report 
	ORDER BY [_]

    RETURN 0 ;
END

GO
