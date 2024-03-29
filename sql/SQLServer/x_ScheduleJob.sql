IF OBJECT_ID ( 'dbo.x_ScheduleJob' ) IS NULL
EXEC sp_executesql N'CREATE PROCEDURE dbo.x_ScheduleJob AS BEGIN RETURN 0 ; END' ;

GO

--
-- Add job and schedule execution plan.
--
ALTER PROCEDURE dbo.x_ScheduleJob
(
    @Help BIT = NULL
    ,
    @Pretend BIT = NULL
    ,
    @Name NVARCHAR(128) = NULL
    ,
    @Command NVARCHAR(MAX) = NULL
    ,
    @Database NVARCHAR(128) = NULL
    ,
    @Owner NVARCHAR(128) = NULL
    ,
    @Enable BIT = NULL
    ,
    @Type NVARCHAR(10) = NULL
    ,
    @Interval INT = NULL
    ,
    @Repeat NVARCHAR(10) = NULL
    ,
    @Every INT = NULL
    ,
    @Relative INT = NULL
    ,
    @StartDate INT = NULL
    ,
    @EndDate INT = NULL
    ,
    @StartTime INT = NULL
    ,
    @EndTime INT = NULL
    ,
    @OutputFile NVARCHAR(200) = NULL
    ,
    @Overwrite BIT = NULL
    ,
    @Subsystem NVARCHAR(40) = NULL
)
AS
BEGIN
    SET NOCOUNT ON ;

    IF @Help = 1
    BEGIN
        DECLARE @Parameter TABLE
        (
            [Parameter] NVARCHAR(20) ,
            [Type] NVARCHAR(20) ,
            [Description] NVARCHAR(500)
        ) ;
        INSERT INTO @Parameter ( [Parameter] , [Type] , [Description] )
        VALUES
            ( '@Help' , 'BIT' , 'Show this help.' )
            ,
            ( '@Pretend' , 'BIT' , 'Print queries to be executed but don''t do anything.' )
            ,
            ( '@Name' , 'NVARCHAR(128)' , 'Desired job name. It will be used for step name too.' )
            ,
            ( '@Command' , 'NVARCHAR(MAX)' , 'Command text for job step.' )
            ,
            ( '@Database' , 'NVARCHAR(128)' , 'Database job will be run on. Current database will be used if not specified.' )
            ,
            ( '@Owner' , 'NVARCHAR(128)' , 'Owner name.' )
            ,
            ( '@Enable' , 'BIT' , 'Enable job.' )
            ,
            ( '@Type' , 'NVARCHAR(10)' , 'A value indicating when a job is to be executed. Valid value is one of ''DAILY'', ''WEEKLY'', ''MONTHLY'', ''RELATIVE'', ''START'', ''IDLE'', ''ONCE'' or ''NONE''.' )
            ,
            ( '@Interval' , 'INT' , 'Days that a job is executed.' )
            ,
            ( '@Repeat' , 'NVARCHAR(10)' , 'Specifies units for repeat interval. Valid value is one of ''HOURS'', ''MINUTES'', ''SECONDS'', ''ONCE'' or ''NONE''.' )
            ,
            ( '@Every' , 'INT' , 'Specifies value for repeat interval. That is number of hours, minutes or seconds depending on chosen repeat interval unit.' )
            ,
            ( '@Relative' , 'INT' , 'When schedule type is relative, this value indicates job''s occurrence in each month.' )
            ,
            ( '@StartDate' , 'INT' , 'Start date written in YYMMDD format.' )
            ,
            ( '@EndDate' , 'INT' , 'End date written in YYMMDD format.' )
            ,
            ( '@StartTime' , 'INT' , 'Start time written in HHMMSS 24 hour format.' )
            ,
            ( '@EndTime' , 'INT' , 'End time written in HHMMSS 24 hour format.' )
            ,
            ( '@OutputFile' , 'NVARCHAR(200)' , 'Output file for job.' )
            ,
            ( '@Overwrite' , 'BIT' , 'Overwrite output instead of append.' )
            ,
            ( '@Subsystem' , 'NVARCHAR(40)' , 'Subsystem used by the SQL Server Agent service to execute command. Default is ''TSQL''.' )
            ;
        SELECT [Parameter] , [Type] , [Description ____________________________________________________________________________________________] = [Description] FROM @Parameter ;

        DECLARE @Description TABLE
        (
            [Description] NVARCHAR(200)
        );
        INSERT INTO @Description
        VALUES
            ( 'Add job and schedule execution plan.' )
            ,
            ( 'EXEC dbo.x_ScheduleJob @Pretend=1 , @Name=''JobOne'' , @Type=''Daily'' , @Repeat=''Minutes'' , @Every=''15'' , @Command=N''SELECT 1'' ;' )
            ;
        SELECT [Description ____________________________________________________________________________________________] = [Description] FROM @Description ;
        
        RETURN ;
    END ;

    SET @Pretend = ISNULL(@Pretend , 0) ;
    SET @Name = ISNULL(@Name , '') ;
    SET @Database = ISNULL(@Database , '') ;
    SET @Owner = ISNULL(@Owner , '') ;
    SET @Enable = ISNULL(@Enable , 0) ;
    SET @Type = UPPER(ISNULL(@Type, '')) ;
    SET @Interval = ISNULL(@Interval , 1) ;
    SET @Repeat = UPPER(ISNULL(@Repeat, '')) ;
    SET @Every = ISNULL(@Every , 0) ;
    SET @Relative = ISNULL(@Relative , 0) ;
    SET @StartDate = ISNULL(@StartDate , 20000101) ;
    SET @EndDate = ISNULL(@EndDate , 99991231) ;
    SET @StartTime = ISNULL(@StartTime , -1) ;
    SET @EndTime = ISNULL(@EndTime , -1) ;
    SET @OutputFile = ISNULL(@OutputFile , '') ;
    SET @Overwrite = ISNULL(@Every , 0) ;
    SET @Subsystem = ISNULL(@Subsystem , 'TSQL') ;

    IF 0 = LEN(@Name)
    BEGIN
        RAISERROR ( 'Job name must be specified. Use @Help=1 to see options.' , 18 , 1 ) ;
        RETURN -1 ;
    END ;

    DECLARE @freq_type INT ;

    SET @freq_type = CASE
        WHEN 1 = ISNUMERIC(@Type + '.e0') THEN CONVERT(INT , @Type)
        WHEN @Type = 'N' OR @Type = 'NONE' OR @Type = '' THEN 0
        WHEN @Type = 'O' OR @Type = 'ONCE' THEN 1
        WHEN @Type = 'D' OR @Type = 'DAILY' THEN 4
        WHEN @Type = 'W' OR @Type = 'WEEKLY' THEN 8
        WHEN @Type = 'M' OR @Type = 'MONTHLY' THEN 16
        WHEN @Type = 'R' OR @Type = 'RELATIVE' THEN 32
        WHEN @Type = 'S' OR @Type = 'START' THEN 64
        WHEN @Type = 'I' OR @Type = 'IDLE' THEN 128
        ELSE -1
    END ;

    IF 0 > @freq_type
    BEGIN
        RAISERROR ( 'Bad value for @Type parameter. Must be number or one of ''DAILY'', ''WEEKLY'', ''MONTHLY'', ''RELATIVE'', ''START'', ''IDLE'', ''ONCE'' or ''NONE''.' , 18 , 1 ) ;
        RETURN -1 ;
    END ;

    DECLARE @freq_subday_type INT ;

    SET @freq_subday_type = CASE
        WHEN 1 = ISNUMERIC(@Repeat + '.e0') THEN CONVERT(INT , @Repeat)
        WHEN @Repeat = 'N' OR @Repeat = 'NONE' OR @Repeat = '' THEN 0
        WHEN @Repeat = 'O' OR @Repeat = 'ONCE' THEN 1
        WHEN @Repeat = 'H' OR @Repeat = 'HOURS' THEN 8
        WHEN @Repeat = 'M' OR @Repeat = 'MINUTES' THEN 4
        WHEN @Repeat = 'S' OR @Repeat = 'SECONDS' THEN 2
        ELSE -1
    END ;

    IF 0 > @freq_subday_type
    BEGIN
        RAISERROR ( 'Bad value for @Repeat parameter. Must be number or one of ''HOURS'', ''MINUTES'', ''SECONDS'', ''ONCE'' or ''NONE''.' , 18 , 1 ) ;
        RETURN -1 ;
    END ;

    IF 0 = LEN(@Database)
        SET @Database = DB_NAME() ;

    DECLARE @_Name NVARCHAR(256) = 'N' + QUOTENAME(@Name , '''') ;
    DECLARE @_Database NVARCHAR(256) = 'N' + QUOTENAME(@Database , '''') ;

    DECLARE @Script NVARCHAR(MAX) ;

    SET @Script = '' ;

    SET @Script = @Script + 'IF EXISTS ( SELECT 1 FROM msdb.dbo.sysjobs WHERE [name] = ' + @_Name + ' )' ;
    SET @Script = @Script + CHAR(13) + CHAR(10) ;

    SET @Script = @Script + 'EXEC sp_executesql N'''
        + REPLACE('EXEC msdb.dbo.sp_delete_job @job_name = ' + @_Name + ' , @delete_unused_schedule = 0' , '''' , '''''')
        + ''' ;' ;
    SET @Script = @Script + CHAR(13) + CHAR(10) ;
    SET @Script = @Script + CHAR(13) + CHAR(10) ;

    SET @Script = @Script + 'EXEC msdb.dbo.sp_add_job @job_name = ' + @_Name ;
    IF 0 < LEN(@Owner)
        SET @Script = @Script + ' , @owner_login_name = N' + QUOTENAME(@Owner , '''');
    SET @Script = @Script + ' ;' ;
    SET @Script = @Script + CHAR(13) + CHAR(10) ;
    SET @Script = @Script + CHAR(13) + CHAR(10) ;

    SET @Script = @Script + 'EXEC msdb.dbo.sp_add_jobstep' ;
    SET @Script = @Script + CHAR(13) + CHAR(10) ;
    SET @Script = @Script + '  @job_name = ' + @_Name + ' ,' + CHAR(13) + CHAR(10) ;
    SET @Script = @Script + '  @step_name = ' + @_Name + ' ,' + CHAR(13) + CHAR(10) ;
    SET @Script = @Script + '  @database_name = ' + @_Database + ' ,' + CHAR(13) + CHAR(10) ;
    SET @Script = @Script + '  @subsystem = N''' + @Subsystem + ''' ,' + CHAR(13) + CHAR(10) ;
    IF @OutputFile <> ''
    BEGIN
        SET @Script = @Script + '  @output_file_name = N''' + REPLACE(@OutputFile , '''' , '''''') + ''' ,' ;
        SET @Script = @Script + CHAR(13) + CHAR(10) ;
        IF @Overwrite = 1
          SET @Script = @Script + '  @flags = 0 ,' + CHAR(13) + CHAR(10) ;
        ELSE
          SET @Script = @Script + '  @flags = 2 ,' + CHAR(13) + CHAR(10) ;
    END ;
    SET @Script = @Script + '  @command = ' ;
    SET @Script = @Script + 'N''' + REPLACE(@Command , '''' , '''''') + '''' ;
    SET @Script = @Script + ' ;' + CHAR(13) + CHAR(10) ;
    SET @Script = @Script + CHAR(13) + CHAR(10) ;

    SET @Script = @Script + 'IF EXISTS ( SELECT 1 FROM msdb.dbo.sysschedules WHERE [name] = ' + @_Name + ' )' ;
    SET @Script = @Script + CHAR(13) + CHAR(10) ;

    SET @Script = @Script + 'EXEC sp_executesql ' ;
    SET @Script = @Script + 'N''' + REPLACE('EXEC msdb.dbo.sp_delete_schedule @schedule_name = ' + @_Name + ' , @force_delete = 1' , '''' , '''''') + '''' ;
    SET @Script = @Script + '  ;' + CHAR(13) + CHAR(10) ;
    SET @Script = @Script + CHAR(13) + CHAR(10) ;

    IF 0 < @freq_type
    BEGIN
        SET @Script = @Script + 'EXEC msdb.dbo.sp_add_schedule' + CHAR(13) + CHAR(10) ;
        SET @Script = @Script + '  @schedule_name = ' + @_Name + ' ,' + CHAR(13) + CHAR(10) ;
        SET @Script = @Script + '  @freq_type = ' + CONVERT(VARCHAR(3) , @freq_type) + ' ,' + CHAR(13) + CHAR(10) ;
        SET @Script = @Script + '  @freq_interval = ' + CONVERT(VARCHAR(3) , @Interval) + ' ,' + CHAR(13) + CHAR(10) ;
        IF 0 < @freq_subday_type
            SET @Script = @Script + '  @freq_subday_type = ' + CONVERT(VARCHAR(3) , @freq_subday_type) + ' ,' + CHAR(13) + CHAR(10) ;
        IF 0 < @Every
            SET @Script = @Script + '  @freq_subday_interval = ' + CONVERT(VARCHAR(8) , @Every) + ' ,' + CHAR(13) + CHAR(10) ;
        IF 0 < @Relative
            SET @Script = @Script + '  @freq_relative_interval = ' + CONVERT(VARCHAR(3) , @Relative) + ' ,' + CHAR(13) + CHAR(10) ;
        IF 0 < @StartDate
            SET @Script = @Script + '  @active_start_date = ' + CONVERT(VARCHAR(8) , @StartDate) + ' ,' + CHAR(13) + CHAR(10) ;
        IF 0 < @EndDate
            SET @Script = @Script + '  @active_end_date = ' + CONVERT(VARCHAR(8) , @EndDate) + ' ,' + CHAR(13) + CHAR(10) ;
        IF 0 <= @StartTime
            SET @Script = @Script + '  @active_start_time = ' + CONVERT(VARCHAR(6) , @StartTime) + ' ,' + CHAR(13) + CHAR(10) ;
        IF 0 <= @EndTime
            SET @Script = @Script + '  @active_end_time = ' + CONVERT(VARCHAR(6) , @EndTime) + ' ,' + CHAR(13) + CHAR(10) ;
        IF 0 < LEN(@Owner)
            SET @Script = @Script + '  @owner_login_name = N' + QUOTENAME(@Owner , '''') + ' ,' + CHAR(13) + CHAR(10) ;
        SET @Script = @Script + '  @enabled = ' + CONVERT(CHAR(1) , @Enable) ;
        SET @Script = @Script + ' ;' + CHAR(13) + CHAR(10) ;
        SET @Script = @Script + CHAR(13) + CHAR(10) ;
        
        SET @Script = @Script + 'EXEC msdb.dbo.sp_attach_schedule @job_name = ' + @_Name + ' , @schedule_name = ' + @_Name + ' ;' ;
        SET @Script = @Script + CHAR(13) + CHAR(10) ;
        SET @Script = @Script + CHAR(13) + CHAR(10) ;
    END ;

    SET @Script = @Script + 'EXEC msdb.dbo.sp_add_jobserver @job_name = ' + @_Name + ' ;' ;
    SET @Script = @Script + CHAR(13) + CHAR(10) ;
    
    -- Print or execute --

    IF @Pretend = 1
    BEGIN
        PRINT @Script ;
        RETURN 0 ;
    END ;
    ELSE
    BEGIN
        EXECUTE sp_executesql @Script ;
        RETURN 1 ;
    END ;
END ;

GO
