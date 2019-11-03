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
