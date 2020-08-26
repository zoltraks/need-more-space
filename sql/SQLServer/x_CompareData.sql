IF OBJECT_ID ( 'dbo.x_CompareData' ) IS NULL
EXEC sp_executesql N'CREATE PROCEDURE dbo.x_CompareData AS BEGIN RETURN 0 ; END'

GO

--
-- Compare data from one table with another.
--
ALTER PROCEDURE dbo.x_CompareData
( 
    @Source NVARCHAR(MAX) = NULL , @Destination NVARCHAR(MAX) = NULL
	,
	@Keys NVARCHAR(MAX) = NULL , @Values NVARCHAR(MAX) = NULL
	,
    @Select BIT = NULL , @Update BIT = NULL , @Insert BIT = NULL , @Delete BIT = NULL
	,
	@Merge BIT = NULL
    ,
    @OperationAlias NVARCHAR(128)= NULL
    ,
    @NullValue NVARCHAR(128) = NULL
    ,
    @Pretend BIT = NULL , @Help BIT = NULL 
)
AS
BEGIN
    SET NOCOUNT ON ;

    IF ISNULL(@Help , 0) = 1
    BEGIN
        DECLARE @Parameter TABLE
        (
            [Parameter] NVARCHAR(20) ,
            [Type] NVARCHAR(20) ,
            [Description] NVARCHAR(500)
        );
        INSERT INTO @Parameter ( [Parameter] , [Type] , [Description] )
        VALUES
            ( '@Help' , 'BIT' , 'Show this help.' )
            ,
            ( '@Pretend' , 'BIT' , 'Print queries to be executed but don''t do anything. It will however read column definition from source table.' )
            ,
            ( '@Source' , 'NVARCHAR(MAX)' , 'Full path to source table.' )
            ,
            ( '@Destination' , 'NVARCHAR(MAX)' , 'Full path to destination table.' )
            ,
            ( '@Keys' , 'NVARCHAR(MAX)' , 'Optional list of key columns. If no key column is specified, primary key will be used for checking.' )
            ,
            ( '@Values' , 'NVARCHAR(MAX)' , 'Optional list of value columns. Only these columns will be checked for differences.' )
            ,
            ( '@Merge' , 'BIT' , 'Perform required INSERT / DELETE / UPDATE operations to remove differences.' )
            ,
            ( '@Select' , 'BIT' , 'Show differences (default).' )
            ,
            ( '@Update' , 'BIT' , 'Update destination table to remove differences.' )
            ,
            ( '@Insert' , 'BIT' , 'Insert missing records to destination table.' )
            ,
            ( '@Delete' , 'BIT' , 'Delete non existing records from destination table.' )
            ,
            ( '@OperationAlias' , 'NVARCHAR(128)' , 'Column alias for operation text.' )
            ,
            ( '@NullValue' , 'NVARCHAR(128)' , 'Optional text value for NULL setting.' )
            ;
        SELECT [Parameter] , [Type] , [Description ____________________________________________________________________________________________] = [Description] FROM @Parameter ;

        DECLARE @Description TABLE
        (
            [Description] NVARCHAR(200)
        );
        INSERT INTO @Description
        VALUES
            ( 'Compare data from one table with another.' )
            ;
        SELECT [Description ____________________________________________________________________________________________] = [Description] FROM @Description ;
        
        RETURN;
    END

	SET @Pretend = ISNULL(@Pretend , 0) ;
	SET @Select = ISNULL(@Select , 1) ;
	SET @Update = ISNULL(@Update , 1) ;
	SET @Insert = ISNULL(@Insert , 1) ;
	SET @Delete = ISNULL(@Delete , 1) ;
	SET @Merge = ISNULL(@Merge , 0) ;

    SET @OperationAlias = ISNULL(@OperationAlias , '!') ;
    IF @OperationAlias <> '' AND '[' <> SUBSTRING(@OperationAlias , 1 , 1)
    BEGIN
      SET @OperationAlias = QUOTENAME(@OperationAlias) ;
    END ;

    SET @NullValue = ISNULL(@NullValue , '<?_NULL_?>') ;
    IF @NullValue <> '' AND '''' <> SUBSTRING(@NullValue , 1 , 1)
    BEGIN
      SET @NullValue = QUOTENAME(@NullValue , '''') ;
    END ;

    --SET @Create = ISNULL(@Create , 0) ;
    --SET @Drop = ISNULL(@Drop , 0) ;
    --SET @Copy = ISNULL(@Copy , 0) ;
    --SET @Delete = ISNULL(@Delete , 0) ;

    --SET @IncludeIdentity = ISNULL(@IncludeIdentity , 0) ;
    --SET @IncludeComputed = ISNULL(@IncludeComputed , 0) ;
    --SET @IdentityNullable = ISNULL(@IdentityNullable , 0) ;

    --SET NOCOUNT ON ;

    DECLARE @SourceCatalog NVARCHAR(500) ;
    DECLARE @SourceSchema NVARCHAR(500) ;
    DECLARE @SourceTable NVARCHAR(500) ;

	DECLARE @Text NVARCHAR(MAX) ;

	-- Extract parts from source object name --

	DECLARE CR_1 CURSOR FOR
	SELECT _.[Text] FROM (
      SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) [Row] , [Text]
      FROM v_SplitText(@Source , '.' , '[' , 1)
    ) _
    ORDER BY _.[Row] DESC
	;

	OPEN CR_1 ;
	WHILE 1 = 1
	BEGIN
	  FETCH NEXT FROM CR_1 INTO @Text ;
	  IF @@FETCH_STATUS <> 0 BREAK ;
	  IF @SourceTable IS NULL
	  BEGIN
	    SET @SourceTable = @Text ;
		CONTINUE ;
	  END ;
	  IF @SourceSchema IS NULL
	  BEGIN
	    SET @SourceSchema = @Text ;
		CONTINUE ;
	  END ;
	  IF @SourceCatalog IS NULL
	  BEGIN
	    SET @SourceCatalog = QUOTENAME(@Text) ;
		CONTINUE ;
	  END ;
	  SET @SourceCatalog = QUOTENAME(@Text) + '.' + @SourceCatalog ;
	END ;
	CLOSE CR_1 ;
	DEALLOCATE CR_1 ;

    IF '' = ISNULL(@SourceSchema , '')
    BEGIN
      SET @SourceSchema = 'dbo' ;
    END ;

	IF @SourceCatalog IS NULL
	BEGIN
	  SET @SourceCatalog = QUOTENAME(DB_NAME()) ;
	END ;

    DECLARE @Query NVARCHAR(MAX) ;

	-- Read list of columns in source table --

    SET @Query = '
SELECT c.[name] AS [Name]
, UPPER(y.[name]) AS [Type]
, c.[is_nullable] AS [Nullable]
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

    SET @Query = REPLACE(@Query , ':source:' , @SourceCatalog) ;
    SET @Query = REPLACE(@Query , ':table:' , QUOTENAME(@SourceTable, '''')) ;
    SET @Query = REPLACE(@Query , ':schema:' , QUOTENAME(@SourceSchema, '''')) ;

    SET @Query = 'SET @CursorColumns = CURSOR FAST_FORWARD FOR' + CHAR(13) + CHAR(10) + @Query ;
    SET @Query = @Query + CHAR(13) + CHAR(10) + 'OPEN @CursorColumns ;' ;

    DECLARE @CursorColumns CURSOR ;

    DECLARE @Columns TABLE
    (
        [Name] NVARCHAR(128) ,
        [Type] NVARCHAR(128) ,
        [Nullable] BIT ,
        [Computed] BIT ,
        [Identity] BIT ,
        [Precision] INT ,
        [Scale] INT ,
        [Length] INT
    ) ;

    DECLARE @ColumnName NVARCHAR(128) ;
    DECLARE @ColumnType NVARCHAR(128) ;
    DECLARE @ColumnNullable BIT ;
    DECLARE @ColumnComputed BIT ;
    DECLARE @ColumnIdentity BIT ;
    DECLARE @ColumnPrecision INT ;
    DECLARE @ColumnScale INT ;
    DECLARE @ColumnLength INT ;

    DECLARE @CreateScript NVARCHAR(MAX) = '' ;

    EXECUTE sp_executesql @Query , N'@CursorColumns CURSOR OUTPUT' , @CursorColumns = @CursorColumns OUTPUT ;

    WHILE 1 = 1
    BEGIN
        FETCH NEXT FROM @CursorColumns INTO @ColumnName , @ColumnType , @ColumnNullable , @ColumnComputed , @ColumnIdentity , @ColumnPrecision , @ColumnScale , @ColumnLength ;
        IF @@FETCH_STATUS <> 0 BREAK ;

        INSERT INTO @Columns VALUES ( @ColumnName , @ColumnType , @ColumnNullable , @ColumnComputed , @ColumnIdentity , @ColumnPrecision , @ColumnScale , @ColumnLength ) ;

		IF @ColumnIdentity = 1
		BEGIN
		  IF '' = ISNULL(@Keys , '')
		  BEGIN
		    SET @Keys = QUOTENAME(@ColumnName) ;
		  END ;
		  CONTINUE ;
		END ;

        IF @ColumnComputed = 1
		BEGIN
		  CONTINUE ;
		END ;

    END

    CLOSE @CursorColumns ;
    DEALLOCATE @CursorColumns ;

	-- Extract list of key and value columns --

	DECLARE @KeyColumnTable TABLE ( [Index] INT IDENTITY(1,1) , [Name] NVARCHAR(MAX) ) ;
    DECLARE @ValueColumnTable TABLE ( [Index] INT IDENTITY(1,1) , [Name] NVARCHAR(MAX) ) ;
    DECLARE @AllColumnTable TABLE ( [Name] NVARCHAR(MAX) ) ;

	DECLARE CR_2 CURSOR FOR
	SELECT [Text] FROM v_SplitText(@Keys , DEFAULT , DEFAULT , 1)
	;
	OPEN CR_2 ;
	WHILE 1 = 1
	BEGIN
	  FETCH NEXT FROM CR_2 INTO @Text ;
	  IF @@FETCH_STATUS <> 0 BREAK ;
	  IF @Text = '' CONTINUE ;
	  IF NOT EXISTS ( SELECT 1 FROM @Columns WHERE UPPER([Name]) = UPPER(@Text) )
	  BEGIN
	    SET @Text = 'Column ' + QUOTENAME(@Text) + ' does not exist' ;
      	CLOSE CR_2 ;
	    DEALLOCATE CR_2;
	    RAISERROR ( @Text , 18 , 1 ) ;
        RETURN -1 ;
      END ;
	  INSERT INTO @KeyColumnTable VALUES ( @Text ) ;
      INSERT INTO @AllColumnTable VALUES ( @Text ) ;
	END ;
	CLOSE CR_2 ;
	DEALLOCATE CR_2;

	DECLARE CR_3 CURSOR FOR
	SELECT [Text] FROM v_SplitText(@Values , DEFAULT , DEFAULT , 1)
	;
	OPEN CR_3 ;
	WHILE 1 = 1
	BEGIN
	  FETCH NEXT FROM CR_3 INTO @Text ;
	  IF @@FETCH_STATUS <> 0 BREAK ;
      IF @Text = '' CONTINUE ;
      IF NOT EXISTS ( SELECT 1 FROM @Columns WHERE UPPER([Name]) = UPPER(@Text) )
	  BEGIN
	    SET @Text = 'Column ' + QUOTENAME(@Text) + ' does not exist' ;
      	CLOSE CR_3 ;
	    DEALLOCATE CR_3;
	    RAISERROR ( @Text , 18 , 1 ) ;
        RETURN -1 ;
      END ;
	  IF EXISTS ( SELECT 1 FROM @KeyColumnTable WHERE UPPER([Name]) = UPPER(@Text) )
	  BEGIN
	    SET @Text = 'Column ' + QUOTENAME(@Text) + ' is part of record key' ;
      	CLOSE CR_3 ;
	    DEALLOCATE CR_3;
	    RAISERROR ( @Text , 18 , 1 ) ;
        RETURN -1 ;
      END ;
	  INSERT INTO @ValueColumnTable VALUES ( @Text ) ;
      INSERT INTO @AllColumnTable VALUES ( @Text ) ;
	END ;
	CLOSE CR_3 ;
	DEALLOCATE CR_3;

	IF NOT EXISTS ( SELECT TOP(1) 1 FROM @KeyColumnTable )
	BEGIN
      RAISERROR ( 'No column is specified for record key' , 18 , 1 ) ;
      RETURN -1 ;
    END ;

	IF NOT EXISTS ( SELECT TOP(1) 1 FROM @ValueColumnTable )
	BEGIN
	  DECLARE CR_4 CURSOR FOR
	  SELECT [Name] FROM @Columns
	  ;
	  OPEN CR_4 ;
	  WHILE 1 = 1
	  BEGIN
	    FETCH NEXT FROM CR_4 INTO @Text ;
	    IF @@FETCH_STATUS <> 0 BREAK ;
        IF @Text = '' CONTINUE ;
	    IF EXISTS ( SELECT 1 FROM @KeyColumnTable WHERE UPPER([Name]) = UPPER(@Text) )
	    BEGIN
	      CONTINUE ;
        END ;
	    INSERT INTO @ValueColumnTable VALUES ( @Text ) ;
        INSERT INTO @AllColumnTable VALUES ( @Text ) ;
	  END ;
	  CLOSE CR_4 ;
  	  DEALLOCATE CR_4;
	END ;
    
    DECLARE @I INT ;
    DECLARE @K INT ;
    DECLARE @N INT ;

    DECLARE @Column NVARCHAR(MAX) ;
    DECLARE @Type NVARCHAR(MAX) ;
    DECLARE @IsKey BIT ;
    DECLARE @IsValue BIT ;

    DECLARE @ColumnsA NVARCHAR(MAX) = '' ;
    DECLARE @ColumnsJ NVARCHAR(MAX) = '' ;
    DECLARE @ColumnsD NVARCHAR(MAX) = '' ;
    DECLARE @ColumnsK NVARCHAR(MAX) = '' ;
    DECLARE @ColumnsN NVARCHAR(MAX) = '' ;
    DECLARE @ColumnsW NVARCHAR(MAX) = '' ;
    DECLARE @ColumnsZ NVARCHAR(MAX) = '' ;
    
   	DECLARE CR_5 CURSOR FOR
    SELECT QUOTENAME(a.[Name]) [Column] , c.[Type]
      , CASE WHEN k.[Name] IS NULL THEN '0' ELSE '1' END [IsKey]
      , CASE WHEN v.[Name] IS NULL THEN '0' ELSE '1' END [IsValue]
    FROM @AllColumnTable a
    JOIN @Columns c ON UPPER(c.[Name]) = UPPER(a.[Name])
    LEFT JOIN @KeyColumnTable k ON k.[Name] = a.[Name]
    LEFT JOIN @ValueColumnTable v ON v.[Name] = a.[Name]
	;
	OPEN CR_5 ;
	WHILE 1 = 1
	BEGIN
	  FETCH NEXT FROM CR_5 INTO @Column , @Type , @IsKey , @IsValue ;
	  IF @@FETCH_STATUS <> 0 BREAK ;
      SET @ColumnsZ = @ColumnsZ + ' , ' + @Column ;
      IF @IsKey = 1
      BEGIN
        SET @ColumnsN = @ColumnsN + ' AND ' + 'b.' + @Column + ' IS NULL' ;
        SET @ColumnsJ = @ColumnsJ + ' AND ' + 'a.' + @Column + ' = ' + 'b.' + @Column ;
      END ;
      IF @IsValue = 1
      BEGIN
        SET @ColumnsW = @ColumnsW + ' OR ' + '( ' + 'a.' + @Column + ' IS NULL AND b.' + @Column + ' IS NOT NULL OR a.' 
          + @Column + ' IS NOT NULL AND b.' + @Column + ' IS NULL OR a.' + @Column + ' <> b.' + @Column + ' )'
          ;
      END ;
      SET @Text = '' ;
      IF @Type = 'VARCHAR' OR @Type = 'NVARCHAR' OR @Type = 'CHAR' OR @Type = 'NCHAR' OR @Type = 'TEXT' OR @Type = 'NTEXT'
      BEGIN
        SET @Text = 'a.' + @Column ;
      END ;
      IF @Type = 'MONEY'
      BEGIN
        SET @Text = 'CONVERT(VARCHAR(21) , a.' + @Column + ' , 2)';
      END ;
      IF @Type = 'SMALLMONEY'
      BEGIN
        SET @Text = 'CONVERT(VARCHAR(12) , a.' + @Column + ' , 2)';
      END ;
      IF @Type = 'BIT'
      BEGIN
         SET @Text = 'CONVERT(VARCHAR(1) , a.' + @Column + ' , 3)';
      END ;
      IF @Type = 'TINYINT'
      BEGIN
         SET @Text = 'CONVERT(VARCHAR(3) , a.' + @Column + ' , 3)';
      END ;
      IF @Type = 'SMALLINT'
      BEGIN
        SET @Text = 'CONVERT(VARCHAR(6) , a.' + @Column + ' , 3)';
      END ;
      IF @Type = 'INT'
      BEGIN
        SET @Text = 'CONVERT(VARCHAR(11) , a.' + @Column + ' , 3)';
      END ;
      IF @Type = 'BIGINT'
      BEGIN
        SET @Text = 'CONVERT(VARCHAR(20) , a.' + @Column + ' , 3)';
      END ;
      IF @Type = 'DECIMAL' OR @Type = 'NUMERIC'
      BEGIN
        SET @Text = 'CONVERT(VARCHAR(40) , a.' + @Column + ' , 3)';
      END ;
      IF @Type = 'FLOAT' OR @Type = 'REAL'
      BEGIN
        SET @Text = 'CONVERT(VARCHAR(20) , a.' + @Column + ' , 3)';
      END ;
      IF @Type = 'DATETIME'
      BEGIN
        SET @Text = 'CONVERT(VARCHAR(23) , a.' + @Column + ' , 126)';
      END ;
      IF @Type = 'DATETIME2'
      BEGIN
        SET @Text = 'CONVERT(VARCHAR(27) , a.' + @Column + ' , 126)';
      END ;
      IF @Type = 'DATE'
      BEGIN
        SET @Text = 'CONVERT(VARCHAR(10) , a.' + @Column + ' , 126)';
      END ;
      IF @Type = 'TIME'
      BEGIN
        SET @Text = 'CONVERT(VARCHAR(16) , a.' + @Column + ' , 126)';
      END ;
      IF @Type = 'DATETIMEOFFSET'
      BEGIN
        SET @Text = 'CONVERT(VARCHAR(33) , a.' + @Column + ' , 126)';
      END ;
      IF @Text = ''
      BEGIN
        SET @Text = 'a.' + @Column ;
      END ;
      SET @ColumnsA = @ColumnsA + ' , ' + @Text + ' AS ' + @Column ;
      IF @IsKey = 1
      BEGIN
        SET @ColumnsK = @ColumnsK + ' , ' + @Text + ' AS ' + @Column ;
      END ;
      IF @IsValue = 1
      BEGIN
        SET @ColumnsD = @ColumnsD + ' , ' + 'CASE'
          + ' WHEN a.' + @Column + ' IS NULL AND b.' + @Column + ' IS NULL THEN NULL'
          + ' WHEN a.' + @Column + ' IS NULL AND b.' + @Column + ' IS NOT NULL THEN ' + @NullValue
          + ' WHEN a.' + @Column + ' = b.' + @Column + ' THEN NULL'
          + ' ELSE ' + @Text
          + ' END AS ' + @Column 
          ;
      END ;
	END ;
	CLOSE CR_5 ;
	DEALLOCATE CR_5;
    SET @ColumnsA = SUBSTRING(@ColumnsA , 4 , 1 + LEN(@ColumnsA) - 4) ;
    SET @ColumnsN = SUBSTRING(@ColumnsN , 6 , 1 + LEN(@ColumnsN) - 6) ;
    SET @ColumnsJ = SUBSTRING(@ColumnsJ , 6 , 1 + LEN(@ColumnsJ) - 6) ;
    SET @ColumnsW = SUBSTRING(@ColumnsW , 5 , 1 + LEN(@ColumnsW) - 5) ;
    SET @ColumnsK = SUBSTRING(@ColumnsK , 4 , 1 + LEN(@ColumnsK) - 4) ;
    SET @ColumnsZ = SUBSTRING(@ColumnsZ , 4 , 1 + LEN(@ColumnsZ) - 4) ;

	-- Generate SELECT statement for comparisation --

	DECLARE @SelectScript NVARCHAR(MAX) ;

	SET @SelectScript = '' ;

    IF @Insert = 1
    BEGIN
      SET @SelectScript = @SelectScript 
        + 'SELECT ''INSERT'' AS ' + @OperationAlias + ' , ' + @ColumnsA
        + CHAR(13) + CHAR(10)
        + 'FROM ' + @Source + ' a'
        + CHAR(13) + CHAR(10)
        + 'LEFT JOIN ' + @Destination + ' b ON ' + @ColumnsJ
        + CHAR(13) + CHAR(10)
        + 'WHERE ' + @ColumnsN
        ;
    END

    IF @Delete = 1
    BEGIN
      IF @SelectScript <> ''
      BEGIN
        SET @SelectScript = @SelectScript
          + CHAR(13) + CHAR(10)
          + 'UNION ALL'
          + CHAR(13) + CHAR(10)
          ;
      END ;

      SET @SelectScript = @SelectScript 
        + 'SELECT ''DELETE'' AS ' + @OperationAlias + ' , ' + @ColumnsA
        + CHAR(13) + CHAR(10)
        + 'FROM ' + @Destination + ' a'
        + CHAR(13) + CHAR(10)
        + 'LEFT JOIN ' + @Source + ' b ON ' + @ColumnsJ
        + CHAR(13) + CHAR(10)
        + 'WHERE ' + @ColumnsN
        ;
    END ;

    IF @Update = 1
    BEGIN
      IF @SelectScript <> ''
      BEGIN
        SET @SelectScript = @SelectScript
          + CHAR(13) + CHAR(10)
          + 'UNION ALL'
          + CHAR(13) + CHAR(10)
          ;
      END ;
      SET @SelectScript = @SelectScript 
        + 'SELECT ''UPDATE'' AS ' + @OperationAlias + ' , ' + @ColumnsK + @ColumnsD
        + CHAR(13) + CHAR(10)
        + 'FROM ' + @Source + ' a'
        + CHAR(13) + CHAR(10)
        + 'JOIN ' + @Destination + ' b ON ' + @ColumnsJ
        + CHAR(13) + CHAR(10)
        + 'WHERE ' + @ColumnsW
        ;
    END ;

    IF @Pretend = 1
    BEGIN
      PRINT '' ;
      PRINT '-- CHECK --' ;
      PRINT '' ;
      PRINT CAST(@SelectScript AS NTEXT) ;
    END ;

    IF @Select = 1 AND @Pretend = 0
    BEGIN
      EXEC sp_executesql @SelectScript ;
    END ;

    DECLARE @ProcessScript NVARCHAR(MAX) = '' ;
    DECLARE @MergeScript NVARCHAR(MAX) = '' ;

    SET @ProcessScript = @ProcessScript
      + 'DECLARE C CURSOR FOR'
      + CHAR(13) + CHAR(10)
      + @SelectScript
      + CHAR(13) + CHAR(10)
      + ';'
      + CHAR(13) + CHAR(10)
      ;

    SET @ProcessScript = @ProcessScript
      + 'DECLARE @Q NVARCHAR(MAX) ;'
      + CHAR(13) + CHAR(10)
      + 'DECLARE @T TABLE ( _ NVARCHAR(MAX) ) ;'
      + CHAR(13) + CHAR(10)
      + 'DECLARE @0 NVARCHAR(6) ;'
      + CHAR(13) + CHAR(10)
      ;

    SET @N = ( SELECT SUM(1) FROM @AllColumnTable ) ;
    SET @K = ( SELECT SUM(1) FROM @KeyColumnTable ) ;

    SET @I = 0 ;

    WHILE @I < @N
    BEGIN
      SET @I = @I + 1 ;
      SET @ProcessScript = @ProcessScript
        + 'DECLARE @' + CONVERT(VARCHAR(5) , @I) + ' NVARCHAR(MAX) ;'
        + CHAR(13) + CHAR(10)
        ;
    END ;

    SET @ProcessScript = @ProcessScript
      + 'OPEN C ;'
      + CHAR(13) + CHAR(10)
      ;

    SET @ProcessScript = @ProcessScript
      + 'WHILE 1 = 1'
      + CHAR(13) + CHAR(10)
      + 'BEGIN'
      + CHAR(13) + CHAR(10)
      ;

    SET @ProcessScript = @ProcessScript
      + '  FETCH NEXT FROM C INTO @0'
      ;

    SET @I = 0 ;
    WHILE @I < @N
    BEGIN
      SET @I = @I + 1 ;
      SET @ProcessScript = @ProcessScript + ' , @' + CONVERT(VARCHAR(5) , @I) ;
    END ;

    SET @ProcessScript = @ProcessScript
      + ' ;'
      + CHAR(13) + CHAR(10)
      + '  IF @@FETCH_STATUS <> 0 BREAK ;'
      + CHAR(13) + CHAR(10)
      ;

    SET @ProcessScript = @ProcessScript
      + '  IF @0 = ''INSERT'''
      + CHAR(13) + CHAR(10)
      + '  BEGIN'
      + CHAR(13) + CHAR(10)
      + '    SET @Q = ''INSERT INTO ' + @Destination + ' ( ' + @ColumnsZ + ' ) VALUES ( '
      ;

    SET @I = 0 ;
    WHILE @I < @N
    BEGIN
      SET @I = @I + 1 ;
      IF @I > 1 SET @ProcessScript = @ProcessScript + ' + '' , ' ;
      SET @ProcessScript = @ProcessScript + ''' + CASE WHEN @' 
        + CONVERT(VARCHAR(5) , @I) + ' IS NULL THEN ''NULL'' ELSE ''N'''''' + @' + CONVERT(VARCHAR(5) , @I) + ' + '''''''' END'
        ;
    END ;

    SET @ProcessScript = @ProcessScript
      + ' + '' )'' ;'
      + CHAR(13) + CHAR(10)
      + '    INSERT INTO @T VALUES ( @Q ) ;'
      + CHAR(13) + CHAR(10)
      + '  END ;'
      + CHAR(13) + CHAR(10)
      ;

    SET @ProcessScript = @ProcessScript
      + '  IF @0 = ''DELETE'''
      + CHAR(13) + CHAR(10)
      + '  BEGIN'
      + CHAR(13) + CHAR(10)
      + '    SET @Q = ''DELETE FROM ' + @Destination + ' WHERE '
      ;

    SET @I = 0 ;
    WHILE @I < @N
    BEGIN
      SET @I = @I + 1 ;
      SET @Text = ( SELECT [Name] FROM @KeyColumnTable WHERE [Index] = @I ) ;
      IF @Text IS NULL
      BEGIN
        BREAK ;
      END ;
      IF @I > 1 SET @ProcessScript = @ProcessScript + ' + '' AND ' ;
      SET @Text = REPLACE(QUOTENAME(@Text) , '''' , '''''') ;
      SET @ProcessScript = @ProcessScript + @Text + ' '' + CASE WHEN @' 
        + CONVERT(VARCHAR(5) , @I) + ' IS NULL THEN ''IS NULL'' ELSE ''= N'''''' + @' + CONVERT(VARCHAR(5) , @I) + ' + '''''''' END'
        ;
    END ;

    SET @ProcessScript = @ProcessScript
      + ' ;'
      + CHAR(13) + CHAR(10)
      + '    INSERT INTO @T VALUES ( @Q ) ;'
      + CHAR(13) + CHAR(10)
      + '  END ;'
      + CHAR(13) + CHAR(10)
      ;

    SET @ProcessScript = @ProcessScript
      + '  IF @0 = ''UPDATE'''
      + CHAR(13) + CHAR(10)
      + '  BEGIN'
      + CHAR(13) + CHAR(10)
      + '    SET @Q = ''UPDATE ' + @Destination + ' SET 8<-CUT->8'''
      ;

    SET @I = 0 ;
    WHILE @I < @N
    BEGIN
      SET @I = @I + 1 ;
      SET @Text = ( SELECT [Name] FROM @ValueColumnTable WHERE [Index] = @I ) ;
      IF @Text IS NULL
      BEGIN
        BREAK ;
      END ;
      SET @Text = REPLACE(QUOTENAME(@Text) , '''' , '''''') ;
      SET @ProcessScript = @ProcessScript + ' + CASE WHEN @' + CONVERT(VARCHAR(5) , @I + @K) + ' IS NULL THEN '''' ELSE '' , ';
      SET @ProcessScript = @ProcessScript + @Text + ' = '' + CASE WHEN @' 
        + CONVERT(VARCHAR(5) , @I + @K) + ' = ' + @NullValue + ' THEN ''NULL'' ELSE ''N'''''' + @'
        + CONVERT(VARCHAR(5) , @I + @K) + ' + '''''''' END END'
        ;
    END ;

    SET @ProcessScript = @ProcessScript + ' + '' WHERE ' ;

    SET @I = 0 ;
    WHILE @I < @N
    BEGIN
      SET @I = @I + 1 ;
      SET @Text = ( SELECT [Name] FROM @KeyColumnTable WHERE [Index] = @I ) ;
      IF @Text IS NULL
      BEGIN
        BREAK ;
      END ;
      IF @I > 1 SET @ProcessScript = @ProcessScript + ' + '' AND ' ;
      SET @Text = REPLACE(QUOTENAME(@Text) , '''' , '''''') ;
      SET @ProcessScript = @ProcessScript + @Text + ' '' + CASE WHEN @' 
        + CONVERT(VARCHAR(5) , @I) + ' IS NULL THEN ''IS NULL'' ELSE ''= N'''''' + @' + CONVERT(VARCHAR(5) , @I) + ' + '''''''' END'
        ;
    END ;

    SET @ProcessScript = @ProcessScript
      + ' ;'
      + CHAR(13) + CHAR(10)
      + '    SET @Q = REPLACE(@Q , '' SET 8<-CUT->8 , '' , '' SET '') ;'
      + CHAR(13) + CHAR(10)
      + '    INSERT INTO @T VALUES ( @Q ) ;'
      + CHAR(13) + CHAR(10)
      + '  END ;'
      + CHAR(13) + CHAR(10)
      ;

    SET @ProcessScript = @ProcessScript
      + 'END ;'
      + CHAR(13) + CHAR(10)
      ;

    SET @ProcessScript = @ProcessScript
      + 'CLOSE C ;'
      + CHAR(13) + CHAR(10)
      + 'DEALLOCATE C ;'
      + CHAR(13) + CHAR(10)
      ;

    SET @MergeScript = @ProcessScript ;

    SET @MergeScript = @MergeScript
      + 'DECLARE R CURSOR FOR SELECT _ FROM @T ;'
      + CHAR(13) + CHAR(10)
      + 'OPEN R ;'
      + CHAR(13) + CHAR(10)
      + 'WHILE 1 = 1'
      + CHAR(13) + CHAR(10)
      + 'BEGIN'
      + CHAR(13) + CHAR(10)
      + '  FETCH NEXT FROM R INTO @Q ;'
      + CHAR(13) + CHAR(10)
      + '  IF @@FETCH_STATUS <> 0 BREAK ;'
      + CHAR(13) + CHAR(10)
      + '  EXECUTE sp_executesql @Q ;'
      + CHAR(13) + CHAR(10)
      + 'END ;'
      + CHAR(13) + CHAR(10)
      + 'CLOSE R ;'
      + CHAR(13) + CHAR(10)
      + 'DEALLOCATE R ;'
      + CHAR(13) + CHAR(10)
      ;

    SET @ProcessScript = @ProcessScript
      + 'SELECT _ FROM @T ;'
      + CHAR(13) + CHAR(10)
      ;

    IF @Pretend = 1
    BEGIN
        PRINT '' ;
        PRINT '-- BUILD --' ;
        PRINT '' ;
        PRINT CAST(@ProcessScript AS NTEXT) ;
        RETURN 0 ;
    END ;

    IF @Select = 1
    BEGIN
      EXEC sp_executesql @ProcessScript ;
    END ;

    IF @Merge = 1
    BEGIN
      EXEC sp_executesql @MergeScript ;
    END ;

    IF @Pretend = 1
        RETURN 0 ;
    ELSE
        RETURN 1 ;
END

GO
