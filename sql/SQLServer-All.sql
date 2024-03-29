
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --
--      __    _  _______  _______  ______       __   __  _______  ______    _______      _______  _______  _______  _______  _______       --
--     |  |  | ||       ||       ||      |     |  |_|  ||       ||    _ |  |       |    |       ||       ||   _   ||       ||       |      --
--     |   |_| ||    ___||    ___||  _    |    |       ||   _   ||   | ||  |    ___|    |  _____||    _  ||  |_|  ||      _||    ___|      --
--     |       ||   |___ |   |___ | | |   |    |       ||  | |  ||   |_||_ |   |___     | |_____ |   |_| ||       ||     |  |   |___       --
--     |  _    ||    ___||    ___|| |_|   |    |       ||  |_|  ||    __  ||    ___|    |_____  ||    ___||       ||     |  |    ___|      --
--     | | |   ||   |___ |   |___ |       |    | ||_|| ||       ||   |  | ||   |___      _____| ||   |    |   _   ||     |_ |   |___       --
--     |_|  |__||_______||_______||______|     |_|   |_||_______||___|  |_||_______|    |_______||___|    |__| |__||_______||_______|      --
--                                                                                                                                         --
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --

-- This is installation script for "Need More Space" utility for SQL Server.
-- Utility contains procedures helpful in diagnostics and examination.
-- Documentation and more information can be found at https://github.com/zoltraks/need-more-space
-- This software is free.
-- Written by Filip Golewski <f.golewski@gmail.com>.

GO

--USE [DBAtools]

GO

IF OBJECT_ID ( 'dbo.v_ColumnType' ) IS NULL
EXEC sp_executesql N'CREATE FUNCTION dbo.v_ColumnType ( ) RETURNS VARCHAR(100) BEGIN RETURN NULL ; END' ;

GO

--
-- Make script definition for data type.
--
-- SELECT dbo.v_ColumnType('NVARCHAR',50,NULL,NULL,NULL)
-- SELECT dbo.v_ColumnType('DECIMAL',NULL,18,9,NULL)
-- SELECT dbo.v_ColumnType('DATETIME2',NULL,NULL,NULL,3)
--
ALTER FUNCTION dbo.v_ColumnType
( 
  @DataType VARCHAR(20) = NULL ,
  @MaximumLength INT = NULL ,
  @NumericPrecision INT = NULL ,
  @NumericScale INT = NULL ,
  @DateTimePrecision INT = NULL
)
RETURNS VARCHAR(100)
AS
BEGIN
  RETURN UPPER(@DataType) 
    +
    CASE
      WHEN UPPER(@DataType) IN ('BIT' , 'INT' , 'SMALLINT' , 'TINYINT' , 'BIGINT' , 'DATETIME' , 'SMALLDATETIME' , 'TIMESTAMP' , 'REAL' , 'TEXT' , 'NTEXT' , 'MONEY' , 'SMALLMONEY' , 'IMAGE' , 'UNIQUEIDENTIFIER' , 'SYSNAME' , 'XML' , 'SQL_VARIANT' , 'HIERARCHYID' , 'GEOMETRY' , 'GEOGRAPHY')
      THEN ''
      WHEN UPPER(@DataType) IN ('CHAR' , 'NCHAR' , 'BINARY' )
      THEN
      CASE
        WHEN @MaximumLength < 2
        THEN ''
        ELSE '(' + CONVERT(VARCHAR , @MaximumLength) + ')'
      END
      WHEN UPPER(@DataType) IN ('VARCHAR' , 'NVARCHAR' , 'VARBINARY')
      THEN
      CASE
        WHEN @MaximumLength = 1
        THEN ''
        WHEN @MaximumLength = -1
        THEN '(MAX)'
        ELSE '(' + CONVERT(VARCHAR , @MaximumLength) + ')'
      END
      WHEN UPPER(@DataType) IN ('DECIMAL' , 'NUMERIC')
      THEN
      CASE
        WHEN @NumericPrecision = 18 AND @NumericScale = 0
        THEN ''
        WHEN @NumericPrecision < 1
        THEN ''
        ELSE
        CASE
          WHEN @NumericScale = 0
          THEN '(' + CONVERT(VARCHAR , @NumericPrecision) + ')'
          WHEN @NumericScale <> 0
          THEN '(' + CONVERT(VARCHAR , @NumericPrecision) + ',' + CONVERT(VARCHAR , @NumericScale) + ')'
        END
      END
      WHEN UPPER(@DataType) = 'FLOAT'
      THEN
      CASE
        WHEN @NumericPrecision > 0 AND @NumericPrecision <> 53
        THEN '(' + CONVERT(VARCHAR , @NumericPrecision) + ')'
        ELSE ''
      END
      WHEN UPPER(@DataType) IN ('TIME' , 'DATETIME2' , 'DATETIMEOFFSET' )
      THEN
      CASE
        WHEN @DateTimePrecision IS NULL OR @DateTimePrecision = 7 OR @DateTimePrecision < 0
        THEN ''
        ELSE '(' + CONVERT(VARCHAR , @DateTimePrecision) + ')'
      END
      ELSE ''
    END
  ;
END ;

GO

IF OBJECT_ID ( 'dbo.v_SplitText' ) IS NULL
EXEC sp_executesql N'CREATE FUNCTION dbo.v_SplitText ( ) RETURNS @Table TABLE ( _ BIT NULL ) AS BEGIN RETURN ; END' ;

GO

--
-- Split text by any separator of comma, semicolon, or pipe characters.
-- Values may be quoted using quotation marks, square brackets, apostrophes or grave accents.
-- Quoted values might be optionally stripped out from surrounding characters.
--
ALTER FUNCTION dbo.v_SplitText ( @Text NVARCHAR(MAX) , @Separators NVARCHAR(10) = NULL , @Quotes NVARCHAR(10) = NULL , @Strip BIT = NULL )
RETURNS @Table TABLE
(
  [Text] NVARCHAR(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS
)
AS
BEGIN

  IF @Text IS NULL RETURN ;

  DECLARE @sl_text NVARCHAR(MAX) ;
  DECLARE @sl_strip BIT ;
  DECLARE @sl_separators NVARCHAR(10) ;
  DECLARE @sl_quotes NVARCHAR(10) ;

  DECLARE @sl_i INT ;
  DECLARE @sl_n INT ;
  DECLARE @sl_q NCHAR ;
  DECLARE @sl_c NCHAR ;
  DECLARE @sl_list TABLE ( [Text] NVARCHAR(MAX) ) ;
  DECLARE @sl_p INT ;
  DECLARE @sl_x INT ;
  DECLARE @sl_t0 NVARCHAR(10) ;
  DECLARE @sl_t1 NVARCHAR(10) ;
  DECLARE @sl_t2 NVARCHAR(10) ;
  DECLARE @sl_s NVARCHAR(MAX) ;
  DECLARE @sl_w INT ;

  SET @sl_text = @Text ;
  SET @sl_separators = @Separators ;
  SET @sl_quotes = @Quotes ;
  SET @sl_strip = @Strip ;

  SET @sl_separators = ISNULL(@sl_separators , ',;|') ;
  SET @sl_quotes = ISNULL(@sl_quotes , '"[''`') ;
  SET @sl_strip = ISNULL(@sl_strip , 0) ;
 
  SET @sl_t0 = ' ' + CHAR(9) + CHAR(10) + CHAR(13) ;
  SET @sl_t1 = '[({' ;
  SET @sl_t2 = '])}' ;
  
  SET @sl_i = 0 ;
  SET @sl_p = 0 ;
  SET @sl_n = LEN(@Text) ;
  SET @sl_q = NULL ;
  SET @sl_w = 0 ;

  WHILE 1 = 1
  BEGIN
    SET @sl_i = @sl_i + 1 ;
    -- Loop check
    IF @sl_i > @sl_n
    BEGIN
      IF @sl_p > 0
      BEGIN
        INSERT INTO @sl_list VALUES ( SUBSTRING(@sl_text , @sl_p , 1 + @sl_n - @sl_p ) ) ;
      END 
      ELSE
      BEGIN
        IF @sl_w = 0
        BEGIN
          INSERT INTO @sl_list VALUES ( '' ) ;
        END ;
      END ;
      BREAK ;
    END ;
    SET @sl_c = SUBSTRING(@sl_text , @sl_i , 1 ) ;
    -- Check for whitespace
    IF @sl_q IS NULL
    BEGIN
      SET @sl_x = CHARINDEX(@sl_c , @sl_t0 ) ;
      IF @sl_x > 0
      BEGIN
        IF @sl_w = 0
        BEGIN
          IF @sl_p > 0
          BEGIN
            INSERT INTO @sl_list VALUES ( SUBSTRING(@sl_text , @sl_p , @sl_i - @sl_p ) ) ;
            SET @sl_p = 0 ;
            -- Move to end of any trailing whitespace
            WHILE 1 = 1
            BEGIN
                IF @sl_i >= @sl_n
                BEGIN
                BREAK ;
                END ;
              SET @sl_c = SUBSTRING(@sl_text , @sl_i + 1 , 1 ) ;
              SET @sl_x = CHARINDEX(@sl_c , @sl_t0 ) ;
              IF @sl_x > 0
              BEGIN
                SET @sl_i = @sl_i + 1 ;
                CONTINUE ;
              END ;
              BREAK ;
            END ;
            -- Consume first separator
            IF @sl_i <= @sl_n
            BEGIN
              SET @sl_x = CHARINDEX(@sl_c , @sl_separators ) ;
               IF @sl_x > 0
              BEGIN
                SET @sl_i = @sl_i + 1 ;
              END ;
            END ;
            CONTINUE ;
          END ;
          SET @sl_w = @sl_i ;
        END ;
        CONTINUE ;
      END ;
    END ;
    -- Check for quotation begining
    IF @sl_q IS NULL
    BEGIN
      SET @sl_x = CHARINDEX(@sl_c , @sl_quotes ) ;
      IF @sl_x > 0
      BEGIN
        SET @sl_p = @sl_i ;
        SET @sl_q = SUBSTRING(@sl_quotes , @sl_x , 1 ) ;
        SET @sl_x = CHARINDEX(@sl_c , @sl_t1 ) ;
        IF @sl_x > 0
        BEGIN
          SET @sl_q = SUBSTRING(@sl_t2 , @sl_x , 1 ) ;
        END ;
        CONTINUE ;
      END ;
    END ;
    -- Check for quotation ending
    IF @sl_c = @sl_q
    BEGIN
      IF @sl_i <= @sl_n AND @sl_q = SUBSTRING(@sl_text , @sl_i + 1 , 1 )
      BEGIN
        SET @sl_i = @sl_i + 1 ;
        CONTINUE ;
      END
      IF @sl_p > 0
      BEGIN
        IF @sl_strip = 1 AND @sl_i - @sl_p > 0
        BEGIN
          INSERT INTO @sl_list VALUES ( REPLACE(SUBSTRING(@sl_text , @sl_p + 1 , @sl_i - @sl_p - 1 ) , @sl_q + @sl_q , @sl_q ) ) ;
        END
        ELSE
        BEGIN
          INSERT INTO @sl_list VALUES ( SUBSTRING(@sl_text , @sl_p , 1 + @sl_i - @sl_p ) ) ;
        END
        SET @sl_p = 0 ;
        -- Move to end of any trailing whitespace
        WHILE 1 = 1
        BEGIN
          IF @sl_i > @sl_n
          BEGIN
            BREAK ;
          END ;
          SET @sl_c = SUBSTRING(@sl_text , @sl_i + 1 , 1 ) ;
          SET @sl_x = CHARINDEX(@sl_c , @sl_t0 ) ;
          IF @sl_x > 0
          BEGIN
            SET @sl_i = @sl_i + 1 ;
            IF @sl_w = 0
            BEGIN
              SET @sl_w = @sl_i ;
            END ;
            CONTINUE ;
          END ;
          BREAK ;
        END ;
        -- Consume first separator
        SET @sl_x = CHARINDEX(@sl_c , @sl_separators ) ;
        IF @sl_x > 0
        BEGIN
          SET @sl_i = @sl_i + 1 ;
          SET @sl_w = 0 ;
        END ;
      END ;
      SET @sl_q = NULL ;
      CONTINUE ;
    END ;
    -- Ignore quoted values
    IF @sl_q IS NOT NULL
    BEGIN
      CONTINUE ;
    END ;
    -- Check for separator
    SET @sl_x = CHARINDEX(@sl_c , @sl_separators ) ;
    IF @sl_x > 0
    BEGIN
      IF @sl_p > 0
      BEGIN
        INSERT INTO @sl_list VALUES ( SUBSTRING(@sl_text , @sl_p , @sl_i - @sl_p ) ) ;
        SET @sl_p = 0 ;
          CONTINUE ;
      END ;
      IF @sl_w > 0 OR @sl_p = 0
      BEGIN
        INSERT INTO @sl_list VALUES ( '' ) ;
        SET @sl_w = 0 ;
        CONTINUE ;
      END ;
      CONTINUE ;
    END ;

    IF @sl_p = 0
    BEGIN
      SET @sl_p = @sl_i ;
      SET @sl_w = 0 ;
    END ;

  END ;

  INSERT INTO @Table ( [Text] )
  SELECT [Text] FROM @sl_list ;

  RETURN ;

END

GO

IF OBJECT_ID ( 'dbo.v_VersionList' ) IS NULL
EXEC sp_executesql N'CREATE FUNCTION dbo.v_VersionList ( ) RETURNS @Table TABLE ( _ BIT NULL ) AS BEGIN RETURN ; END' ;

GO

--
-- This function will result with dictionary of wait type names and descriptions.
--
-- Source: https://buildnumbers.wordpress.com/sqlserver/
--
ALTER FUNCTION dbo.v_VersionList ( )
RETURNS @Table TABLE
(
  [Version] NVARCHAR(20) COLLATE SQL_Latin1_General_CP1_CI_AS ,
  [Family] NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS ,
  [Update] NVARCHAR(20) COLLATE SQL_Latin1_General_CP1_CI_AS ,
  UNIQUE CLUSTERED ( [Version] DESC )
)
AS
BEGIN

INSERT INTO @Table ( [Version] , [Family] , [Update] )
VALUES
 (N'',N'',N'')

,(N'15.0.4188.2',N'SQL Server 2019',N'CU14')
,(N'15.0.4178.1',N'SQL Server 2019',N'CU13')
,(N'15.0.4153.1',N'SQL Server 2019',N'CU12')
,(N'15.0.4138.2',N'SQL Server 2019',N'CU11')
,(N'15.0.4123.1',N'SQL Server 2019',N'CU10')
,(N'15.0.4102.2',N'SQL Server 2019',N'CU9')
,(N'15.0.4083.2',N'SQL Server 2019',N'CU8+SU')
,(N'15.0.4073.23',N'SQL Server 2019',N'CU8')
,(N'15.0.4063.15',N'SQL Server 2019',N'CU7')
,(N'15.0.4053.23',N'SQL Server 2019',N'CU6')
,(N'15.0.4043.16',N'SQL Server 2019',N'CU5')
,(N'15.0.4033.1',N'SQL Server 2019',N'CU4')
,(N'15.0.4023.6',N'SQL Server 2019',N'CU3')
,(N'15.0.4013.40',N'SQL Server 2019',N'CU2')
,(N'15.0.4003.23',N'SQL Server 2019',N'CU1')
,(N'15.0.2080.9',N'SQL Server 2019',N'GDR+SU')
,(N'15.0.2070.41',N'SQL Server 2019',N'GDR1')
,(N'15.0.2000.5',N'SQL Server 2019',N'RTM')

,(N'15.0.1900.47',N'SQL Server 2019 RTM',N'RC1 1.1')
,(N'15.0.1900.25',N'SQL Server 2019 RTM',N'RC1')
,(N'15.0.1800.32',N'SQL Server 2019 RTM',N'CTP 3.2')
,(N'15.0.1700.37',N'SQL Server 2019 RTM',N'CTP 3.1')
,(N'15.0.1600.8',N'SQL Server 2019 RTM',N'CTP 3.0')
,(N'15.0.1500.28',N'SQL Server 2019 RTM',N'CTP 2.5')
,(N'15.0.1400.75',N'SQL Server 2019 RTM',N'CTP 2.4')
,(N'15.0.1300.359',N'SQL Server 2019 RTM',N'CTP 2.3')
,(N'15.0.1200.24',N'SQL Server 2019 RTM',N'CTP 2.2')
,(N'15.0.1100.94',N'SQL Server 2019 RTM',N'CTP 2.1')
,(N'15.0.1000.34',N'SQL Server 2019 RTM',N'CTP 2.0')

,(N'14.0.3411.3',N'SQL Server 2017',N'CU26')
,(N'14.0.3401.7',N'SQL Server 2017',N'CU25')
,(N'14.0.3391.2',N'SQL Server 2017',N'CU24')
,(N'14.0.3381.3',N'SQL Server 2017',N'CU23')
,(N'14.0.3370.1',N'SQL Server 2017',N'CU22+SU')
,(N'14.0.3356.20',N'SQL Server 2017',N'CU22')
,(N'14.0.3335.7',N'SQL Server 2017',N'CU21')
,(N'14.0.3294.2',N'SQL Server 2017',N'CU20')
,(N'14.0.3281.6',N'SQL Server 2017',N'CU19')
,(N'14.0.3257.3',N'SQL Server 2017',N'CU18')
,(N'14.0.3238.1',N'SQL Server 2017',N'CU17')
,(N'14.0.3223.3',N'SQL Server 2017',N'CU16')
,(N'14.0.3208.1',N'SQL Server 2017',N'CU15+SU2+FIX')
,(N'14.0.3192.2',N'SQL Server 2017',N'CU15+SU1')
,(N'14.0.3164.1',N'SQL Server 2017',N'CU15+FIX')
,(N'14.0.3162.1',N'SQL Server 2017',N'CU15')
,(N'14.0.3103.1',N'SQL Server 2017',N'CU14+SU')
,(N'14.0.3076.1',N'SQL Server 2017',N'CU14')
,(N'14.0.3049.1',N'SQL Server 2017',N'FIX')
,(N'14.0.3048.4',N'SQL Server 2017',N'CU13')
,(N'14.0.3045.24',N'SQL Server 2017',N'CU12')
,(N'14.0.3038.14',N'SQL Server 2017',N'CU11')
,(N'14.0.3037.1',N'SQL Server 2017',N'CU10')
,(N'14.0.3035.2',N'SQL Server 2017',N'CU9+SU')
,(N'14.0.3030.27',N'SQL Server 2017',N'CU9')
,(N'14.0.3029.16',N'SQL Server 2017',N'CU8')
,(N'14.0.3026.27',N'SQL Server 2017',N'CU7')
,(N'14.0.3025.34',N'SQL Server 2017',N'CU6')
,(N'14.0.3023.8',N'SQL Server 2017',N'CU5')
,(N'14.0.3022.28',N'SQL Server 2017',N'CU4')
,(N'14.0.3015.40',N'SQL Server 2017',N'CU3')
,(N'14.0.3008.27',N'SQL Server 2017',N'CU2')
,(N'14.0.3006.16',N'SQL Server 2017',N'CU1')
,(N'14.0.2037.2',N'SQL Server 2017',N'GDR+SU5')
,(N'14.0.2027.2',N'SQL Server 2017',N'GDR+SU4')
,(N'14.0.2014.14',N'SQL Server 2017',N'GDR+SU3')
,(N'14.0.2002.14',N'SQL Server 2017',N'GDR+SU2')
,(N'14.0.2000.63',N'SQL Server 2017',N'GDR+SU1')
,(N'14.0.1000.169',N'SQL Server 2017',N'RTM')
,(N'14.0.900.75',N'SQL Server 2017',N'RC2')
,(N'14.0.800.90',N'SQL Server 2017',N'RC1')
,(N'14.0.600.250',N'SQL Server 2017',N'CTP 2.1')
,(N'14.0.500.272',N'SQL Server 2017',N'CTP 2.0')
,(N'14.0.405.198',N'SQL Server 2017',N'CTP 1.4')
,(N'14.0.304.138',N'SQL Server 2017',N'CTP 1.3')
,(N'14.0.200.24',N'SQL Server 2017',N'CTP 1.2')
,(N'14.0.100.187',N'SQL Server 2017',N'CTP 1.1')
,(N'14.0.1.246',N'SQL Server 2017',N'CTP 1')

,(N'13.0.6300.2',N'SQL Server 2016 Service Pack 3',N'SP3')
,(N'13.0.5888.11',N'SQL Server 2016 Service Pack 2',N'CU17')
,(N'13.0.5882.1',N'SQL Server 2016 Service Pack 2',N'CU16')
,(N'13.0.5865.1',N'SQL Server 2016 Service Pack 2',N'CU15+SU')
,(N'13.0.5850.14',N'SQL Server 2016 Service Pack 2',N'CU15')
,(N'13.0.5830.85',N'SQL Server 2016 Service Pack 2',N'CU14')
,(N'13.0.5820.21',N'SQL Server 2016 Service Pack 2',N'CU13')
,(N'13.0.5698.0',N'SQL Server 2016 Service Pack 2',N'CU12')
,(N'13.0.5622.0',N'SQL Server 2016 Service Pack 2',N'CU11+SU')
,(N'13.0.5598.27',N'SQL Server 2016 Service Pack 2',N'CU11')
,(N'13.0.5492.2',N'SQL Server 2016 Service Pack 2',N'CU10')
,(N'13.0.5479.0',N'SQL Server 2016 Service Pack 2',N'CU9')
,(N'13.0.5426.0',N'SQL Server 2016 Service Pack 2',N'CU8')
,(N'13.0.5382.0',N'SQL Server 2016 Service Pack 2',N'CU7+SU2+FIX')
,(N'13.0.5366.0',N'SQL Server 2016 Service Pack 2',N'CU7+SU1')
,(N'13.0.5343.1',N'SQL Server 2016 Service Pack 2',N'CU7+FIX')
,(N'13.0.5337.0',N'SQL Server 2016 Service Pack 2',N'CU7')
,(N'13.0.5292.0',N'SQL Server 2016 Service Pack 2',N'CU6')
,(N'13.0.5270.0',N'SQL Server 2016 Service Pack 2',N'CU5+FIX')
,(N'13.0.5264.1',N'SQL Server 2016 Service Pack 2',N'CU5')
,(N'13.0.5239.0',N'SQL Server 2016 Service Pack 2',N'CU4+FIX')
,(N'13.0.5233.0',N'SQL Server 2016 Service Pack 2',N'CU4')
,(N'13.0.5216.0',N'SQL Server 2016 Service Pack 2',N'CU3')
,(N'13.0.5201.1',N'SQL Server 2016 Service Pack 2',N'CU2+SU')
,(N'13.0.5153.0',N'SQL Server 2016 Service Pack 2',N'CU2')
,(N'13.0.5149.0',N'SQL Server 2016 Service Pack 2',N'CU1')
,(N'13.0.5103.6',N'SQL Server 2016 Service Pack 2',N'GDR+SU4')
,(N'13.0.5102.14',N'SQL Server 2016 Service Pack 2',N'GDR+SU3')
,(N'13.0.5101.9',N'SQL Server 2016 Service Pack 2',N'GDR+SU2')
,(N'13.0.5081.1',N'SQL Server 2016 Service Pack 2',N'GDR+SU1')
,(N'13.0.5026.0',N'SQL Server 2016 Service Pack 2',N'SP2')
,(N'13.0.4604.0',N'SQL Server 2016 Service Pack 1',N'CU15+SU')
,(N'13.0.4577.0',N'SQL Server 2016 Service Pack 1',N'CU15+FIX')
,(N'13.0.4574.0',N'SQL Server 2016 Service Pack 1',N'CU15')
,(N'13.0.4560.0',N'SQL Server 2016 Service Pack 1',N'CU14')
,(N'13.0.4550.1',N'SQL Server 2016 Service Pack 1',N'CU13')
,(N'13.0.4541.0',N'SQL Server 2016 Service Pack 1',N'CU12')
,(N'13.0.4531.0',N'SQL Server 2016 Service Pack 1',N'CU11+FIX')
,(N'13.0.4528.0',N'SQL Server 2016 Service Pack 1',N'CU11')
,(N'13.0.4522.0',N'SQL Server 2016 Service Pack 1',N'CU10+SU')
,(N'13.0.4514.0',N'SQL Server 2016 Service Pack 1',N'CU10')
,(N'13.0.4502.0',N'SQL Server 2016 Service Pack 1',N'CU9')
,(N'13.0.4474.0',N'SQL Server 2016 Service Pack 1',N'CU8')
,(N'13.0.4466.4',N'SQL Server 2016 Service Pack 1',N'CU7')
,(N'13.0.4457.0',N'SQL Server 2016 Service Pack 1',N'CU6')
,(N'13.0.4451.0',N'SQL Server 2016 Service Pack 1',N'CU5')
,(N'13.0.4446.0',N'SQL Server 2016 Service Pack 1',N'CU4')
,(N'13.0.4435.0',N'SQL Server 2016 Service Pack 1',N'CU3')
,(N'13.0.4422.0',N'SQL Server 2016 Service Pack 1',N'CU2')
,(N'13.0.4411.0',N'SQL Server 2016 Service Pack 1',N'CU1')
,(N'13.0.4259.0',N'SQL Server 2016 Service Pack 1',N'GDR+SU4')
,(N'13.0.4224.16',N'SQL Server 2016 Service Pack 1',N'GDR+SU3')
,(N'13.0.4210.6',N'SQL Server 2016 Service Pack 1',N'GDR+SU2')
,(N'13.0.4206.0',N'SQL Server 2016 Service Pack 1',N'GDR+SU1')
,(N'13.0.4202.2',N'SQL Server 2016 Service Pack 1',N'GDR')
,(N'13.0.4199.0',N'SQL Server 2016 Service Pack 1',N'SP1+FIX')
,(N'13.0.4001.0',N'SQL Server 2016 Service Pack 1',N'SP1')
,(N'13.0.2218.0',N'SQL Server 2016',N'CU9+SU')
,(N'13.0.2216.0',N'SQL Server 2016',N'CU9')
,(N'13.0.2213.0',N'SQL Server 2016',N'CU8')
,(N'13.0.2210.0',N'SQL Server 2016',N'CU7')
,(N'13.0.2204.0',N'SQL Server 2016',N'CU6')
,(N'13.0.2197.0',N'SQL Server 2016',N'CU5')
,(N'13.0.2193.0',N'SQL Server 2016',N'CU4')
,(N'13.0.2186.6',N'SQL Server 2016',N'MS16-136')
,(N'13.0.2170.0',N'SQL Server 2016',N'CU2+FIX2')
,(N'13.0.2169.0',N'SQL Server 2016',N'CU2+FIX1')
,(N'13.0.2164.0',N'SQL Server 2016',N'CU2')
,(N'13.0.2149.0',N'SQL Server 2016',N'CU1')
,(N'13.0.1745.2',N'SQL Server 2016',N'GDR+SU2')
,(N'13.0.1742.0',N'SQL Server 2016',N'GDR+SU1')
,(N'13.0.1728.2',N'SQL Server 2016',N'GDR')
,(N'13.0.1722.0',N'SQL Server 2016',N'MS16-136')
,(N'13.0.1711.0',N'SQL Server 2016',N'FIX')
,(N'13.0.1708.0',N'SQL Server 2016',N'CU')
,(N'13.0.1601.5',N'SQL Server 2016',N'RTM')
,(N'13.0.1400.361',N'SQL Server 2016',N'RC3')
,(N'13.0.1300.275',N'SQL Server 2016',N'RC2')
,(N'13.0.1200.242',N'SQL Server 2016',N'RC1')
,(N'13.0.1100.288',N'SQL Server 2016',N'RC0')
,(N'13.0.1000.281',N'SQL Server 2016',N'CTP 3.3')
,(N'13.00.900.73',N'SQL Server 2016',N'CTP 3.2')
,(N'13.0.800.111',N'SQL Server 2016',N'CTP 3.1')
,(N'13.0.700.1395',N'SQL Server 2016',N'CTP 3.0')
,(N'13.0.600.65',N'SQL Server 2016',N'CTP 2.4')
,(N'13.0.500.53',N'SQL Server 2016',N'CTP 2.3')
,(N'13.0.407.1',N'SQL Server 2016',N'CTP 2.2')
,(N'13.0.400.91',N'SQL Server 2016',N'CTP 2.2')
,(N'13.0.300.44',N'SQL Server 2016',N'CTP 2.1')
,(N'13.0.200.172',N'SQL Server 2016',N'CTP 2.0')

,(N'12.0.6433.1',N'SQL Server 2014 Service Pack 3',N'CU4+SU2')
,(N'12.0.6372.1',N'SQL Server 2014 Service Pack 3',N'CU4+SU1')
,(N'12.0.6329.1',N'SQL Server 2014 Service Pack 3',N'CU4')
,(N'12.0.6293.0',N'SQL Server 2014 Service Pack 3',N'CU3+SU')
,(N'12.0.6259.0',N'SQL Server 2014 Service Pack 3',N'CU3')
,(N'12.0.6214.1',N'SQL Server 2014 Service Pack 3',N'CU2')
,(N'12.0.6205.1',N'SQL Server 2014 Service Pack 3',N'CU1')
,(N'12.0.6164.21',N'SQL Server 2014 Service Pack 3',N'GDR+SU3')
,(N'12.0.6118.4',N'SQL Server 2014 Service Pack 3',N'GDR+SU2')
,(N'12.0.6108.1',N'SQL Server 2014 Service Pack 3',N'GDR+SU1')
,(N'12.0.6024.0',N'SQL Server 2014 Service Pack 3',N'SP3')
,(N'12.0.5687.1',N'SQL Server 2014 Service Pack 2',N'CU18')
,(N'12.0.5659.1',N'SQL Server 2014 Service Pack 2',N'CU17+SU')
,(N'12.0.5632.1',N'SQL Server 2014 Service Pack 2',N'CU17')
,(N'12.0.5626.1',N'SQL Server 2014 Service Pack 2',N'CU16')
,(N'12.0.5605.1',N'SQL Server 2014 Service Pack 2',N'CU15')
,(N'12.0.5600.1',N'SQL Server 2014 Service Pack 2',N'CU14')
,(N'12.0.5590.1',N'SQL Server 2014 Service Pack 2',N'CU13')
,(N'12.0.5589.7',N'SQL Server 2014 Service Pack 2',N'CU12')
,(N'12.0.5579.0',N'SQL Server 2014 Service Pack 2',N'CU11')
,(N'12.0.5571.0',N'SQL Server 2014 Service Pack 2',N'CU10')
,(N'12.0.5563.0',N'SQL Server 2014 Service Pack 2',N'CU9')
,(N'12.0.5557.0',N'SQL Server 2014 Service Pack 2',N'CU8')
,(N'12.0.5556.0',N'SQL Server 2014 Service Pack 2',N'CU7')
,(N'12.0.5553.0',N'SQL Server 2014 Service Pack 2',N'CU6')
,(N'12.0.5546.0',N'SQL Server 2014 Service Pack 2',N'CU5')
,(N'12.0.5540.0',N'SQL Server 2014 Service Pack 2',N'CU4')
,(N'12.0.5538.0',N'SQL Server 2014 Service Pack 2',N'CU3')
,(N'12.0.5532.0',N'SQL Server 2014 Service Pack 2',N'MS16-136')
,(N'12.0.5522.0',N'SQL Server 2014 Service Pack 2',N'CU2')
,(N'12.0.5511.0',N'SQL Server 2014 Service Pack 2',N'CU1')
,(N'12.0.5223.6',N'SQL Server 2014 Service Pack 2',N'GDR+SU3')
,(N'12.0.5214.6',N'SQL Server 2014 Service Pack 2',N'GDR+SU2')
,(N'12.0.5207.0',N'SQL Server 2014 Service Pack 2',N'GDR+SU1')
,(N'12.0.5203.0',N'SQL Server 2014 Service Pack 2',N'MS16-136')
,(N'12.0.5000.0',N'SQL Server 2014 Service Pack 2',N'SP2')
,(N'12.0.4522.0',N'SQL Server 2014 Service Pack 1',N'CU13')
,(N'12.0.4511.0',N'SQL Server 2014 Service Pack 1',N'CU12')
,(N'12.0.4502.0',N'SQL Server 2014 Service Pack 1',N'CU11')
,(N'12.0.4491.0',N'SQL Server 2014 Service Pack 1',N'CU10')
,(N'12.0.4487.0',N'SQL Server 2014 Service Pack 1',N'MS16-136')
,(N'12.0.4474.0',N'SQL Server 2014 Service Pack 1',N'CU9')
,(N'12.0.4468.0',N'SQL Server 2014 Service Pack 1',N'CU8')
,(N'12.0.4463.0',N'SQL Server 2014 Service Pack 1',N'FIX')
,(N'12.0.4459.0',N'SQL Server 2014 Service Pack 1',N'CU7')
,(N'12.0.4457.0',N'SQL Server 2014 Service Pack 1',N'CU6')
,(N'12.0.4449.0',N'SQL Server 2014 Service Pack 1',N'CU6')
,(N'12.0.4439.1',N'SQL Server 2014 Service Pack 1',N'CU5')
,(N'12.0.4437.0',N'SQL Server 2014 Service Pack 1',N'CU4+FIX')
,(N'12.0.4436.0',N'SQL Server 2014 Service Pack 1',N'CU4')
,(N'12.0.4427.24',N'SQL Server 2014 Service Pack 1',N'CU3')
,(N'12.0.4422.0',N'SQL Server 2014 Service Pack 1',N'CU2')
,(N'12.0.4416.0',N'SQL Server 2014 Service Pack 1',N'CU1')
,(N'12.0.4237.0',N'SQL Server 2014 Service Pack 1',N'GDR+SU')
,(N'12.0.4232.0',N'SQL Server 2014 Service Pack 1',N'MS16-136')
,(N'12.0.4219.0',N'SQL Server 2014 Service Pack 1',N'TLS')
,(N'12.0.4213.0',N'SQL Server 2014 Service Pack 1',N'MS15-058')
,(N'12.0.4100.1',N'SQL Server 2014 Service Pack 1',N'SP1')
,(N'12.0.2569.0',N'SQL Server 2014',N'CU14')
,(N'12.0.2568.0',N'SQL Server 2014',N'CU13')
,(N'12.0.2564.0',N'SQL Server 2014',N'CU12')
,(N'12.0.2560.0',N'SQL Server 2014',N'CU11')
,(N'12.0.2556.4',N'SQL Server 2014',N'CU10')
,(N'12.0.2553.0',N'SQL Server 2014',N'CU9')
,(N'12.0.2548.0',N'SQL Server 2014',N'MS15-058')
,(N'12.0.2546.0',N'SQL Server 2014',N'CU8')
,(N'12.0.2495.0',N'SQL Server 2014',N'CU7')
,(N'12.0.2480.0',N'SQL Server 2014',N'CU6')
,(N'12.0.2474.0',N'SQL Server 2014',N'CU5+FIX')
,(N'12.0.2456.0',N'SQL Server 2014',N'CU5')
,(N'12.0.2430.0',N'SQL Server 2014',N'CU4')
,(N'12.0.2402.0',N'SQL Server 2014',N'CU3')
,(N'12.0.2381.0',N'SQL Server 2014',N'MS14-044')
,(N'12.0.2370.0',N'SQL Server 2014',N'CU2')
,(N'12.0.2342.0',N'SQL Server 2014',N'CU1')
,(N'12.0.2271.0',N'SQL Server 2014',N'TLS')
,(N'12.0.2269.0',N'SQL Server 2014',N'MS15-058')
,(N'12.0.2254.0',N'SQL Server 2014',N'MS14-044')
,(N'12.0.2000.8',N'SQL Server 2014',N'RTM')

,(N'11.0.7507.2',N'SQL Server 2012 Service Pack 4',N'GDR+SU2')
,(N'11.0.7493.4',N'SQL Server 2012 Service Pack 4',N'GDR+SU1')
,(N'11.0.7469.6',N'SQL Server 2012 Service Pack 4',N'GDR+FIX')
,(N'11.0.7462.6',N'SQL Server 2012 Service Pack 4',N'GDR')
,(N'11.0.7001.0',N'SQL Server 2012 Service Pack 4',N'SP4')
,(N'11.0.6615.2',N'SQL Server 2012 Service Pack 3',N'CU10+SU')
,(N'11.0.6607.3',N'SQL Server 2012 Service Pack 3',N'CU10')
,(N'11.0.6598.0',N'SQL Server 2012 Service Pack 3',N'CU9')
,(N'11.0.6594.0',N'SQL Server 2012 Service Pack 3',N'CU8')
,(N'11.0.6579.0',N'SQL Server 2012 Service Pack 3',N'CU7')
,(N'11.0.6567.0',N'SQL Server 2012 Service Pack 3',N'MS16-136')
,(N'11.0.6544.0',N'SQL Server 2012 Service Pack 3',N'CU5')
,(N'11.0.6540.0',N'SQL Server 2012 Service Pack 3',N'CU4')
,(N'11.0.6537.0',N'SQL Server 2012 Service Pack 3',N'CU3')
,(N'11.0.6523.0',N'SQL Server 2012 Service Pack 3',N'CU2')
,(N'11.0.6518.0',N'SQL Server 2012 Service Pack 3',N'CU1')
,(N'11.0.6260.1',N'SQL Server 2012 Service Pack 3',N'GDR+SU2')
,(N'11.0.6251.0',N'SQL Server 2012 Service Pack 3',N'GDR+SU1')
,(N'11.0.6248.0',N'SQL Server 2012 Service Pack 3',N'MS16-136')
,(N'11.0.6216.27',N'SQL Server 2012 Service Pack 3',N'TLS')
,(N'11.0.6020.0',N'SQL Server 2012 Service Pack 3',N'SP3')
,(N'11.0.5678.0',N'SQL Server 2012 Service Pack 2',N'CU16')
,(N'11.0.5676.0',N'SQL Server 2012 Service Pack 2',N'MS16-136')
,(N'11.0.5657.0',N'SQL Server 2012 Service Pack 2',N'CU14')
,(N'11.0.5655.0',N'SQL Server 2012 Service Pack 2',N'CU13')
,(N'11.0.5649.0',N'SQL Server 2012 Service Pack 2',N'CU12')
,(N'11.0.5646.0',N'SQL Server 2012 Service Pack 2',N'CU11')
,(N'11.0.5644.2',N'SQL Server 2012 Service Pack 2',N'CU10')
,(N'11.0.5641.0',N'SQL Server 2012 Service Pack 2',N'CU9')
,(N'11.0.5634.1',N'SQL Server 2012 Service Pack 2',N'CU8')
,(N'11.0.5623.0',N'SQL Server 2012 Service Pack 2',N'CU7')
,(N'11.0.5613.0',N'SQL Server 2012 Service Pack 2',N'MS15-058')
,(N'11.0.5592.0',N'SQL Server 2012 Service Pack 2',N'CU6')
,(N'11.0.5582.0',N'SQL Server 2012 Service Pack 2',N'CU5')
,(N'11.0.5571.0',N'SQL Server 2012 Service Pack 2',N'FIX')
,(N'11.0.5569.0',N'SQL Server 2012 Service Pack 2',N'CU4')
,(N'11.0.5556.0',N'SQL Server 2012 Service Pack 2',N'CU3')
,(N'11.0.5548.0',N'SQL Server 2012 Service Pack 2',N'CU2')
,(N'11.0.5532.0',N'SQL Server 2012 Service Pack 2',N'CU1')
,(N'11.0.5522.0',N'SQL Server 2012 Service Pack 2',N'FIX')
,(N'11.0.5388.0',N'SQL Server 2012 Service Pack 2',N'MS16-136')
,(N'11.0.5352.0',N'SQL Server 2012 Service Pack 2',N'TLS')
,(N'11.0.5343.0',N'SQL Server 2012 Service Pack 2',N'MS15-058')
,(N'11.0.5058.0',N'SQL Server 2012 Service Pack 2',N'SP2')
,(N'11.0.3513.0',N'SQL Server 2012 Service Pack 1',N'MS15-058')
,(N'11.0.3492.0',N'SQL Server 2012 Service Pack 1',N'CU16')
,(N'11.0.3487.0',N'SQL Server 2012 Service Pack 1',N'CU15')
,(N'11.0.3486.0',N'SQL Server 2012 Service Pack 1',N'CU14')
,(N'11.0.3482.0',N'SQL Server 2012 Service Pack 1',N'CU13')
,(N'11.0.3470.0',N'SQL Server 2012 Service Pack 1',N'CU12')
,(N'11.0.3467.0',N'SQL Server 2012 Service Pack 1',N'FIX')
,(N'11.0.3460.0',N'SQL Server 2012 Service Pack 1',N'MS14-044')
,(N'11.0.3449.0',N'SQL Server 2012 Service Pack 1',N'CU11')
,(N'11.0.3437.0',N'SQL Server 2012 Service Pack 1',N'FIX')
,(N'11.0.3431.0',N'SQL Server 2012 Service Pack 1',N'CU10')
,(N'11.0.3412.0',N'SQL Server 2012 Service Pack 1',N'CU9')
,(N'11.0.3401.0',N'SQL Server 2012 Service Pack 1',N'CU8')
,(N'11.0.3393.0',N'SQL Server 2012 Service Pack 1',N'CU7')
,(N'11.0.3381.0',N'SQL Server 2012 Service Pack 1',N'CU6')
,(N'11.0.3373.0',N'SQL Server 2012 Service Pack 1',N'CU5')
,(N'11.0.3368.0',N'SQL Server 2012 Service Pack 1',N'CU4')
,(N'11.0.3349.0',N'SQL Server 2012 Service Pack 1',N'CU3')
,(N'11.0.3339.0',N'SQL Server 2012 Service Pack 1',N'CU2')
,(N'11.0.3321.0',N'SQL Server 2012 Service Pack 1',N'CU1')
,(N'11.0.3156.0',N'SQL Server 2012 Service Pack 1',N'MS15-058')
,(N'11.0.3153.0',N'SQL Server 2012 Service Pack 1',N'MS14-044')
,(N'11.0.3128.0',N'SQL Server 2012 Service Pack 1',N'FIX')
,(N'11.0.3000.0',N'SQL Server 2012 Service Pack 1',N'SP1')
,(N'11.0.2424.0',N'SQL Server 2012',N'CU11')
,(N'11.0.2420.0',N'SQL Server 2012',N'CU10')
,(N'11.0.2419.0',N'SQL Server 2012',N'CU9')
,(N'11.0.2410.0',N'SQL Server 2012',N'CU8')
,(N'11.0.2405.0',N'SQL Server 2012',N'CU7')
,(N'11.0.2401.0',N'SQL Server 2012',N'CU6')
,(N'11.0.2395.0',N'SQL Server 2012',N'CU5')
,(N'11.0.2383.0',N'SQL Server 2012',N'CU4')
,(N'11.0.2376.0',N'SQL Server 2012',N'MS12-070')
,(N'11.0.2332.0',N'SQL Server 2012',N'CU3')
,(N'11.0.2325.0',N'SQL Server 2012',N'CU2')
,(N'11.0.2316.0',N'SQL Server 2012',N'CU1')
,(N'11.0.2218.0',N'SQL Server 2012',N'MS12-070')
,(N'11.0.2100.0',N'SQL Server 2012',N'RTM')

,(N'10.50.6560.0',N'SQL Server 2008 R2 Service Pack 3',N'GDR+SU')
,(N'10.50.6542.0',N'SQL Server 2008 R2 Service Pack 3',N'TLS')
,(N'10.50.6537.0',N'SQL Server 2008 R2 Service Pack 3',N'TLS')
,(N'10.50.6529.0',N'SQL Server 2008 R2 Service Pack 3',N'MS15-058')
,(N'10.50.6525.0',N'SQL Server 2008 R2 Service Pack 3',N'FIX')
,(N'10.50.6220.0',N'SQL Server 2008 R2 Service Pack 3',N'MS15-058')
,(N'10.50.6000.34',N'SQL Server 2008 R2 Service Pack 3',N'SP3')
,(N'10.50.4344.0',N'SQL Server 2008 R2 Service Pack 2',N'TLS')
,(N'10.50.4343.0',N'SQL Server 2008 R2 Service Pack 2',N'TLS')
,(N'10.50.4339.0',N'SQL Server 2008 R2 Service Pack 2',N'MS15-058')
,(N'10.50.4331.0',N'SQL Server 2008 R2 Service Pack 2',N'MS14-044')
,(N'10.50.4319.0',N'SQL Server 2008 R2 Service Pack 2',N'CU13')
,(N'10.50.4305.0',N'SQL Server 2008 R2 Service Pack 2',N'CU12')
,(N'10.50.4302.0',N'SQL Server 2008 R2 Service Pack 2',N'CU11')
,(N'10.50.4297.0',N'SQL Server 2008 R2 Service Pack 2',N'CU10')
,(N'10.50.4295.0',N'SQL Server 2008 R2 Service Pack 2',N'CU9')
,(N'10.50.4290.0',N'SQL Server 2008 R2 Service Pack 2',N'CU8')
,(N'10.50.4286.0',N'SQL Server 2008 R2 Service Pack 2',N'CU7')
,(N'10.50.4285.0',N'SQL Server 2008 R2 Service Pack 2',N'CU6')
,(N'10.50.4279.0',N'SQL Server 2008 R2 Service Pack 2',N'CU6')
,(N'10.50.4276.0',N'SQL Server 2008 R2 Service Pack 2',N'CU5')
,(N'10.50.4270.0',N'SQL Server 2008 R2 Service Pack 2',N'CU4')
,(N'10.50.4266.0',N'SQL Server 2008 R2 Service Pack 2',N'CU3')
,(N'10.50.4263.0',N'SQL Server 2008 R2 Service Pack 2',N'CU2')
,(N'10.50.4260.0',N'SQL Server 2008 R2 Service Pack 2',N'CU1')
,(N'10.50.4047.0',N'SQL Server 2008 R2 Service Pack 2',N'TLS')
,(N'10.50.4046.0',N'SQL Server 2008 R2 Service Pack 2',N'TLS')
,(N'10.50.4042.0',N'SQL Server 2008 R2 Service Pack 2',N'MS15-058')
,(N'10.50.4033.0',N'SQL Server 2008 R2 Service Pack 2',N'MS14-044')
,(N'10.50.4000.0',N'SQL Server 2008 R2 Service Pack 2',N'SP2')
,(N'10.50.2500.0',N'SQL Server 2008 R2 Service Pack 1',N'SP1')
,(N'10.50.1600.1',N'SQL Server 2008 R2',N'RTM')

,(N'10.00.6556.0',N'SQL Server 2008 Service Pack 4',N'GDR+SU')
,(N'10.00.6547.0',N'SQL Server 2008 Service Pack 4',N'TLS')
,(N'10.00.6543.0',N'SQL Server 2008 Service Pack 4',N'TLS')
,(N'10.00.6535.0',N'SQL Server 2008 Service Pack 4',N'MS15-058')
,(N'10.00.6526.0',N'SQL Server 2008 Service Pack 4',N'FIX')
,(N'10.00.6241.0',N'SQL Server 2008 Service Pack 4',N'MS15-058')
,(N'10.00.6000.0',N'SQL Server 2008 Service Pack 4',N'SP4')
,(N'10.00.5896.0',N'SQL Server 2008 Service Pack 3',N'TLS')
,(N'10.00.5894.0',N'SQL Server 2008 Service Pack 3',N'TLS')
,(N'10.00.5890.0',N'SQL Server 2008 Service Pack 3',N'MS15-058')
,(N'10.00.5869.0',N'SQL Server 2008 Service Pack 3',N'MS14-044')
,(N'10.00.5861.0',N'SQL Server 2008 Service Pack 3',N'CU17')
,(N'10.00.5852.0',N'SQL Server 2008 Service Pack 3',N'CU16')
,(N'10.00.5850.0',N'SQL Server 2008 Service Pack 3',N'CU15')
,(N'10.00.5848.0',N'SQL Server 2008 Service Pack 3',N'CU14')
,(N'10.00.5846.0',N'SQL Server 2008 Service Pack 3',N'CU13')
,(N'10.00.5844.0',N'SQL Server 2008 Service Pack 3',N'CU12')
,(N'10.00.5841.0',N'SQL Server 2008 Service Pack 3',N'CU11')
,(N'10.00.5840.0',N'SQL Server 2008 Service Pack 3',N'CU11')
,(N'10.00.5835.0',N'SQL Server 2008 Service Pack 3',N'CU10')
,(N'10.00.5829.0',N'SQL Server 2008 Service Pack 3',N'CU9')
,(N'10.00.5828.0',N'SQL Server 2008 Service Pack 3',N'CU8')
,(N'10.00.5826.0',N'SQL Server 2008 Service Pack 3',N'MS12-070')
,(N'10.00.5794.0',N'SQL Server 2008 Service Pack 3',N'CU7')
,(N'10.00.5788.0',N'SQL Server 2008 Service Pack 3',N'CU6')
,(N'10.00.5785.0',N'SQL Server 2008 Service Pack 3',N'CU5')
,(N'10.00.5775.0',N'SQL Server 2008 Service Pack 3',N'CU4')
,(N'10.00.5770.0',N'SQL Server 2008 Service Pack 3',N'CU3')
,(N'10.00.5768.0',N'SQL Server 2008 Service Pack 3',N'CU2')
,(N'10.00.5766.0',N'SQL Server 2008 Service Pack 3',N'CU1')
,(N'10.00.5545.0',N'SQL Server 2008 Service Pack 3',N'TLS')
,(N'10.00.5544.0',N'SQL Server 2008 Service Pack 3',N'TLS')
,(N'10.00.5538.0',N'SQL Server 2008 Service Pack 3',N'MS15-058')
,(N'10.00.5520.0',N'SQL Server 2008 Service Pack 3',N'MS14-044')
,(N'10.00.5512.0',N'SQL Server 2008 Service Pack 3',N'MS12-070')
,(N'10.00.5500.0',N'SQL Server 2008 Service Pack 3',N'SP3')
,(N'10.00.4000.0',N'SQL Server 2008 Service Pack 2',N'SP2')
,(N'10.00.2531.0',N'SQL Server 2008 Service Pack 1',N'SP1')
,(N'10.00.1600.0',N'SQL Server 2008',N'RTM')

;

RETURN ;

END ;

GO

IF OBJECT_ID ( 'dbo.v_WaitType' ) IS NULL
EXEC sp_executesql N'CREATE FUNCTION dbo.v_WaitType ( ) RETURNS @Table TABLE ( _ BIT NULL ) AS BEGIN RETURN ; END' ;

GO

--
-- This function will result with dictionary of wait type names and descriptions.
--
ALTER FUNCTION dbo.v_WaitType ( )
RETURNS @Table TABLE
(
  [Name] NVARCHAR(60) COLLATE SQL_Latin1_General_CP1_CI_AS ,
  [Text] NVARCHAR(1000) COLLATE SQL_Latin1_General_CP1_CI_AS ,
  UNIQUE CLUSTERED ( [Name] )
)
AS
BEGIN

INSERT INTO @Table ( [Name] , [Text] )
VALUES
 ('','')
,('ABR','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('AM_INDBUILD_ALLOCATION','Internal use only.')
,('AM_SCHEMAMGR_UNSHARED_CACHE','Internal use only.')
,('ASSEMBLY_FILTER_HASHTABLE','Internal use only.')
,('ASSEMBLY_LOAD','Exclusive access to assembly loading.')
,('ASYNC_DISKPOOL_LOCK','Attempt to synchronize parallel threads that are performing tasks such as creating or initializing a file.')
,('ASYNC_IO_COMPLETION','Waiting for I/Os to finish.')
,('ASYNC_NETWORK_IO','Occurs on network writes when the task is blocked behind the network. Verify that the client is processing data from the server.')
,('ASYNC_OP_COMPLETION','Internal use only.')
,('ASYNC_OP_CONTEXT_READ','Internal use only.')
,('ASYNC_OP_CONTEXT_WRITE','Internal use only.')
,('ASYNC_SOCKETDUP_IO','Internal use only.')
,('AUDIT_GROUPCACHE_LOCK','Wait on a lock that controls access to a special cache. The cache contains information about which audits are being used to audit each audit action group.')
,('AUDIT_LOGINCACHE_LOCK','Wait on a lock that controls access to a special cache. The cache contains information about which audits are being used to audit login audit action groups.')
,('AUDIT_ON_DEMAND_TARGET_LOCK','Wait on a lock that is used to ensure single initialization of audit related Extended Event targets.')
,('AUDIT_XE_SESSION_MGR','Wait on a lock that is used to synchronize the starting and stopping of audit related Extended Events sessions.')
,('BACKUP','Task is blocked as part of backup processing.')
,('BACKUP_OPERATOR','Waiting for a tape mount. To view the tape status, query sys.dm_io_backup_tapes. If a mount operation is not pending, this wait type may indicate a hardware problem with the tape drive.')
,('BACKUPBUFFER','Backup task is waiting for data, or is waiting for a buffer in which to store data. This type is not typical, except when a task is waiting for a tape mount.')
,('BACKUPIO','Backup task is waiting for data, or is waiting for a buffer in which to store data. This type is not typical, except when a task is waiting for a tape mount.')
,('BACKUPTHREAD','Waiting for a backup task to finish. Wait times may be long, from several minutes to several hours. If the task that is being waited on is in an I/O process, this type does not indicate a problem.')
,('BAD_PAGE_PROCESS','Background suspect page logger is trying to avoid running more than every five seconds. Excessive suspect pages cause the logger to run frequently.')
,('BLOB_METADATA','Internal use only.')
,('BMPALLOCATION','Parallel batch-mode plans when synchronizing the allocation of a large bitmap filter. If waiting is excessive and cannot be reduced by tuning the query (such as adding indexes), consider adjusting the cost threshold for parallelism or lowering the degree of parallelism.')
,('BMPBUILD','Parallel batch-mode plans when synchronizing the building of a large bitmap filter. If waiting is excessive and cannot be reduced by tuning the query (such as adding indexes), consider adjusting the cost threshold for parallelism or lowering the degree of parallelism.')
,('BMPREPARTITION','Parallel batch-mode plans when synchronizing the repartitioning of a large bitmap filter. If waiting is excessive and cannot be reduced by tuning the query (such as adding indexes), consider adjusting the cost threshold for parallelism or lowering the degree of parallelism.')
,('BMPREPLICATION','Parallel batch-mode plans when synchronizing the replication of a large bitmap filter across worker threads. If waiting is excessive and cannot be reduced by tuning the query (such as adding indexes), consider adjusting the cost threshold for parallelism or lowering the degree of parallelism.')
,('BPSORT','Parallel batch-mode plans when synchronizing the sorting of a dataset across multiple threads. If waiting is excessive and cannot be reduced by tuning the query (such as adding indexes), consider adjusting the cost threshold for parallelism or lowering the degree of parallelism.')
,('BROKER_CONNECTION_RECEIVE_TASK','Waiting for access to receive a message on a connection endpoint. Receive access to the endpoint is serialized.')
,('BROKER_DISPATCHER','Internal use only.')
,('BROKER_ENDPOINT_STATE_MUTEX','There is contention to access the state of a Service Broker connection endpoint. Access to the state for changes is serialized.')
,('BROKER_EVENTHANDLER','Waiting in the primary event handler of the Service Broker. This should occur very briefly.')
,('BROKER_FORWARDER','Internal use only.')
,('BROKER_INIT','Initializing Service Broker in each active database. This should occur infrequently.')
,('BROKER_MASTERSTART','Waiting for the primary event handler of the Service Broker to start. This should occur very briefly.')
,('BROKER_RECEIVE_WAITFOR','RECEIVE WAITFOR is waiting. This may mean that either no messages are ready to be received in the queue or a lock contention is preventing it from receiving messages from the queue.')
,('BROKER_REGISTERALLENDPOINTS','Initialization of a Service Broker connection endpoint. This should occur very briefly.')
,('BROKER_SERVICE','Service Broker destination list that is associated with a target service is updated or re-prioritized.')
,('BROKER_SHUTDOWN','There is a planned shutdown of Service Broker. This should occur very briefly, if at all.')
,('BROKER_START','Internal use only.')
,('BROKER_TASK_SHUTDOWN','Internal use only.')
,('BROKER_TASK_STOP','Service Broker queue task handler tries to shut down the task. The state check is serialized and must be in a running state beforehand.')
,('BROKER_TASK_SUBMIT','Internal use only.')
,('BROKER_TO_FLUSH','Service Broker lazy flusher flushes the in-memory transmission objects to a work table.')
,('BROKER_TRANSMISSION_OBJECT','Internal use only.')
,('BROKER_TRANSMISSION_TABLE','Internal use only.')
,('BROKER_TRANSMISSION_WORK','Internal use only.')
,('BROKER_TRANSMITTER','Service Broker transmitter is waiting for work. Service Broker has a component known as the Transmitter which schedules messages from multiple dialogs to be sent across the wire over one or more connection endpoints. The transmitter has 2 dedicated threads for this purpose. This wait type is charged when these transmitter threads are waiting for dialog messages to be sent using the transport connections. High values of waiting_tasks_count for this wait type point to intermittent work for these transmitter threads and are not indications of any performance problem. If service broker is not used at all, waiting_tasks_count should be 2 (for the 2 transmitter threads) and wait_time_ms should be twice the duration since instance startup. See Service broker wait stats.')
,('BUILTIN_HASHKEY_MUTEX','May occur after startup of instance, while internal data structures are initializing. Will not recur once data structures have initialized.')
,('CHANGE_TRACKING_WAITFORCHANGES','Internal use only.')
,('CHECK_PRINT_RECORD','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('CHECK_SCANNER_MUTEX','Internal use only.')
,('CHECK_TABLES_INITIALIZATION','Internal use only.')
,('CHECK_TABLES_SINGLE_SCAN','Internal use only.')
,('CHECK_TABLES_THREAD_BARRIER','Internal use only.')
,('CHECKPOINT_QUEUE','Checkpoint task is waiting for the next checkpoint request.')
,('CHKPT','Occurs at server startup to tell the checkpoint thread that it can start.')
,('CLEAR_DB','Occurs during operations that change the state of a database, such as opening or closing a database.')
,('CLR_AUTO_EVENT','Task is currently performing common language runtime (CLR) execution and is waiting for a particular autoevent to be initiated. Long waits are typical, and do not indicate a problem.')
,('CLR_CRST','Task is currently performing CLR execution and is waiting to enter a critical section of the task that is currently being used by another task.')
,('CLR_JOIN','Task is currently performing CLR execution and waiting for another task to end. This wait state There is a join between tasks.')
,('CLR_MANUAL_EVENT','Task is currently performing CLR execution and is waiting for a specific manual event to be initiated.')
,('CLR_MEMORY_SPY','Occurs during a wait on lock acquisition for a data structure that is used to record all virtual memory allocations that come from CLR. The data structure is locked to maintain its integrity if there is parallel access.')
,('CLR_MONITOR','Task is currently performing CLR execution and is waiting to obtain a lock on the monitor.')
,('CLR_RWLOCK_READER','Task is currently performing CLR execution and is waiting for a reader lock.')
,('CLR_RWLOCK_WRITER','Task is currently performing CLR execution and is waiting for a writer lock.')
,('CLR_SEMAPHORE','Task is currently performing CLR execution and is waiting for a semaphore.')
,('CLR_TASK_START','Waiting for a CLR task to complete startup.')
,('CLRHOST_STATE_ACCESS','Occurs where there is a wait to acquire exclusive access to the CLR-hosting data structures. This wait type occurs while setting up or tearing down the CLR runtime.')
,('CMEMPARTITIONED','Internal use only.')
,('CMEMTHREAD','Waiting on a thread-safe memory object. The wait time might increase when there is contention caused by multiple tasks trying to allocate memory from the same memory object.')
,('COLUMNSTORE_BUILD_THROTTLE','Internal use only.')
,('COLUMNSTORE_COLUMNDATASET_SESSION_LIST','Internal use only.')
,('COMMIT_TABLE','Internal use only.')
,('CONNECTION_ENDPOINT_LOCK','Internal use only.')
,('COUNTRECOVERYMGR','Internal use only.')
,('CREATE_DATINISERVICE','Internal use only.')
,('CXCONSUMER','Parallel query plans when a consumer thread waits for a producer thread to send rows. This is a normal part of parallel query execution.')
,('CXPACKET','Parallel query plans when synchronizing the query processor exchange iterator, and when producing and consuming rows. If waiting is excessive and cannot be reduced by tuning the query (such as adding indexes), consider adjusting the cost threshold for parallelism or lowering the degree of parallelism.')
,('CXROWSET_SYNC','Occurs during a parallel range scan.')
,('DAC_INIT','Occurs while the dedicated administrator connection is initializing.')
,('DBCC_SCALE_OUT_EXPR_CACHE','Internal use only.')
,('DBMIRROR_DBM_EVENT','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('DBMIRROR_DBM_MUTEX','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('DBMIRROR_EVENTS_QUEUE','Database mirroring waits for events to process.')
,('DBMIRROR_SEND','Waiting for a communications backlog at the network layer to clear to be able to send messages. Indicates that the communications layer is starting to become overloaded and affect the database mirroring data throughput.')
,('DBMIRROR_WORKER_QUEUE','Indicates that the database mirroring worker task is waiting for more work.')
,('DBMIRRORING_CMD','Waiting for log records to be flushed to disk. This wait state is expected to be held for long periods of time.')
,('DBSEEDING_FLOWCONTROL','Internal use only.')
,('DBSEEDING_OPERATION','Internal use only.')
,('DEADLOCK_ENUM_MUTEX','Deadlock monitor and sys.dm_os_waiting_tasks try to make sure that SQL Server is not running multiple deadlock searches at the same time.')
,('DEADLOCK_TASK_SEARCH','Large waiting time on this resource indicates that the server is executing queries on top of sys.dm_os_waiting_tasks, and these queries are blocking deadlock monitor from running deadlock search. This wait type is used by deadlock monitor only. Queries on top of sys.dm_os_waiting_tasks use DEADLOCK_ENUM_MUTEX.')
,('DEBUG','Occurs during Transact-SQL and CLR debugging for internal synchronization.')
,('DIRECTLOGCONSUMER_LIST','Internal use only.')
,('DIRTY_PAGE_POLL','Internal use only.')
,('DIRTY_PAGE_SYNC','Internal use only.')
,('DIRTY_PAGE_TABLE_LOCK','Internal use only.')
,('DISABLE_VERSIONING','SQL Server polls the version transaction manager to see whether the timestamp of the earliest active transaction is later than the timestamp of when the state started changing. If this is this case, all the snapshot transactions that were started before the ALTER DATABASE statement was run have finished. This wait state is used when SQL Server disables versioning by using the ALTER DATABASE statement.')
,('DISKIO_SUSPEND','Waiting to access a file when an external backup is active. This is reported for each waiting user process. A count larger than five per user process may indicate that the external backup is taking too much time to finish.')
,('DISPATCHER_PRIORITY_QUEUE_SEMAPHORE','Internal use only.')
,('DISPATCHER_QUEUE_SEMAPHORE','Occurs when a thread from the dispatcher pool is waiting for more work to process. The wait time for this wait type is expected to increase when the dispatcher is idle.')
,('DLL_LOADING_MUTEX','Occurs once while waiting for the XML parser DLL to load.')
,('DPT_ENTRY_LOCK','Internal use only.')
,('DROP_DATABASE_TIMER_TASK','Internal use only.')
,('DROPTEMP','Occurs between attempts to drop a temporary object if the previous attempt failed. The wait duration grows exponentially with each failed drop attempt.')
,('DTC','Waiting on an event that is used to manage state transition. This state controls when the recovery of Microsoft Distributed Transaction Coordinator (MS DTC) transactions occurs after SQL Server receives notification that the MS DTC service has become unavailable.')
,('DTC_ABORT_REQUEST','Occurs in a MS DTC worker session when the session is waiting to take ownership of a MS DTC transaction. After MS DTC owns the transaction, the session can roll back the transaction. Generally, the session will wait for another session that is using the transaction.')
,('DTC_RESOLVE','Occurs when a recovery task is waiting for the master database in a cross-database transaction so that the task can query the outcome of the transaction.')
,('DTC_STATE','Waiting on an event that protects changes to the internal MS DTC global state object. This state should be held for very short periods of time.')
,('DTC_TMDOWN_REQUEST','Occurs in a MS DTC worker session when SQL Server receives notification that the MS DTC service is not available. First, the worker will wait for the MS DTC recovery process to start. Then, the worker waits to obtain the outcome of the distributed transaction that the worker is working on. This may continue until the connection with the MS DTC service has been reestablished.')
,('DTC_WAITFOR_OUTCOME','Occurs when recovery tasks wait for MS DTC to become active to enable the resolution of prepared transactions.')
,('DTCNEW_ENLIST','Internal use only.')
,('DTCNEW_PREPARE','Internal use only.')
,('DTCNEW_RECOVERY','Internal use only.')
,('DTCNEW_TM','Internal use only.')
,('DTCNEW_TRANSACTION_ENLISTMENT','Internal use only.')
,('DTCPNTSYNC','Internal use only.')
,('DUMP_LOG_COORDINATOR','Occurs when a main task is waiting for a subtask to generate data. Ordinarily, this state does not occur. A long wait indicates an unexpected blockage. The subtask should be investigated.')
,('DUMP_LOG_COORDINATOR_QUEUE','Internal use only.')
,('DUMPTRIGGER','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('EC','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('EE_PMOLOCK','Synchronization of certain types of memory allocations during statement execution.')
,('EE_SPECPROC_MAP_INIT','Synchronization of internal procedure hash table creation. This wait can only occur during the initial accessing of the hash table after the SQL Server instance starts.')
,('ENABLE_EMPTY_VERSIONING','Internal use only.')
,('ENABLE_VERSIONING','Occurs when SQL Server waits for all update transactions in this database to finish before declaring the database ready to transition to snapshot isolation allowed state. This state is used when SQL Server enables snapshot isolation by using the ALTER DATABASE statement.')
,('ERROR_REPORTING_MANAGER','Synchronization of multiple concurrent error log initializations.')
,('EXCHANGE','Synchronization in the query processor exchange iterator during parallel queries.')
,('EXECSYNC','Occurs during parallel queries while synchronizing in query processor in areas not related to the exchange iterator. Examples of such areas are bitmaps, large binary objects (LOBs), and the spool iterator. LOBs may frequently use this wait state.')
,('EXECUTION_PIPE_EVENT_INTERNAL','Synchronization between producer and consumer parts of batch execution that are submitted through the connection context.')
,('EXTERNAL_RG_UPDATE','Internal use only.')
,('EXTERNAL_SCRIPT_NETWORK_IO','Internal use only.')
,('EXTERNAL_SCRIPT_PREPARE_SERVICE','Internal use only.')
,('EXTERNAL_SCRIPT_SHUTDOWN','Internal use only.')
,('FABRIC_HADR_TRANSPORT_CONNECTION','Internal use only.')
,('FABRIC_REPLICA_CONTROLLER_LIST','Internal use only.')
,('FABRIC_REPLICA_CONTROLLER_STATE_AND_CONFIG','Internal use only.')
,('FABRIC_REPLICA_PUBLISHER_EVENT_PUBLISH','Internal use only.')
,('FABRIC_REPLICA_PUBLISHER_SUBSCRIBER_LIST','Internal use only.')
,('FABRIC_WAIT_FOR_BUILD_REPLICA_EVENT_PROCESSING','Internal use only.')
,('FAILPOINT','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('FCB_REPLICA_READ','Occurs when the reads of a snapshot (or a temporary snapshot created by DBCC) sparse file are synchronized.')
,('FCB_REPLICA_WRITE','Occurs when the pushing or pulling of a page to a snapshot (or a temporary snapshot created by DBCC) sparse file is synchronized.')
,('FEATURE_SWITCHES_UPDATE','Internal use only.')
,('FFT_NSO_DB_KILL_FLAG','Internal use only.')
,('FFT_NSO_DB_LIST','Internal use only.')
,('FFT_NSO_FCB','Internal use only.')
,('FFT_NSO_FCB_FIND','Internal use only.')
,('FFT_NSO_FCB_PARENT','Internal use only.')
,('FFT_NSO_FCB_RELEASE_CACHED_ENTRIES','Internal use only.')
,('FFT_NSO_FCB_STATE','Internal use only.')
,('FFT_NSO_FILEOBJECT','Internal use only.')
,('FFT_NSO_TABLE_LIST','Internal use only.')
,('FFT_NTFS_STORE','Internal use only.')
,('FFT_RECOVERY','Internal use only.')
,('FFT_RSFX_COMM','Internal use only.')
,('FFT_RSFX_WAIT_FOR_MEMORY','Internal use only.')
,('FFT_STARTUP_SHUTDOWN','Internal use only.')
,('FFT_STORE_DB','Internal use only.')
,('FFT_STORE_ROWSET_LIST','Internal use only.')
,('FFT_STORE_TABLE','Internal use only.')
,('FILE_VALIDATION_THREADS','Internal use only.')
,('FILESTREAM_CACHE','Internal use only.')
,('FILESTREAM_CHUNKER','Internal use only.')
,('FILESTREAM_CHUNKER_INIT','Internal use only.')
,('FILESTREAM_FCB','Internal use only.')
,('FILESTREAM_FILE_OBJECT','Internal use only.')
,('FILESTREAM_WORKITEM_QUEUE','Internal use only.')
,('FILETABLE_SHUTDOWN','Internal use only.')
,('FOREIGN_REDO','Internal use only.')
,('FORWARDER_TRANSITION','Internal use only.')
,('FS_FC_RWLOCK','There is a wait by the FILESTREAM garbage collector to do either of the following:')
,('FS_GARBAGE_COLLECTOR_SHUTDOWN','Occurs when the FILESTREAM garbage collector is waiting for cleanup tasks to be completed.')
,('FS_HEADER_RWLOCK','There is a wait to acquire access to the FILESTREAM header of a FILESTREAM data container to either read or update contents in the FILESTREAM header file (Filestream.hdr).')
,('FS_LOGTRUNC_RWLOCK','There is a wait to acquire access to FILESTREAM log truncation to do either of the following:')
,('FSA_FORCE_OWN_XACT','FILESTREAM file I/O operation needs to bind to the associated transaction, but the transaction is currently owned by another session.')
,('FSAGENT','FILESTREAM file I/O operation is waiting for a FILESTREAM agent resource that is being used by another file I/O operation.')
,('FSTR_CONFIG_MUTEX','There is a wait for another FILESTREAM feature reconfiguration to be completed.')
,('FSTR_CONFIG_RWLOCK','There is a wait to serialize access to the FILESTREAM configuration parameters.')
,('FT_COMPROWSET_RWLOCK','Full-text is waiting on fragment metadata operation. Documented for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('FT_IFTS_RWLOCK','Full-text is waiting on internal synchronization. Documented for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('FT_IFTS_SCHEDULER_IDLE_WAIT','Full-text scheduler sleep wait type. The scheduler is idle.')
,('FT_IFTSHC_MUTEX','Full-text is waiting on an fdhost control operation. Documented for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('FT_IFTSISM_MUTEX','Full-text is waiting on communication operation. Documented for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('FT_MASTER_MERGE','Full-text is waiting on master merge operation. Documented for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('FT_MASTER_MERGE_COORDINATOR','Internal use only.')
,('FT_METADATA_MUTEX','Documented for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('FT_PROPERTYLIST_CACHE','Internal use only.')
,('FT_RESTART_CRAWL','Occurs when a full-text crawl needs to restart from a last known good point to recover from a transient failure. The wait lets the worker tasks currently working on that population to complete or exit the current step.')
,('GDMA_GET_RESOURCE_OWNER','Internal use only.')
,('GHOSTCLEANUP_UPDATE_STATS','Internal use only.')
,('GHOSTCLEANUPSYNCMGR','Internal use only.')
,('GLOBAL_QUERY_CANCEL','Internal use only.')
,('GLOBAL_QUERY_CLOSE','Internal use only.')
,('GLOBAL_QUERY_CONSUMER','Internal use only.')
,('GLOBAL_QUERY_PRODUCER','Internal use only.')
,('GLOBAL_TRAN_CREATE','Internal use only.')
,('GLOBAL_TRAN_UCS_SESSION','Internal use only.')
,('GUARDIAN','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('HADR_AG_MUTEX','Occurs when an Always On DDL statement or Windows Server Failover Clustering command is waiting for exclusive read/write access to the configuration of an availability group.')
,('HADR_AR_CRITICAL_SECTION_ENTRY','Occurs when an Always On DDL statement or Windows Server Failover Clustering command is waiting for exclusive read/write access to the runtime state of the local replica of the associated availability group.')
,('HADR_AR_MANAGER_MUTEX','Occurs when an availability replica shutdown is waiting for startup to complete or an availability replica startup is waiting for shutdown to complete. Internal use only.')
,('HADR_AR_UNLOAD_COMPLETED','Internal use only.')
,('HADR_ARCONTROLLER_NOTIFICATIONS_SUBSCRIBER_LIST','The publisher for an availability replica event (such as a state change or configuration change) is waiting for exclusive read/write access to the list of event subscribers. Internal use only.')
,('HADR_BACKUP_BULK_LOCK','The Always On primary database received a backup request from a secondary database and is waiting for the background thread to finish processing the request on acquiring or releasing the BulkOp lock.')
,('HADR_BACKUP_QUEUE','The backup background thread of the Always On primary database is waiting for a new work request from the secondary database. (typically, this occurs when the primary database is holding the BulkOp log and is waiting for the secondary database to indicate that the primary database can release the lock).')
,('HADR_CLUSAPI_CALL','A SQL Server thread is waiting to switch from non-preemptive mode (scheduled by SQL Server) to preemptive mode (scheduled by the operating system) in order to invoke Windows Server Failover Clustering APIs.')
,('HADR_COMPRESSED_CACHE_SYNC','Waiting for access to the cache of compressed log blocks that is used to avoid redundant compression of the log blocks sent to multiple secondary databases.')
,('HADR_CONNECTIVITY_INFO','Internal use only.')
,('HADR_DATABASE_FLOW_CONTROL','Waiting for messages to be sent to the partner when the maximum number of queued messages has been reached. Indicates that the log scans are running faster than the network sends. This is an issue only if network sends are slower than expected.')
,('HADR_DATABASE_VERSIONING_STATE','Occurs on the versioning state change of an Always On secondary database. This wait is for internal data structures and is usually is very short with no direct effect on data access.')
,('HADR_DATABASE_WAIT_FOR_RECOVERY','Internal use only.')
,('HADR_DATABASE_WAIT_FOR_RESTART','Waiting for the database to restart under Always On Availability Groups control. Under normal conditions, this is not a customer issue because waits are expected here.')
,('HADR_DATABASE_WAIT_FOR_TRANSITION_TO_VERSIONING','A query on object(s) in a readable secondary database of an Always On availability group is blocked on row versioning while waiting for commit or rollback of all transactions that were in-flight when the secondary replica was enabled for read workloads. This wait type guarantees that row versions are available before execution of a query under snapshot isolation.')
,('HADR_DB_COMMAND','Waiting for responses to conversational messages (which require an explicit response from the other side, using the Always On conversational message infrastructure). A number of different message types use this wait type.')
,('HADR_DB_OP_COMPLETION_SYNC','Waiting for responses to conversational messages (which require an explicit response from the other side, using the Always On conversational message infrastructure). A number of different message types use this wait type.')
,('HADR_DB_OP_START_SYNC','An Always On DDL statement or a Windows Server Failover Clustering command is waiting for serialized access to an availability database and its runtime state.')
,('HADR_DBR_SUBSCRIBER','The publisher for an availability replica event (such as a state change or configuration change) is waiting for exclusive read/write access to the runtime state of an event subscriber that corresponds to an availability database. Internal use only.')
,('HADR_DBR_SUBSCRIBER_FILTER_LIST','The publisher for an availability replica event (such as a state change or configuration change) is waiting for exclusive read/write access to the list of event subscribers that correspond to availability databases. Internal use only.')
,('HADR_DBSEEDING','Internal use only.')
,('HADR_DBSEEDING_LIST','Internal use only.')
,('HADR_DBSTATECHANGE_SYNC','Concurrency control wait for updating the internal state of the database replica.')
,('HADR_FABRIC_CALLBACK','Internal use only.')
,('HADR_FILESTREAM_BLOCK_FLUSH','The FILESTREAM Always On transport manager is waiting until processing of a log block is finished.')
,('HADR_FILESTREAM_FILE_CLOSE','The FILESTREAM Always On transport manager is waiting until the next FILESTREAM file gets processed and its handle gets closed.')
,('HADR_FILESTREAM_FILE_REQUEST','An Always On secondary replica is waiting for the primary replica to send all requested FILESTREAM files during UNDO.')
,('HADR_FILESTREAM_IOMGR','The FILESTREAM Always On transport manager is waiting for R/W lock that protects the FILESTREAM Always On I/O manager during startup or shutdown.')
,('HADR_FILESTREAM_IOMGR_IOCOMPLETION','The FILESTREAM Always On I/O manager is waiting for I/O completion.')
,('HADR_FILESTREAM_MANAGER','The FILESTREAM Always On transport manager is waiting for the R/W lock that protects the FILESTREAM Always On transport manager during startup or shutdown.')
,('HADR_FILESTREAM_PREPROC','Internal use only.')
,('HADR_GROUP_COMMIT','Transaction commit processing is waiting to allow a group commit so that multiple commit log records can be put into a single log block. This wait is an expected condition that optimizes the log I/O, capture, and send operations.')
,('HADR_LOGCAPTURE_SYNC','Concurrency control around the log capture or apply object when creating or destroying scans. This is an expected wait when partners change state or connection status.')
,('HADR_LOGCAPTURE_WAIT','Waiting for log records to become available. Can occur either when waiting for new log records to be generated by connections or for I/O completion when reading log not in the cache. This is an expected wait if the log scan is caught up to the end of log or is reading from disk.')
,('HADR_LOGPROGRESS_SYNC','Concurrency control wait when updating the log progress status of database replicas.')
,('HADR_NOTIFICATION_DEQUEUE','A background task that processes Windows Server Failover Clustering notifications is waiting for the next notification. Internal use only.')
,('HADR_NOTIFICATION_WORKER_EXCLUSIVE_ACCESS','The Always On availability replica manager is waiting for serialized access to the runtime state of a background task that processes Windows Server Failover Clustering notifications. Internal use only.')
,('HADR_NOTIFICATION_WORKER_STARTUP_SYNC','A background task is waiting for the completion of the startup of a background task that processes Windows Server Failover Clustering notifications. Internal use only.')
,('HADR_NOTIFICATION_WORKER_TERMINATION_SYNC','A background task is waiting for the termination of a background task that processes Windows Server Failover Clustering notifications. Internal use only.')
,('HADR_PARTNER_SYNC','Concurrency control wait on the partner list.')
,('HADR_READ_ALL_NETWORKS','Waiting to get read or write access to the list of WSFC networks. Internal use only. Note: The engine keeps a list of WSFC networks that is used in dynamic management views (such as sys.dm_hadr_cluster_networks) or to validate Always On Transact-SQL statements that reference WSFC network information. This list is updated upon engine startup, WSFC related notifications, and internal Always On restart (for example, losing and regaining of WSFC quorum). Tasks will usually be blocked when an update in that list is in progress. ,')
,('HADR_RECOVERY_WAIT_FOR_CONNECTION','Waiting for the secondary database to connect to the primary database before running recovery. This is an expected wait, which can lengthen if the connection to the primary is slow to establish.')
,('HADR_RECOVERY_WAIT_FOR_UNDO','Database recovery is waiting for the secondary database to finish the reverting and initializing phase to bring it back to the common log point with the primary database. This is an expected wait after failovers.Undo progress can be tracked through the Windows System Monitor (perfmon.exe) and dynamic management views.')
,('HADR_REPLICAINFO_SYNC','Waiting for concurrency control to update the current replica state.')
,('HADR_SEEDING_CANCELLATION','Internal use only.')
,('HADR_SEEDING_FILE_LIST','Internal use only.')
,('HADR_SEEDING_LIMIT_BACKUPS','Internal use only.')
,('HADR_SEEDING_SYNC_COMPLETION','Internal use only.')
,('HADR_SEEDING_TIMEOUT_TASK','Internal use only.')
,('HADR_SEEDING_WAIT_FOR_COMPLETION','Internal use only.')
,('HADR_SYNC_COMMIT','Waiting for transaction commit processing for the synchronized secondary databases to harden the log. This wait is also reflected by the Transaction Delay performance counter. This wait type is expected for synchronized availability groups and indicates the time to send, write, and acknowledge log to the secondary databases.')
,('HADR_SYNCHRONIZING_THROTTLE','Waiting for transaction commit processing to allow a synchronizing secondary database to catch up to the primary end of log in order to transition to the synchronized state. This is an expected wait when a secondary database is catching up.')
,('HADR_TDS_LISTENER_SYNC','Either the internal Always On system or the WSFC cluster will request that listeners are started or stopped. The processing of this request is always asynchronous, and there is a mechanism to remove redundant requests. There are also moments that this process is suspended because of configuration changes. All waits related with this listener synchronization mechanism use this wait type. Internal use only.')
,('HADR_TDS_LISTENER_SYNC_PROCESSING','Used at the end of an Always On Transact-SQL statement that requires starting and/or stopping an availability group listener. Since the start/stop operation is done asynchronously, the user thread will block using this wait type until the situation of the listener is known.')
,('HADR_THROTTLE_LOG_RATE_GOVERNOR','Internal use only.')
,('HADR_THROTTLE_LOG_RATE_MISMATCHED_SLO','Occurs when a geo-replication secondary is configured with lower compute size (lower SLO) than the primary. A primary database is throttled due to delayed log consumption by the secondary. This is caused by the secondary database having insufficient compute capacity to keep up with the primary database''s rate of change.')
,('HADR_THROTTLE_LOG_RATE_LOG_SIZE','Internal use only.')
,('HADR_THROTTLE_LOG_RATE_SEEDING','Internal use only.')
,('HADR_THROTTLE_LOG_RATE_SEND_RECV_QUEUE_SIZE','Internal use only.')
,('HADR_TIMER_TASK','Waiting to get the lock on the timer task object and is also used for the actual waits between times that work is being performed. For example, for a task that runs every 10 seconds, after one execution, Always On Availability Groups waits about 10 seconds to reschedule the task, and the wait is included here.')
,('HADR_TRANSPORT_DBRLIST','Waiting for access to the transport layer''s database replica list. Used for the spinlock that grants access to it.')
,('HADR_TRANSPORT_FLOW_CONTROL','Waiting when the number of outstanding unacknowledged Always On messages is over the out flow control threshold. This is on an availability replica-to-replica basis (not on a database-to-database basis).')
,('HADR_TRANSPORT_SESSION','Always On Availability Groups is waiting while changing or accessing the underlying transport state.')
,('HADR_WORK_POOL','Concurrency control wait on the Always On Availability Groups background work task object.')
,('HADR_WORK_QUEUE','Always On Availability Groups background worker thread waiting for new work to be assigned. This is an expected wait when there are ready workers waiting for new work, which is the normal state.')
,('HADR_XRF_STACK_ACCESS','Accessing (look up, add, and delete) the extended recovery fork stack for an Always On availability database.')
,('HCCO_CACHE','Internal use only.')
,('HK_RESTORE_FILEMAP','Internal use only.')
,('HKCS_PARALLEL_MIGRATION','Internal use only.')
,('HKCS_PARALLEL_RECOVERY','Internal use only.')
,('HTBUILD','Parallel batch-mode plans when synchronizing the building of the hash table on the input side of a hash join/aggregation. If waiting is excessive and cannot be reduced by tuning the query (such as adding indexes), consider adjusting the cost threshold for parallelism or lowering the degree of parallelism.')
,('HTDELETE','Parallel batch-mode plans when synchronizing at the end of a hash join/aggregation. If waiting is excessive and cannot be reduced by tuning the query (such as adding indexes), consider adjusting the cost threshold for parallelism or lowering the degree of parallelism.')
,('HTMEMO','Parallel batch-mode plans when synchronizing before scanning hash table to output matches / non-matches in hash join/aggregation. If waiting is excessive and cannot be reduced by tuning the query (such as adding indexes), consider adjusting the cost threshold for parallelism or lowering the degree of parallelism.')
,('HTREINIT','Parallel batch-mode plans when synchronizing before resetting a hash join/aggregation for the next partial join. If waiting is excessive and cannot be reduced by tuning the query (such as adding indexes), consider adjusting the cost threshold for parallelism or lowering the degree of parallelism.')
,('HTREPARTITION','Parallel batch-mode plans when synchronizing the repartitioning of the hash table on the input side of a hash join/aggregation. If waiting is excessive and cannot be reduced by tuning the query (such as adding indexes), consider adjusting the cost threshold for parallelism or lowering the degree of parallelism.')
,('HTTP_ENUMERATION','Occurs at startup to enumerate the HTTP endpoints to start HTTP.')
,('HTTP_START','Occurs when a connection is waiting for HTTP to complete initialization.')
,('HTTP_STORAGE_CONNECTION','Internal use only.')
,('IMPPROV_IOWAIT','Occurs when SQL Server waits for a bulkload I/O to finish.')
,('INSTANCE_LOG_RATE_GOVERNOR','Internal use only.')
,('INTERNAL_TESTING','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('IO_AUDIT_MUTEX','Synchronization of trace event buffers.')
,('IO_COMPLETION','Waiting for I/O operations to complete. This wait type generally represents non-data page I/Os. Data page I/O completion waits appear as PAGEIOLATCH_* waits.')
,('IO_QUEUE_LIMIT','Internal use only.')
,('IO_RETRY','Occurs when an I/O operation such as a read or a write to disk fails because of insufficient resources, and is then retried.')
,('IOAFF_RANGE_QUEUE','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('KSOURCE_WAKEUP','Used by the service control task while waiting for requests from the Service Control Manager. Long waits are expected and do not indicate a problem.')
,('KTM_ENLISTMENT','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('KTM_RECOVERY_MANAGER','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('KTM_RECOVERY_RESOLUTION','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('LATCH_DT','Waiting for a DT (destroy) latch. This does not include buffer latches or transaction mark latches. A listing of LATCH_* waits is available in sys.dm_os_latch_stats. Note that sys.dm_os_latch_stats groups LATCH_NL, LATCH_SH, LATCH_UP, LATCH_EX, and LATCH_DT waits together.')
,('LATCH_EX','Waiting for an EX (exclusive) latch. This does not include buffer latches or transaction mark latches. A listing of LATCH_* waits is available in sys.dm_os_latch_stats. Note that sys.dm_os_latch_stats groups LATCH_NL, LATCH_SH, LATCH_UP, LATCH_EX, and LATCH_DT waits together.')
,('LATCH_KP','Waiting for a KP (keep) latch. This does not include buffer latches or transaction mark latches. A listing of LATCH_* waits is available in sys.dm_os_latch_stats. Note that sys.dm_os_latch_stats groups LATCH_NL, LATCH_SH, LATCH_UP, LATCH_EX, and LATCH_DT waits together.')
,('LATCH_NL','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('LATCH_SH','Waiting for an SH (share) latch. This does not include buffer latches or transaction mark latches. A listing of LATCH_* waits is available in sys.dm_os_latch_stats. Note that sys.dm_os_latch_stats groups LATCH_NL, LATCH_SH, LATCH_UP, LATCH_EX, and LATCH_DT waits together.')
,('LATCH_UP','Waiting for an UP (update) latch. This does not include buffer latches or transaction mark latches. A listing of LATCH_* waits is available in sys.dm_os_latch_stats. Note that sys.dm_os_latch_stats groups LATCH_NL, LATCH_SH, LATCH_UP, LATCH_EX, and LATCH_DT waits together.')
,('LAZYWRITER_SLEEP','Occurs when lazy writer tasks are suspended. This is a measure of the time spent by background tasks that are waiting. Do not consider this state when you are looking for user stalls.')
,('LCK_M_BU','Waiting to acquire a Bulk Update (BU) lock.')
,('LCK_M_BU_ABORT_BLOCKERS','Waiting to acquire a Bulk Update (BU) lock with Abort Blockers. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_BU_LOW_PRIORITY','Waiting to acquire a Bulk Update (BU) lock with Low Priority. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_IS','Waiting to acquire an Intent Shared (IS) lock.')
,('LCK_M_IS_ABORT_BLOCKERS','Waiting to acquire an Intent Shared (IS) lock with Abort Blockers. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_IS_LOW_PRIORITY','Waiting to acquire an Intent Shared (IS) lock with Low Priority. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_IU','Waiting to acquire an Intent Update (IU) lock.')
,('LCK_M_IU_ABORT_BLOCKERS','Waiting to acquire an Intent Update (IU) lock with Abort Blockers. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_IU_LOW_PRIORITY','Waiting to acquire an Intent Update (IU) lock with Low Priority. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_IX','Waiting to acquire an Intent Exclusive (IX) lock.')
,('LCK_M_IX_ABORT_BLOCKERS','Waiting to acquire an Intent Exclusive (IX) lock with Abort Blockers. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_IX_LOW_PRIORITY','Waiting to acquire an Intent Exclusive (IX) lock with Low Priority. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_RS_S','Waiting to acquire a Shared lock on the current key value, and a Shared Range lock between the current and previous key.')
,('LCK_M_RS_S_ABORT_BLOCKERS','Waiting to acquire a Shared lock with Abort Blockers on the current key value, and a Shared Range lock with Abort Blockers between the current and previous key. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_RS_S_LOW_PRIORITY','Waiting to acquire a Shared lock with Low Priority on the current key value, and a Shared Range lock with Low Priority between the current and previous key. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_RS_U','Waiting to acquire an Update lock on the current key value, and an Update Range lock between the current and previous key.')
,('LCK_M_RS_U_ABORT_BLOCKERS','Waiting to acquire an Update lock with Abort Blockers on the current key value, and an Update Range lock with Abort Blockers between the current and previous key. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_RS_U_LOW_PRIORITY','Waiting to acquire an Update lock with Low Priority on the current key value, and an Update Range lock with Low Priority between the current and previous key. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_RX_S','Waiting to acquire a Shared lock on the current key value, and an Exclusive Range lock between the current and previous key.')
,('LCK_M_RX_S_ABORT_BLOCKERS','Waiting to acquire a Shared lock with Abort Blockers on the current key value, and an Exclusive Range with Abort Blockers lock between the current and previous key. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_RX_S_LOW_PRIORITY','Waiting to acquire a Shared lock with Low Priority on the current key value, and an Exclusive Range with Low Priority lock between the current and previous key. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_RX_U','Waiting to acquire an Update lock on the current key value, and an Exclusive range lock between the current and previous key.')
,('LCK_M_RX_U_ABORT_BLOCKERS','Waiting to acquire an Update lock with Abort Blockers on the current key value, and an Exclusive range lock with Abort Blockers between the current and previous key. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_RX_U_LOW_PRIORITY','Waiting to acquire an Update lock with Low Priority on the current key value, and an Exclusive range lock with Low Priority between the current and previous key. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_RX_X','Waiting to acquire an Exclusive lock on the current key value, and an Exclusive Range lock between the current and previous key.')
,('LCK_M_RX_X_ABORT_BLOCKERS','Waiting to acquire an Exclusive lock with Abort Blockers on the current key value, and an Exclusive Range lock with Abort Blockers between the current and previous key. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_RX_X_LOW_PRIORITY','Waiting to acquire an Exclusive lock with Low Priority on the current key value, and an Exclusive Range lock with Low Priority between the current and previous key. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_S','Waiting to acquire a Shared lock.')
,('LCK_M_S_ABORT_BLOCKERS','Waiting to acquire a Shared lock with Abort Blockers. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_S_LOW_PRIORITY','Waiting to acquire a Shared lock with Low Priority. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_SCH_M','Waiting to acquire a Schema Modify lock.')
,('LCK_M_SCH_M_ABORT_BLOCKERS','Waiting to acquire a Schema Modify lock with Abort Blockers. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_SCH_M_LOW_PRIORITY','Waiting to acquire a Schema Modify lock with Low Priority. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_SCH_S','Waiting to acquire a Schema Share lock.')
,('LCK_M_SCH_S_ABORT_BLOCKERS','Waiting to acquire a Schema Share lock with Abort Blockers. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_SCH_S_LOW_PRIORITY','Waiting to acquire a Schema Share lock with Low Priority. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_SIU','Waiting to acquire a Shared With Intent Update lock.')
,('LCK_M_SIU_ABORT_BLOCKERS','Waiting to acquire a Shared With Intent Update lock with Abort Blockers. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_SIU_LOW_PRIORITY','Waiting to acquire a Shared With Intent Update lock with Low Priority. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_SIX','Waiting to acquire a Shared With Intent Exclusive lock.')
,('LCK_M_SIX_ABORT_BLOCKERS','Waiting to acquire a Shared With Intent Exclusive lock with Abort Blockers. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_SIX_LOW_PRIORITY','Waiting to acquire a Shared With Intent Exclusive lock with Low Priority. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_U','Waiting to acquire an Update lock.')
,('LCK_M_U_ABORT_BLOCKERS','Waiting to acquire an Update lock with Abort Blockers. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_U_LOW_PRIORITY','Waiting to acquire an Update lock with Low Priority. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_UIX','Waiting to acquire an Update With Intent Exclusive lock.')
,('LCK_M_UIX_ABORT_BLOCKERS','Waiting to acquire an Update With Intent Exclusive lock with Abort Blockers. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_UIX_LOW_PRIORITY','Waiting to acquire an Update With Intent Exclusive lock with Low Priority. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_X','Waiting to acquire an Exclusive lock.')
,('LCK_M_X_ABORT_BLOCKERS','Waiting to acquire an Exclusive lock with Abort Blockers. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LCK_M_X_LOW_PRIORITY','Waiting to acquire an Exclusive lock with Low Priority. (Related to the low priority wait option of ALTER TABLE and ALTER INDEX.),')
,('LOG_POOL_SCAN','Internal use only.')
,('LOG_RATE_GOVERNOR','Internal use only.')
,('LOGBUFFER','Waiting for space in the log buffer to store a log record. Consistently high values may indicate that the log devices cannot keep up with the amount of log being generated by the server.')
,('LOGCAPTURE_LOGPOOLTRUNCPOINT','Internal use only.')
,('LOGGENERATION','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('LOGMGR','Waiting for any outstanding log I/Os to finish before shutting down the log while closing the database.')
,('LOGMGR_FLUSH','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('LOGMGR_PMM_LOG','Internal use only.')
,('LOGMGR_QUEUE','Occurs while the log writer task waits for work requests.')
,('LOGMGR_RESERVE_APPEND','Waiting to see whether log truncation frees up log space to enable the task to write a new log record. Consider increasing the size of the log file(s) for the affected database to reduce this wait.')
,('LOGPOOL_CACHESIZE','Internal use only.')
,('LOGPOOL_CONSUMER','Internal use only.')
,('LOGPOOL_CONSUMERSET','Internal use only.')
,('LOGPOOL_FREEPOOLS','Internal use only.')
,('LOGPOOL_MGRSET','Internal use only.')
,('LOGPOOL_REPLACEMENTSET','Internal use only.')
,('LOGPOOLREFCOUNTEDOBJECT_REFDONE','Internal use only.')
,('LOWFAIL_MEMMGR_QUEUE','Waiting for memory to be available for use.')
,('MD_AGENT_YIELD','Internal use only.')
,('MD_LAZYCACHE_RWLOCK','Internal use only.')
,('MEMORY_ALLOCATION_EXT','Occurs while allocating memory from either the internal SQL Server memory pool or the operation system.')
,('MEMORY_GRANT_UPDATE','Internal use only.')
,('METADATA_LAZYCACHE_RWLOCK','Internal use only.')
,('MIGRATIONBUFFER','Internal use only.')
,('MISCELLANEOUS','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('MSQL_DQ','Waiting for a distributed query operation to finish. This is used to detect potential Multiple Active Result Set (MARS) application deadlocks. The wait ends when the distributed query call finishes.')
,('MSQL_XACT_MGR_MUTEX','Waiting to obtain ownership of the session transaction manager to perform a session level transaction operation.')
,('MSQL_XACT_MUTEX','Synchronization of transaction usage. A request must acquire the mutex before it can use the transaction.')
,('MSQL_XP','Waiting for an extended stored procedure to end. SQL Server uses this wait state to detect potential MARS application deadlocks. The wait stops when the extended stored procedure call ends.')
,('MSSEARCH','Occurs during Full-Text Search calls. This wait ends when the full-text operation completes. It does not indicate contention, but rather the duration of full-text operations.')
,('NET_WAITFOR_PACKET','Occurs when a connection is waiting for a network packet during a network read.')
,('NETWORKSXMLMGRLOAD','Internal use only.')
,('NODE_CACHE_MUTEX','Internal use only.')
,('OLEDB','Occurs when SQL Server calls the SQL Server Native Client OLE DB Provider. This wait type is not used for synchronization. Instead, it indicates the duration of calls to the OLE DB provider.')
,('ONDEMAND_TASK_QUEUE','Occurs while a background task waits for high priority system task requests. Long wait times indicate that there have been no high priority requests to process, and should not cause concern.')
,('PAGEIOLATCH_DT','Waiting on a latch in Destroy mode for a buffer that is in an I/O request. Long waits may indicate problems with the disk subsystem.')
,('PAGEIOLATCH_EX','Waiting on a latch in Exclusive mode for a buffer that is in an I/O request. Long waits may indicate problems with the disk subsystem.')
,('PAGEIOLATCH_KP','Waiting on a latch in Keep mode for a buffer that is in an I/O request.Long waits may indicate problems with the disk subsystem.')
,('PAGEIOLATCH_NL','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('PAGEIOLATCH_SH','Waiting on a latch in Shared mode for a buffer that is in an I/O request. Long waits may indicate problems with the disk subsystem.')
,('PAGEIOLATCH_UP','Waiting on a latch in Update mode for a buffer that is in an I/O request. Long waits may indicate problems with the disk subsystem.')
,('PAGELATCH_DT','Waiting on a latch in Destroy mode for a buffer that is not in an I/O request.')
,('PAGELATCH_EX','Waiting on a latch in Exclusive mode for a buffer that is not in an I/O request.')
,('PAGELATCH_KP','Waiting on a latch in Keep mode for a buffer that is not in an I/O request.')
,('PAGELATCH_NL','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('PAGELATCH_SH','Waiting on a latch in Shared mode for a buffer that is not in an I/O request.')
,('PAGELATCH_UP','Waiting on a latch in Update mode for a buffer that is not in an I/O request.')
,('PARALLEL_BACKUP_QUEUE','Occurs when serializing output produced by RESTORE HEADERONLY, RESTORE FILELISTONLY, or RESTORE LABELONLY.')
,('PARALLEL_REDO_DRAIN_WORKER','Internal use only.')
,('PARALLEL_REDO_FLOW_CONTROL','Internal use only.')
,('PARALLEL_REDO_LOG_CACHE','Internal use only.')
,('PARALLEL_REDO_TRAN_LIST','Internal use only.')
,('PARALLEL_REDO_TRAN_TURN','Internal use only.')
,('PARALLEL_REDO_WORKER_SYNC','Internal use only.')
,('PARALLEL_REDO_WORKER_WAIT_WORK','Internal use only.')
,('PERFORMANCE_COUNTERS_RWLOCK','Internal use only.')
,('PHYSICAL_SEEDING_DMV','Internal use only.')
,('POOL_LOG_RATE_GOVERNOR','Internal use only.')
,('PREEMPTIVE_ABR','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('PREEMPTIVE_AUDIT_ACCESS_EVENTLOG','Occurs when the SQL Server Operating System (SQLOS) scheduler switches to preemptive mode to write an audit event to the Windows event log.')
,('PREEMPTIVE_AUDIT_ACCESS_SECLOG','SQLOS scheduler switches to preemptive mode to write an audit event to the Windows Security log.')
,('PREEMPTIVE_CLOSEBACKUPMEDIA','SQLOS scheduler switches to preemptive mode to close backup media.')
,('PREEMPTIVE_CLOSEBACKUPTAPE','SQLOS scheduler switches to preemptive mode to close a tape backup device.')
,('PREEMPTIVE_CLOSEBACKUPVDIDEVICE','SQLOS scheduler switches to preemptive mode to close a virtual backup device.')
,('PREEMPTIVE_CLUSAPI_CLUSTERRESOURCECONTROL','SQLOS scheduler switches to preemptive mode to perform Windows failover cluster operations.')
,('PREEMPTIVE_COM_COCREATEINSTANCE','SQLOS scheduler switches to preemptive mode to create a COM object.')
,('PREEMPTIVE_COM_COGETCLASSOBJECT','Internal use only.')
,('PREEMPTIVE_COM_CREATEACCESSOR','Internal use only.')
,('PREEMPTIVE_COM_DELETEROWS','Internal use only.')
,('PREEMPTIVE_COM_GETCOMMANDTEXT','Internal use only.')
,('PREEMPTIVE_COM_GETDATA','Internal use only.')
,('PREEMPTIVE_COM_GETNEXTROWS','Internal use only.')
,('PREEMPTIVE_COM_GETRESULT','Internal use only.')
,('PREEMPTIVE_COM_GETROWSBYBOOKMARK','Internal use only.')
,('PREEMPTIVE_COM_LBFLUSH','Internal use only.')
,('PREEMPTIVE_COM_LBLOCKREGION','Internal use only.')
,('PREEMPTIVE_COM_LBREADAT','Internal use only.')
,('PREEMPTIVE_COM_LBSETSIZE','Internal use only.')
,('PREEMPTIVE_COM_LBSTAT','Internal use only.')
,('PREEMPTIVE_COM_LBUNLOCKREGION','Internal use only.')
,('PREEMPTIVE_COM_LBWRITEAT','Internal use only.')
,('PREEMPTIVE_COM_QUERYINTERFACE','Internal use only.')
,('PREEMPTIVE_COM_RELEASE','Internal use only.')
,('PREEMPTIVE_COM_RELEASEACCESSOR','Internal use only.')
,('PREEMPTIVE_COM_RELEASEROWS','Internal use only.')
,('PREEMPTIVE_COM_RELEASESESSION','Internal use only.')
,('PREEMPTIVE_COM_RESTARTPOSITION','Internal use only.')
,('PREEMPTIVE_COM_SEQSTRMREAD','Internal use only.')
,('PREEMPTIVE_COM_SEQSTRMREADANDWRITE','Internal use only.')
,('PREEMPTIVE_COM_SETDATAFAILURE','Internal use only.')
,('PREEMPTIVE_COM_SETPARAMETERINFO','Internal use only.')
,('PREEMPTIVE_COM_SETPARAMETERPROPERTIES','Internal use only.')
,('PREEMPTIVE_COM_STRMLOCKREGION','Internal use only.')
,('PREEMPTIVE_COM_STRMSEEKANDREAD','Internal use only.')
,('PREEMPTIVE_COM_STRMSEEKANDWRITE','Internal use only.')
,('PREEMPTIVE_COM_STRMSETSIZE','Internal use only.')
,('PREEMPTIVE_COM_STRMSTAT','Internal use only.')
,('PREEMPTIVE_COM_STRMUNLOCKREGION','Internal use only.')
,('PREEMPTIVE_CONSOLEWRITE','Internal use only.')
,('PREEMPTIVE_CREATEPARAM','Internal use only.')
,('PREEMPTIVE_DEBUG','Internal use only.')
,('PREEMPTIVE_DFSADDLINK','Internal use only.')
,('PREEMPTIVE_DFSLINKEXISTCHECK','Internal use only.')
,('PREEMPTIVE_DFSLINKHEALTHCHECK','Internal use only.')
,('PREEMPTIVE_DFSREMOVELINK','Internal use only.')
,('PREEMPTIVE_DFSREMOVEROOT','Internal use only.')
,('PREEMPTIVE_DFSROOTFOLDERCHECK','Internal use only.')
,('PREEMPTIVE_DFSROOTINIT','Internal use only.')
,('PREEMPTIVE_DFSROOTSHARECHECK','Internal use only.')
,('PREEMPTIVE_DTC_ABORT','Internal use only.')
,('PREEMPTIVE_DTC_ABORTREQUESTDONE','Internal use only.')
,('PREEMPTIVE_DTC_BEGINTRANSACTION','Internal use only.')
,('PREEMPTIVE_DTC_COMMITREQUESTDONE','Internal use only.')
,('PREEMPTIVE_DTC_ENLIST','Internal use only.')
,('PREEMPTIVE_DTC_PREPAREREQUESTDONE','Internal use only.')
,('PREEMPTIVE_FILESIZEGET','Internal use only.')
,('PREEMPTIVE_FSAOLEDB_ABORTTRANSACTION','Internal use only.')
,('PREEMPTIVE_FSAOLEDB_COMMITTRANSACTION','Internal use only.')
,('PREEMPTIVE_FSAOLEDB_STARTTRANSACTION','Internal use only.')
,('PREEMPTIVE_FSRECOVER_UNCONDITIONALUNDO','Internal use only.')
,('PREEMPTIVE_GETRMINFO','Internal use only.')
,('PREEMPTIVE_HADR_LEASE_MECHANISM','Always On Availability Groups lease manager scheduling for Microsoft Support diagnostics.')
,('PREEMPTIVE_HTTP_EVENT_WAIT','Internal use only.')
,('PREEMPTIVE_HTTP_REQUEST','Internal use only.')
,('PREEMPTIVE_LOCKMONITOR','Internal use only.')
,('PREEMPTIVE_MSS_RELEASE','Internal use only.')
,('PREEMPTIVE_ODBCOPS','Internal use only.')
,('PREEMPTIVE_OLE_UNINIT','Internal use only.')
,('PREEMPTIVE_OLEDB_ABORTORCOMMITTRAN','Internal use only.')
,('PREEMPTIVE_OLEDB_ABORTTRAN','Internal use only.')
,('PREEMPTIVE_OLEDB_GETDATASOURCE','Internal use only.')
,('PREEMPTIVE_OLEDB_GETLITERALINFO','Internal use only.')
,('PREEMPTIVE_OLEDB_GETPROPERTIES','Internal use only.')
,('PREEMPTIVE_OLEDB_GETPROPERTYINFO','Internal use only.')
,('PREEMPTIVE_OLEDB_GETSCHEMALOCK','Internal use only.')
,('PREEMPTIVE_OLEDB_JOINTRANSACTION','Internal use only.')
,('PREEMPTIVE_OLEDB_RELEASE','Internal use only.')
,('PREEMPTIVE_OLEDB_SETPROPERTIES','Internal use only.')
,('PREEMPTIVE_OLEDBOPS','Internal use only.')
,('PREEMPTIVE_OS_ACCEPTSECURITYCONTEXT','Internal use only.')
,('PREEMPTIVE_OS_ACQUIRECREDENTIALSHANDLE','Internal use only.')
,('PREEMPTIVE_OS_AUTHENTICATIONOPS','Internal use only.')
,('PREEMPTIVE_OS_AUTHORIZATIONOPS','Internal use only.')
,('PREEMPTIVE_OS_AUTHZGETINFORMATIONFROMCONTEXT','Internal use only.')
,('PREEMPTIVE_OS_AUTHZINITIALIZECONTEXTFROMSID','Internal use only.')
,('PREEMPTIVE_OS_AUTHZINITIALIZERESOURCEMANAGER','Internal use only.')
,('PREEMPTIVE_OS_BACKUPREAD','Internal use only.')
,('PREEMPTIVE_OS_CLOSEHANDLE','Internal use only.')
,('PREEMPTIVE_OS_CLUSTEROPS','Internal use only.')
,('PREEMPTIVE_OS_COMOPS','Internal use only.')
,('PREEMPTIVE_OS_COMPLETEAUTHTOKEN','Internal use only.')
,('PREEMPTIVE_OS_COPYFILE','Internal use only.')
,('PREEMPTIVE_OS_CREATEDIRECTORY','Internal use only.')
,('PREEMPTIVE_OS_CREATEFILE','Internal use only.')
,('PREEMPTIVE_OS_CRYPTACQUIRECONTEXT','Internal use only.')
,('PREEMPTIVE_OS_CRYPTIMPORTKEY','Internal use only.')
,('PREEMPTIVE_OS_CRYPTOPS','Internal use only.')
,('PREEMPTIVE_OS_DECRYPTMESSAGE','Internal use only.')
,('PREEMPTIVE_OS_DELETEFILE','Internal use only.')
,('PREEMPTIVE_OS_DELETESECURITYCONTEXT','Internal use only.')
,('PREEMPTIVE_OS_DEVICEIOCONTROL','Internal use only.')
,('PREEMPTIVE_OS_DEVICEOPS','Internal use only.')
,('PREEMPTIVE_OS_DIRSVC_NETWORKOPS','Internal use only.')
,('PREEMPTIVE_OS_DISCONNECTNAMEDPIPE','Internal use only.')
,('PREEMPTIVE_OS_DOMAINSERVICESOPS','Internal use only.')
,('PREEMPTIVE_OS_DSGETDCNAME','Internal use only.')
,('PREEMPTIVE_OS_DTCOPS','Internal use only.')
,('PREEMPTIVE_OS_ENCRYPTMESSAGE','Internal use only.')
,('PREEMPTIVE_OS_FILEOPS','Internal use only.')
,('PREEMPTIVE_OS_FINDFILE','Internal use only.')
,('PREEMPTIVE_OS_FLUSHFILEBUFFERS','Internal use only.')
,('PREEMPTIVE_OS_FORMATMESSAGE','Internal use only.')
,('PREEMPTIVE_OS_FREECREDENTIALSHANDLE','Internal use only.')
,('PREEMPTIVE_OS_FREELIBRARY','Internal use only.')
,('PREEMPTIVE_OS_GENERICOPS','Internal use only.')
,('PREEMPTIVE_OS_GETADDRINFO','Internal use only.')
,('PREEMPTIVE_OS_GETCOMPRESSEDFILESIZE','Internal use only.')
,('PREEMPTIVE_OS_GETDISKFREESPACE','Internal use only.')
,('PREEMPTIVE_OS_GETFILEATTRIBUTES','Internal use only.')
,('PREEMPTIVE_OS_GETFILESIZE','Internal use only.')
,('PREEMPTIVE_OS_GETFINALFILEPATHBYHANDLE','Internal use only.')
,('PREEMPTIVE_OS_GETLONGPATHNAME','Internal use only.')
,('PREEMPTIVE_OS_GETPROCADDRESS','Internal use only.')
,('PREEMPTIVE_OS_GETVOLUMENAMEFORVOLUMEMOUNTPOINT','Internal use only.')
,('PREEMPTIVE_OS_GETVOLUMEPATHNAME','Internal use only.')
,('PREEMPTIVE_OS_INITIALIZESECURITYCONTEXT','Internal use only.')
,('PREEMPTIVE_OS_LIBRARYOPS','Internal use only.')
,('PREEMPTIVE_OS_LOADLIBRARY','Internal use only.')
,('PREEMPTIVE_OS_LOGONUSER','Internal use only.')
,('PREEMPTIVE_OS_LOOKUPACCOUNTSID','Internal use only.')
,('PREEMPTIVE_OS_MESSAGEQUEUEOPS','Internal use only.')
,('PREEMPTIVE_OS_MOVEFILE','Internal use only.')
,('PREEMPTIVE_OS_NETGROUPGETUSERS','Internal use only.')
,('PREEMPTIVE_OS_NETLOCALGROUPGETMEMBERS','Internal use only.')
,('PREEMPTIVE_OS_NETUSERGETGROUPS','Internal use only.')
,('PREEMPTIVE_OS_NETUSERGETLOCALGROUPS','Internal use only.')
,('PREEMPTIVE_OS_NETUSERMODALSGET','Internal use only.')
,('PREEMPTIVE_OS_NETVALIDATEPASSWORDPOLICY','Internal use only.')
,('PREEMPTIVE_OS_NETVALIDATEPASSWORDPOLICYFREE','Internal use only.')
,('PREEMPTIVE_OS_OPENDIRECTORY','Internal use only.')
,('PREEMPTIVE_OS_PDH_WMI_INIT','Internal use only.')
,('PREEMPTIVE_OS_PIPEOPS','Internal use only.')
,('PREEMPTIVE_OS_PROCESSOPS','Internal use only.')
,('PREEMPTIVE_OS_QUERYCONTEXTATTRIBUTES','Internal use only.')
,('PREEMPTIVE_OS_QUERYREGISTRY','Internal use only.')
,('PREEMPTIVE_OS_QUERYSECURITYCONTEXTTOKEN','Internal use only.')
,('PREEMPTIVE_OS_REMOVEDIRECTORY','Internal use only.')
,('PREEMPTIVE_OS_REPORTEVENT','Internal use only.')
,('PREEMPTIVE_OS_REVERTTOSELF','Internal use only.')
,('PREEMPTIVE_OS_RSFXDEVICEOPS','Internal use only.')
,('PREEMPTIVE_OS_SECURITYOPS','Internal use only.')
,('PREEMPTIVE_OS_SERVICEOPS','Internal use only.')
,('PREEMPTIVE_OS_SETENDOFFILE','Internal use only.')
,('PREEMPTIVE_OS_SETFILEPOINTER','Internal use only.')
,('PREEMPTIVE_OS_SETFILEVALIDDATA','Internal use only.')
,('PREEMPTIVE_OS_SETNAMEDSECURITYINFO','Internal use only.')
,('PREEMPTIVE_OS_SQLCLROPS','Internal use only.')
,('PREEMPTIVE_OS_SQMLAUNCH','Internal use only.')
,('PREEMPTIVE_OS_VERIFYSIGNATURE','Internal use only.')
,('PREEMPTIVE_OS_VERIFYTRUST','Internal use only.')
,('PREEMPTIVE_OS_VSSOPS','Internal use only.')
,('PREEMPTIVE_OS_WAITFORSINGLEOBJECT','Internal use only.')
,('PREEMPTIVE_OS_WINSOCKOPS','Internal use only.')
,('PREEMPTIVE_OS_WRITEFILE','Internal use only.')
,('PREEMPTIVE_OS_WRITEFILEGATHER','Internal use only. Waiting for the OS to complete write operations. Occurs when calling the Windows WriteFileGather function.')
,('PREEMPTIVE_OS_WSASETLASTERROR','Internal use only.')
,('PREEMPTIVE_REENLIST','Internal use only.')
,('PREEMPTIVE_RESIZELOG','Internal use only.')
,('PREEMPTIVE_ROLLFORWARDREDO','Internal use only.')
,('PREEMPTIVE_ROLLFORWARDUNDO','Internal use only.')
,('PREEMPTIVE_SB_STOPENDPOINT','Internal use only.')
,('PREEMPTIVE_SERVER_STARTUP','Internal use only.')
,('PREEMPTIVE_SETRMINFO','Internal use only.')
,('PREEMPTIVE_SHAREDMEM_GETDATA','Internal use only.')
,('PREEMPTIVE_SNIOPEN','Internal use only.')
,('PREEMPTIVE_SOSHOST','Internal use only.')
,('PREEMPTIVE_SOSTESTING','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('PREEMPTIVE_SP_SERVER_DIAGNOSTICS','Internal use only.')
,('PREEMPTIVE_STARTRM','Internal use only.')
,('PREEMPTIVE_STREAMFCB_CHECKPOINT','Internal use only.')
,('PREEMPTIVE_STREAMFCB_RECOVER','Internal use only.')
,('PREEMPTIVE_STRESSDRIVER','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('PREEMPTIVE_TESTING','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('PREEMPTIVE_TRANSIMPORT','Internal use only.')
,('PREEMPTIVE_UNMARSHALPROPAGATIONTOKEN','Internal use only.')
,('PREEMPTIVE_VSS_CREATESNAPSHOT','Internal use only.')
,('PREEMPTIVE_VSS_CREATEVOLUMESNAPSHOT','Internal use only.')
,('PREEMPTIVE_XE_CALLBACKEXECUTE','Internal use only.')
,('PREEMPTIVE_XE_CX_FILE_OPEN','Internal use only.')
,('PREEMPTIVE_XE_CX_HTTP_CALL','Internal use only.')
,('PREEMPTIVE_XE_DISPATCHER','Internal use only.')
,('PREEMPTIVE_XE_ENGINEINIT','Internal use only.')
,('PREEMPTIVE_XE_GETTARGETSTATE','Internal use only.')
,('PREEMPTIVE_XE_SESSIONCOMMIT','Internal use only.')
,('PREEMPTIVE_XE_TARGETFINALIZE','Internal use only.')
,('PREEMPTIVE_XE_TARGETINIT','Internal use only.')
,('PREEMPTIVE_XE_TIMERRUN','Internal use only.')
,('PREEMPTIVE_XETESTING','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('PRINT_ROLLBACK_PROGRESS','Used to wait while user processes are ended in a database that has been transitioned by using the ALTER DATABASE termination clause. For more information, see ALTER DATABASE (Transact-SQL).')
,('PRU_ROLLBACK_DEFERRED','Internal use only.')
,('PWAIT_ALL_COMPONENTS_INITIALIZED','Internal use only.')
,('PWAIT_COOP_SCAN','Internal use only.')
,('PWAIT_DIRECTLOGCONSUMER_GETNEXT','Internal use only.')
,('PWAIT_EVENT_SESSION_INIT_MUTEX','Internal use only.')
,('PWAIT_FABRIC_REPLICA_CONTROLLER_DATA_LOSS','Internal use only.')
,('PWAIT_HADR_ACTION_COMPLETED','Internal use only.')
,('PWAIT_HADR_CHANGE_NOTIFIER_TERMINATION_SYNC','Occurs when a background task is waiting for the termination of the background task that receives (via polling) Windows Server Failover Clustering notifications.')
,('PWAIT_HADR_CLUSTER_INTEGRATION','An append, replace, and/or remove operation is waiting to grab a write lock on an Always On internal list (such as a list of networks, network addresses, or availability group listeners). Internal use only,')
,('PWAIT_HADR_FAILOVER_COMPLETED','Internal use only.')
,('PWAIT_HADR_JOIN','Internal use only.')
,('PWAIT_HADR_OFFLINE_COMPLETED','An Always On drop availability group operation is waiting for the target availability group to go offline before destroying Windows Server Failover Clustering objects.')
,('PWAIT_HADR_ONLINE_COMPLETED','An Always On create or failover availability group operation is waiting for the target availability group to come online.')
,('PWAIT_HADR_POST_ONLINE_COMPLETED','An Always On drop availability group operation is waiting for the termination of any background task that was scheduled as part of a previous command. For example, there may be a background task that is transitioning availability databases to the primary role. The DROP AVAILABILITY GROUP DDL must wait for this background task to terminate in order to avoid race conditions.')
,('PWAIT_HADR_SERVER_READY_CONNECTIONS','Internal use only.')
,('PWAIT_HADR_WORKITEM_COMPLETED','Internal wait by a thread waiting for an async work task to complete. This is an expected wait and is for CSS use.')
,('PWAIT_HADRSIM','Internal use only.')
,('PWAIT_LOG_CONSOLIDATION_IO','Internal use only.')
,('PWAIT_LOG_CONSOLIDATION_POLL','Internal use only.')
,('PWAIT_MD_LOGIN_STATS','Internal synchronization in metadata on login stats.')
,('PWAIT_MD_RELATION_CACHE','Internal synchronization in metadata on table or index.')
,('PWAIT_MD_SERVER_CACHE','Internal synchronization in metadata on linked servers.')
,('PWAIT_MD_UPGRADE_CONFIG','Internal synchronization in upgrading server wide configurations.')
,('PWAIT_PREEMPTIVE_APP_USAGE_TIMER','Internal use only.')
,('PWAIT_PREEMPTIVE_AUDIT_ACCESS_WINDOWSLOG','Internal use only.')
,('PWAIT_QRY_BPMEMORY','Internal use only.')
,('PWAIT_REPLICA_ONLINE_INIT_MUTEX','Internal use only.')
,('PWAIT_RESOURCE_SEMAPHORE_FT_PARALLEL_QUERY_SYNC','Internal use only.')
,('PWAIT_SBS_FILE_OPERATION','Internal use only.')
,('PWAIT_XTP_FSSTORAGE_MAINTENANCE','Internal use only.')
,('PWAIT_XTP_HOST_STORAGE_WAIT','Internal use only.')
,('QDS_ASYNC_CHECK_CONSISTENCY_TASK','Internal use only.')
,('QDS_ASYNC_PERSIST_TASK','Internal use only.')
,('QDS_ASYNC_PERSIST_TASK_START','Internal use only.')
,('QDS_ASYNC_QUEUE','Internal use only.')
,('QDS_BCKG_TASK','Internal use only.')
,('QDS_BLOOM_FILTER','Internal use only.')
,('QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP','Internal use only.')
,('QDS_CTXS','Internal use only.')
,('QDS_DB_DISK','Internal use only.')
,('QDS_DYN_VECTOR','Internal use only.')
,('QDS_EXCLUSIVE_ACCESS','Internal use only.')
,('QDS_HOST_INIT','Internal use only.')
,('QDS_LOADDB','Internal use only.')
,('QDS_PERSIST_TASK_MAIN_LOOP_SLEEP','Internal use only.')
,('QDS_QDS_CAPTURE_INIT','Internal use only.')
,('QDS_SHUTDOWN_QUEUE','Internal use only.')
,('QDS_STMT','Internal use only.')
,('QDS_STMT_DISK','Internal use only.')
,('QDS_TASK_SHUTDOWN','Internal use only.')
,('QDS_TASK_START','Internal use only.')
,('QE_WARN_LIST_SYNC','Internal use only.')
,('QPJOB_KILL','Indicates that an asynchronous automatic statistics update was canceled by a call to KILL as the update was starting to run. The terminating thread is suspended, waiting for it to start listening for KILL commands. A good value is less than one second.')
,('QPJOB_WAITFOR_ABORT','Indicates that an asynchronous automatic statistics update was canceled by a call to KILL when it was running. The update has now completed but is suspended until the terminating thread message coordination is complete. This is an ordinary but rare state, and should be very short. A good value is less than one second.')
,('QRY_MEM_GRANT_INFO_MUTEX','Occurs when Query Execution memory management tries to control access to static grant information list. This state lists information about the current granted and waiting memory requests. This state is a simple access control state. There should never be a long wait on this state. If this mutex is not released, all new memory-using queries will stop responding.')
,('QRY_PARALLEL_THREAD_MUTEX','Internal use only.')
,('QRY_PROFILE_LIST_MUTEX','Internal use only.')
,('QUERY_ERRHDL_SERVICE_DONE','Identified for informational purposes only. Not supported.')
,('QUERY_WAIT_ERRHDL_SERVICE','Identified for informational purposes only. Not supported.')
,('QUERY_EXECUTION_INDEX_SORT_EVENT_OPEN','Occurs in certain cases when offline create index build is run in parallel, and the different worker threads that are sorting synchronize access to the sort files.')
,('QUERY_NOTIFICATION_MGR_MUTEX','Synchronization of the garbage collection queue in the Query Notification Manager.')
,('QUERY_NOTIFICATION_SUBSCRIPTION_MUTEX','Occurs during state synchronization for transactions in Query Notifications.')
,('QUERY_NOTIFICATION_TABLE_MGR_MUTEX','Internal synchronization within the Query Notification Manager.')
,('QUERY_NOTIFICATION_UNITTEST_MUTEX','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('QUERY_OPTIMIZER_PRINT_MUTEX','Synchronization of query optimizer diagnostic output production. This wait type only occurs if diagnostic settings have been enabled under direction of Microsoft Product Support.')
,('QUERY_TASK_ENQUEUE_MUTEX','Internal use only.')
,('QUERY_TRACEOUT','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('RBIO_WAIT_VLF','Internal use only.')
,('RBIO_RG_STORAGE','Hyperscale database compute node is being throttled due to delayed log consumption at the page server(s).')
,('RBIO_RG_DESTAGE','Hyperscale database compute node is being throttled due to delayed log consumption by the long term log storage.')
,('RBIO_RG_REPLICA','Hyperscale database compute node is being throttled due to delayed log consumption by the readable secondary replica node(s).')
,('RBIO_RG_LOCALDESTAGE','Hyperscale database compute node is being throttled due to delayed log consumption by the log service.')
,('RECOVER_CHANGEDB','Synchronization of database status in warm standby database.')
,('RECOVERY_MGR_LOCK','Internal use only.')
,('REDO_THREAD_PENDING_WORK','Internal use only.')
,('REDO_THREAD_SYNC','Internal use only.')
,('REMOTE_BLOCK_IO','Internal use only.')
,('REMOTE_DATA_ARCHIVE_MIGRATION_DMV','Internal use only.')
,('REMOTE_DATA_ARCHIVE_SCHEMA_DMV','Internal use only.')
,('REMOTE_DATA_ARCHIVE_SCHEMA_TASK_QUEUE','Internal use only.')
,('REPL_CACHE_ACCESS','Synchronization on a replication article cache. During these waits, the replication log reader stalls, and data definition language (DDL) statements on a published table are blocked.')
,('REPL_HISTORYCACHE_ACCESS','Internal use only.')
,('REPL_SCHEMA_ACCESS','Synchronization of replication schema version information. This state exists when DDL statements are executed on the replicated object, and when the log reader builds or consumes versioned schema based on DDL occurrence. Contention can be seen on this wait type if you have many published databases on a single publisher with transactional replication and the published databases are very active.')
,('REPL_TRANFSINFO_ACCESS','Internal use only.')
,('REPL_TRANHASHTABLE_ACCESS','Internal use only.')
,('REPL_TRANTEXTINFO_ACCESS','Internal use only.')
,('REPLICA_WRITES','Occurs while a task waits for completion of page writes to database snapshots or DBCC replicas.')
,('REQUEST_DISPENSER_PAUSE','Waiting for all outstanding I/O to complete, so that I/O to a file can be frozen for snapshot backup.')
,('REQUEST_FOR_DEADLOCK_SEARCH','Occurs while the deadlock monitor waits to start the next deadlock search. This wait is expected between deadlock detections, and lengthy total waiting time on this resource does not indicate a problem.')
,('RESERVED_MEMORY_ALLOCATION_EXT','Internal use only.')
,('RESMGR_THROTTLED','Occurs when a new request comes in and is throttled based on the GROUP_MAX_REQUESTS setting.')
,('RESOURCE_GOVERNOR_IDLE','Internal use only.')
,('RESOURCE_QUEUE','Synchronization of various internal resource queues.')
,('RESOURCE_SEMAPHORE','Occurs when a query memory request cannot be granted immediately due to other concurrent queries. High waits and wait times may indicate excessive number of concurrent queries, or excessive memory request amounts.')
,('RESOURCE_SEMAPHORE_MUTEX','Occurs while a query waits for its request for a thread reservation to be fulfilled. It also occurs when synchronizing query compile and memory grant requests.')
,('RESOURCE_SEMAPHORE_QUERY_COMPILE','Occurs when the number of concurrent query compilations reaches a throttling limit. High waits and wait times may indicate excessive compilations, recompiles, or uncachable plans.')
,('RESOURCE_SEMAPHORE_SMALL_QUERY','Occurs when memory request by a small query cannot be granted immediately due to other concurrent queries. Wait time should not exceed more than a few seconds, because the server transfers the request to the main query memory pool if it fails to grant the requested memory within a few seconds. High waits may indicate an excessive number of concurrent small queries while the main memory pool is blocked by waiting queries.')
,('RESTORE_FILEHANDLECACHE_ENTRYLOCK','Internal use only.')
,('RESTORE_FILEHANDLECACHE_LOCK','Internal use only.')
,('RG_RECONFIG','Internal use only.')
,('ROWGROUP_OP_STATS','Internal use only.')
,('ROWGROUP_VERSION','Internal use only.')
,('RTDATA_LIST','Internal use only.')
,('SATELLITE_CARGO','Internal use only.')
,('SATELLITE_SERVICE_SETUP','Internal use only.')
,('SATELLITE_TASK','Internal use only.')
,('SBS_DISPATCH','Internal use only.')
,('SBS_RECEIVE_TRANSPORT','Internal use only.')
,('SBS_TRANSPORT','Internal use only.')
,('SCAN_CHAR_HASH_ARRAY_INITIALIZATION','Internal use only.')
,('SEC_DROP_TEMP_KEY','Occurs after a failed attempt to drop a temporary security key before a retry attempt.')
,('SECURITY_CNG_PROVIDER_MUTEX','Internal use only.')
,('SECURITY_CRYPTO_CONTEXT_MUTEX','Internal use only.')
,('SECURITY_DBE_STATE_MUTEX','Internal use only.')
,('SECURITY_KEYRING_RWLOCK','Internal use only.')
,('SECURITY_MUTEX','There is a wait for mutexes that control access to the global list of Extensible Key Management (EKM) cryptographic providers and the session-scoped list of EKM sessions.')
,('SECURITY_RULETABLE_MUTEX','Internal use only.')
,('SEMPLAT_DSI_BUILD','Internal use only.')
,('SEQUENCE_GENERATION','Internal use only.')
,('SEQUENTIAL_GUID','New sequential GUID is being obtained.')
,('SERVER_IDLE_CHECK','Synchronization of SQL Server instance idle status when a resource monitor is attempting to declare a SQL Server instance as idle or trying to wake up.')
,('SERVER_RECONFIGURE','Internal use only.')
,('SESSION_WAIT_STATS_CHILDREN','Internal use only.')
,('SHARED_DELTASTORE_CREATION','Internal use only.')
,('SHUTDOWN','Shutdown statement waits for active connections to exit.')
,('SLEEP_BPOOL_FLUSH','Occurs when a checkpoint is throttling the issuance of new I/Os in order to avoid flooding the disk subsystem.')
,('SLEEP_BUFFERPOOL_HELPLW','Internal use only.')
,('SLEEP_DBSTARTUP','Occurs during database startup while waiting for all databases to recover.')
,('SLEEP_DCOMSTARTUP','Occurs once at most during SQL Server instance startup while waiting for DCOM initialization to complete.')
,('SLEEP_MASTERDBREADY','Internal use only.')
,('SLEEP_MASTERMDREADY','Internal use only.')
,('SLEEP_MASTERUPGRADED','Internal use only.')
,('SLEEP_MEMORYPOOL_ALLOCATEPAGES','Internal use only.')
,('SLEEP_MSDBSTARTUP','Occurs when SQL Trace waits for the msdb database to complete startup.')
,('SLEEP_RETRY_VIRTUALALLOC','Internal use only.')
,('SLEEP_SYSTEMTASK','Occurs during the start of a background task while waiting for tempdb to complete startup.')
,('SLEEP_TASK','Task sleeps while waiting for a generic event to occur.')
,('SLEEP_TEMPDBSTARTUP','Occurs while a task waits for tempdb to complete startup.')
,('SLEEP_WORKSPACE_ALLOCATEPAGE','Internal use only.')
,('SLO_UPDATE','Internal use only.')
,('SMSYNC','Internal use only.')
,('SNI_CONN_DUP','Internal use only.')
,('SNI_CRITICAL_SECTION','Internal synchronization within SQL Server networking components.')
,('SNI_LISTENER_ACCESS','Waiting for non-uniform memory access (NUMA) nodes to update state change. Access to state change is serialized.')
,('SNI_TASK_COMPLETION','There is a wait for all tasks to finish during a NUMA node state change.')
,('SNI_WRITE_ASYNC','Internal use only.')
,('SOAP_READ','Waiting for an HTTP network read to complete.')
,('SOAP_WRITE','Waiting for an HTTP network write to complete.')
,('SOCKETDUPLICATEQUEUE_CLEANUP','Internal use only.')
,('SOS_CALLBACK_REMOVAL','Occurs while performing synchronization on a callback list in order to remove a callback. It is not expected for this counter to change after server initialization is completed.')
,('SOS_DISPATCHER_MUTEX','Internal synchronization of the dispatcher pool. This includes when the pool is being adjusted.')
,('SOS_LOCALALLOCATORLIST','Internal synchronization in the SQL Server memory manager.')
,('SOS_MEMORY_TOPLEVELBLOCKALLOCATOR','Internal use only.')
,('SOS_MEMORY_USAGE_ADJUSTMENT','Occurs when memory usage is being adjusted among pools.')
,('SOS_OBJECT_STORE_DESTROY_MUTEX','Internal synchronization in memory pools when destroying objects from the pool.')
,('SOS_PHYS_PAGE_CACHE','Accounts for the time a thread waits to acquire the mutex it must acquire before it allocates physical pages or before it returns those pages to the operating system. Waits on this type only appear if the instance of SQL Server uses AWE memory.')
,('SOS_PROCESS_AFFINITY_MUTEX','Occurs during synchronizing of access to process affinity settings.')
,('SOS_RESERVEDMEMBLOCKLIST','Internal synchronization in the SQL Server memory manager.')
,('SOS_SCHEDULER_YIELD','Task voluntarily yields the scheduler for other tasks to execute. During this wait the task is waiting for its quantum to be renewed.')
,('SOS_SMALL_PAGE_ALLOC','Occurs during the allocation and freeing of memory that is managed by some memory objects.')
,('SOS_STACKSTORE_INIT_MUTEX','Synchronization of internal store initialization.')
,('SOS_SYNC_TASK_ENQUEUE_EVENT','Task is started in a synchronous manner. Most tasks in SQL Server are started in an asynchronous manner, in which control returns to the starter immediately after the task request has been placed on the work queue.')
,('SOS_VIRTUALMEMORY_LOW','Occurs when a memory allocation waits for a resource manager to free up virtual memory.')
,('SOSHOST_EVENT','Occurs when a hosted component, such as CLR, waits on a SQL Server event synchronization object.')
,('SOSHOST_INTERNAL','Synchronization of memory manager callbacks used by hosted components, such as CLR.')
,('SOSHOST_MUTEX','Occurs when a hosted component, such as CLR, waits on a SQL Server mutex synchronization object.')
,('SOSHOST_RWLOCK','Occurs when a hosted component, such as CLR, waits on a SQL Server reader-writer synchronization object.')
,('SOSHOST_SEMAPHORE','Occurs when a hosted component, such as CLR, waits on a SQL Server semaphore synchronization object.')
,('SOSHOST_SLEEP','Occurs when a hosted task sleeps while waiting for a generic event to occur. Hosted tasks are used by hosted components such as CLR.')
,('SOSHOST_TRACELOCK','Synchronization of access to trace streams.')
,('SOSHOST_WAITFORDONE','Occurs when a hosted component, such as CLR, waits for a task to complete.')
,('SP_PREEMPTIVE_SERVER_DIAGNOSTICS_SLEEP','Internal use only.')
,('SP_SERVER_DIAGNOSTICS_BUFFER_ACCESS','Internal use only.')
,('SP_SERVER_DIAGNOSTICS_INIT_MUTEX','Internal use only.')
,('SP_SERVER_DIAGNOSTICS_SLEEP','Internal use only.')
,('SQLCLR_APPDOMAIN','Occurs while CLR waits for an application domain to complete startup.')
,('SQLCLR_ASSEMBLY','Waiting for access to the loaded assembly list in the appdomain.')
,('SQLCLR_DEADLOCK_DETECTION','CLR waits for deadlock detection to complete.')
,('SQLCLR_QUANTUM_PUNISHMENT','CLR task is throttled because it has exceeded its execution quantum. This throttling is done in order to reduce the effect of this resource-intensive task on other tasks.')
,('SQLSORT_NORMMUTEX','Internal synchronization, while initializing internal sorting structures.')
,('SQLSORT_SORTMUTEX','Internal synchronization, while initializing internal sorting structures.')
,('SQLTRACE_BUFFER_FLUSH','Waiting for a background task to flush trace buffers to disk every four seconds.')
,('SQLTRACE_FILE_BUFFER','Synchronization on trace buffers during a file trace.')
,('SQLTRACE_FILE_READ_IO_COMPLETION','Internal use only.')
,('SQLTRACE_FILE_WRITE_IO_COMPLETION','Internal use only.')
,('SQLTRACE_INCREMENTAL_FLUSH_SLEEP','Internal use only.')
,('SQLTRACE_LOCK','Internal use only.')
,('SQLTRACE_PENDING_BUFFER_WRITERS','Internal use only.')
,('SQLTRACE_SHUTDOWN','Occurs while trace shutdown waits for outstanding trace events to complete.')
,('SQLTRACE_WAIT_ENTRIES','Occurs while a SQL Trace event queue waits for packets to arrive on the queue.')
,('SRVPROC_SHUTDOWN','Occurs while the shutdown process waits for internal resources to be released to shutdown cleanly.')
,('STARTUP_DEPENDENCY_MANAGER','Internal use only.')
,('TDS_BANDWIDTH_STATE','Internal use only.')
,('TDS_INIT','Internal use only.')
,('TDS_PROXY_CONTAINER','Internal use only.')
,('TEMPOBJ','Occurs when temporary object drops are synchronized. This wait is rare, and only occurs if a task has requested exclusive access for temp table drops.')
,('TEMPORAL_BACKGROUND_PROCEED_CLEANUP','Internal use only.')
,('TERMINATE_LISTENER','Internal use only.')
,('THREADPOOL','Waiting for a worker to run on. This can indicate that the maximum worker setting is too low, or that batch executions are taking unusually long, thus reducing the number of workers available to satisfy other batches.')
,('TIMEPRIV_TIMEPERIOD','Internal synchronization of the Extended Events timer.')
,('TRACE_EVTNOTIF','Internal use only.')
,('TRACEWRITE','Occurs when the SQL Trace rowset trace provider waits for either a free buffer or a buffer with events to process.')
,('TRAN_MARKLATCH_DT','Waiting for a destroy mode latch on a transaction mark latch. Transaction mark latches are used for synchronization of commits with marked transactions.')
,('TRAN_MARKLATCH_EX','Waiting for an exclusive mode latch on a marked transaction. Transaction mark latches are used for synchronization of commits with marked transactions.')
,('TRAN_MARKLATCH_KP','Waiting for a keep mode latch on a marked transaction. Transaction mark latches are used for synchronization of commits with marked transactions.')
,('TRAN_MARKLATCH_NL','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('TRAN_MARKLATCH_SH','Waiting for a shared mode latch on a marked transaction. Transaction mark latches are used for synchronization of commits with marked transactions.')
,('TRAN_MARKLATCH_UP','Waiting for an update mode latch on a marked transaction. Transaction mark latches are used for synchronization of commits with marked transactions.')
,('TRANSACTION_MUTEX','Synchronization of access to a transaction by multiple batches.')
,('UCS_ENDPOINT_CHANGE','Internal use only.')
,('UCS_MANAGER','Internal use only.')
,('UCS_MEMORY_NOTIFICATION','Internal use only.')
,('UCS_SESSION_REGISTRATION','Internal use only.')
,('UCS_TRANSPORT','Internal use only.')
,('UCS_TRANSPORT_STREAM_CHANGE','Internal use only.')
,('UTIL_PAGE_ALLOC','Occurs when transaction log scans wait for memory to be available during memory pressure.')
,('VDI_CLIENT_COMPLETECOMMAND','Internal use only.')
,('VDI_CLIENT_GETCOMMAND','Internal use only.')
,('VDI_CLIENT_OPERATION','Internal use only.')
,('VDI_CLIENT_OTHER','Internal use only.')
,('VERSIONING_COMMITTING','Internal use only.')
,('VIA_ACCEPT','Occurs when a Virtual Interface Adapter (VIA) provider connection is completed during startup.')
,('VIEW_DEFINITION_MUTEX','Synchronization on access to cached view definitions.')
,('WAIT_FOR_RESULTS','Waiting for a query notification to be triggered.')
,('WAIT_ON_SYNC_STATISTICS_REFRESH','Waiting for synchronous statistics update to complete before query compilation and execution can resume.')
,('WAIT_SCRIPTDEPLOYMENT_REQUEST','Internal use only.')
,('WAIT_SCRIPTDEPLOYMENT_WORKER','Internal use only.')
,('WAIT_XLOGREAD_SIGNAL','Internal use only.')
,('WAIT_XTP_ASYNC_TX_COMPLETION','Internal use only.')
,('WAIT_XTP_CKPT_AGENT_WAKEUP','Internal use only.')
,('WAIT_XTP_CKPT_CLOSE','Waiting for a checkpoint to complete.')
,('WAIT_XTP_CKPT_ENABLED','Checkpointing is disabled, and waiting for checkpointing to be enabled.')
,('WAIT_XTP_CKPT_STATE_LOCK','Synchronizing checking of checkpoint state.')
,('WAIT_XTP_COMPILE_WAIT','Internal use only.')
,('WAIT_XTP_GUEST','Database memory allocator needs to stop receiving low-memory notifications.')
,('WAIT_XTP_HOST_WAIT','Waits are triggered by the database engine and implemented by the host.')
,('WAIT_XTP_OFFLINE_CKPT_BEFORE_REDO','Internal use only.')
,('WAIT_XTP_OFFLINE_CKPT_LOG_IO','Offline checkpoint is waiting for a log read IO to complete.')
,('WAIT_XTP_OFFLINE_CKPT_NEW_LOG','Offline checkpoint is waiting for new log records to scan.')
,('WAIT_XTP_PROCEDURE_ENTRY','Occurs when a drop procedure is waiting for all current executions of that procedure to complete.')
,('WAIT_XTP_RECOVERY','Occurs when database recovery is waiting for recovery of memory-optimized objects to finish.')
,('WAIT_XTP_SERIAL_RECOVERY','Internal use only.')
,('WAIT_XTP_SWITCH_TO_INACTIVE','Internal use only.')
,('WAIT_XTP_TASK_SHUTDOWN','Waiting for an In-Memory OLTP thread to complete.')
,('WAIT_XTP_TRAN_DEPENDENCY','Waiting for transaction dependencies.')
,('WAITFOR','Occurs as a result of a WAITFOR Transact-SQL statement. The duration of the wait is determined by the parameters to the statement. This is a user-initiated wait.')
,('WAITFOR_PER_QUEUE','Internal use only.')
,('WAITFOR_TASKSHUTDOWN','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('WAITSTAT_MUTEX','Synchronization of access to the collection of statistics used to populate sys.dm_os_wait_stats.')
,('WCC','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('WINDOW_AGGREGATES_MULTIPASS','Internal use only.')
,('WINFAB_API_CALL','Internal use only.')
,('WINFAB_REPLICA_BUILD_OPERATION','Internal use only.')
,('WINFAB_REPORT_FAULT','Internal use only.')
,('WORKTBL_DROP','Pausing before retrying, after a failed worktable drop.')
,('WRITE_COMPLETION','Write operation is in progress.')
,('WRITELOG','Waiting for a log flush to complete. Common operations that cause log flushes are checkpoints and transaction commits.')
,('XACT_OWN_TRANSACTION','Waiting to acquire ownership of a transaction.')
,('XACT_RECLAIM_SESSION','Waiting for the current owner of a session to release ownership of the session.')
,('XACTLOCKINFO','Synchronization of access to the list of locks for a transaction. In addition to the transaction itself, the list of locks is accessed by operations such as deadlock detection and lock migration during page splits.')
,('XACTWORKSPACE_MUTEX','Synchronization of defections from a transaction, as well as the number of database locks between enlist members of a transaction.')
,('XDB_CONN_DUP_HASH','Internal use only.')
,('XDES_HISTORY','Internal use only.')
,('XDES_OUT_OF_ORDER_LIST','Internal use only.')
,('XDES_SNAPSHOT','Internal use only.')
,('XDESTSVERMGR','Internal use only.')
,('XE_BUFFERMGR_ALLPROCESSED_EVENT','Extended Events session buffers are flushed to targets. This wait occurs on a background thread.')
,('XE_BUFFERMGR_FREEBUF_EVENT','Occurs when either of the following conditions is true: 1) An Extended Events session is configured for no event loss, and all buffers in the session are currently full. This can indicate that the buffers for an Extended Events session are too small, or should be partitioned. 2) Audits experience a delay. This can indicate a disk bottleneck on the drive where the audits are written.')
,('XE_CALLBACK_LIST','Internal use only.')
,('XE_CX_FILE_READ','Internal use only.')
,('XE_DISPATCHER_CONFIG_SESSION_LIST','Occurs when an Extended Events session that is using asynchronous targets is started or stopped. This wait indicates either of the following:')
,('XE_DISPATCHER_JOIN','Background thread that is used for Extended Events sessions is terminating.')
,('XE_DISPATCHER_WAIT','Background thread that is used for Extended Events sessions is waiting for event buffers to process.')
,('XE_FILE_TARGET_TVF','Internal use only.')
,('XE_LIVE_TARGET_TVF','Internal use only.')
,('XE_MODULEMGR_SYNC','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('XE_OLS_LOCK','Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.')
,('XE_PACKAGE_LOCK_BACKOFF','Identified for informational purposes only. Not supported.')
,('XE_SERVICES_EVENTMANUAL','Internal use only.')
,('XE_SERVICES_MUTEX','Internal use only.')
,('XE_SERVICES_RWLOCK','Internal use only.')
,('XE_SESSION_CREATE_SYNC','Internal use only.')
,('XE_SESSION_FLUSH','Internal use only.')
,('XE_SESSION_SYNC','Internal use only.')
,('XE_STM_CREATE','Internal use only.')
,('XE_TIMER_EVENT','Internal use only.')
,('XE_TIMER_MUTEX','Internal use only.')
,('XE_TIMER_TASK_DONE','Internal use only.')
,('XIO_CREDENTIAL_MGR_RWLOCK','Internal use only.')
,('XIO_CREDENTIAL_RWLOCK','Internal use only.')
,('XIO_EDS_MGR_RWLOCK','Internal use only.')
,('XIO_EDS_RWLOCK','Internal use only.')
,('XIO_IOSTATS_BLOBLIST_RWLOCK','Internal use only.')
,('XIO_IOSTATS_FCBLIST_RWLOCK','Internal use only.')
,('XIO_LEASE_RENEW_MGR_RWLOCK','Internal use only.')
,('XTP_HOST_DB_COLLECTION','Internal use only.')
,('XTP_HOST_LOG_ACTIVITY','Internal use only.')
,('XTP_HOST_PARALLEL_RECOVERY','Internal use only.')
,('XTP_PREEMPTIVE_TASK','Internal use only.')
,('XTP_TRUNCATION_LSN','Internal use only.')
,('XTPPROC_CACHE_ACCESS','Occurs when for accessing all natively compiled stored procedure cache objects.')
,('XTPPROC_PARTITIONED_STACK_CREATE','Occurs when allocating per-NUMA node natively compiled stored procedure cache structures (must be done single threaded) for a given procedure.')
;

RETURN ;

END ;

GO

IF OBJECT_ID ( 'dbo.x_CompareData' ) IS NULL
EXEC sp_executesql N'CREATE PROCEDURE dbo.x_CompareData AS BEGIN RETURN 0 ; END' ;

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
    @Alias NVARCHAR(128)= NULL
    ,
    @Null NVARCHAR(128) = NULL
    ,
    @Quote BIT = NULL
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
            ( '@Keys' , 'NVARCHAR(MAX)' , 'Optional list of key columns. If no key column is specified, identity or primary key will be used.' )
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
            ( '@Alias' , 'NVARCHAR(128)' , 'Column alias for operation text.' )
            ,
            ( '@Null' , 'NVARCHAR(128)' , 'Optional text value for NULL.' )
            ,
            ( '@Quote' , 'BIT' , 'Display values quoted for SQL script.' )
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
  SET @Quote = ISNULL(@Quote , 0) ;

    SET @Alias = ISNULL(@Alias , '!') ;
    IF @Alias <> '' AND '[' <> SUBSTRING(@Alias , 1 , 1)
    BEGIN
      SET @Alias = QUOTENAME(@Alias) ;
    END ;

    SET @Null = ISNULL(@Null , '<?_NULL_?>') ;
    IF @Null <> '' AND '''' <> SUBSTRING(@Null , 1 , 1)
    BEGIN
      SET @Null = QUOTENAME(@Null , '''') ;
    END ;

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
    DECLARE @IsNull BIT ;
    DECLARE @Comparisation NVARCHAR(MAX) ;
    DECLARE @Alternative NVARCHAR(MAX) ;

    DECLARE @ColumnsA NVARCHAR(MAX) = '' ;
    DECLARE @ColumnsJ NVARCHAR(MAX) = '' ;
    DECLARE @ColumnsD NVARCHAR(MAX) = '' ;
    DECLARE @ColumnsK NVARCHAR(MAX) = '' ;
    DECLARE @ColumnsN NVARCHAR(MAX) = '' ;
    DECLARE @ColumnsW NVARCHAR(MAX) = '' ;
    DECLARE @ColumnsZ NVARCHAR(MAX) = '' ;
    DECLARE @ColumnsQ NVARCHAR(MAX) = '' ;
    DECLARE @ColumnsB NVARCHAR(MAX) = '' ;
    DECLARE @ColumnsV NVARCHAR(MAX) = '' ;
    
     DECLARE CR_5 CURSOR FOR
    SELECT QUOTENAME(a.[Name]) [Column] , c.[Type] , c.[Nullable] [IsNull]
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
    FETCH NEXT FROM CR_5 INTO @Column , @Type , @IsNull , @IsKey , @IsValue ;
    IF @@FETCH_STATUS <> 0 BREAK ;
      SET @ColumnsZ = @ColumnsZ + ' , ' + @Column ;
      IF @IsKey = 1
      BEGIN
        SET @ColumnsN = @ColumnsN + ' AND ' + 'b.' + @Column + ' IS NULL' ;
        SET @ColumnsJ = @ColumnsJ + ' AND ' + 'a.' + @Column + ' = ' + 'b.' + @Column ;
      END ;
      IF @IsValue = 1
      BEGIN
        SET @Comparisation = 'a.' + @Column + ' <> b.' + @Column ;
        IF @Type = 'TEXT' OR @Type = 'NTEXT'
        BEGIN
          SET @Comparisation = 'CAST(a.' + @Column + ' AS NVARCHAR(MAX)) <> CAST(b.' + @Column + ' AS NVARCHAR(MAX))';
        END ;
        IF @IsNull = 1
        BEGIN
          SET @ColumnsW = @ColumnsW + ' OR ' + '( ' + 'a.' + @Column + ' IS NULL AND b.' + @Column + ' IS NOT NULL OR a.' 
            + @Column + ' IS NOT NULL AND b.' + @Column + ' IS NULL OR ' + @Comparisation + ' )'
            ;
        END ;
        IF @IsNull = 0
        BEGIN
          SET @ColumnsW = @ColumnsW + ' OR ' + @Comparisation
            ;
        END ;
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
      IF @Type = 'FLOAT'
      BEGIN
        SET @Text = 'CASE WHEN a.' + @Column + ' <> 0.0 THEN CONVERT(VARCHAR(24) , a.' + @Column + ' , 128) ELSE ''0'' END';
      END ;
      IF @Type = 'REAL'
      BEGIN
        SET @Text = 'CASE WHEN a.' + @Column + ' <> 0.0 THEN CONVERT(VARCHAR(24) , a.' + @Column + ' , 3) ELSE ''0'' END';
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
      IF @Type = 'VARBINARY'
      BEGIN
        SET @Text = 'CONVERT(VARCHAR(MAX) , a.' + @Column + ' , 1)';
      END ;
      IF @Type = 'TEXT' OR @Type = 'NTEXT'
      BEGIN
        SET @Text = 'CAST(a.' + @Column + ' AS NVARCHAR(MAX))';
      END ;
      IF @Text = ''
      BEGIN
        SET @Text = 'a.' + @Column ;
      END ;
      SET @ColumnsA = @ColumnsA + ' , ' + @Text + ' AS ' + @Column ;
      SET @Alternative = ''''''''' + REPLACE(' + @Text + ' , '''''''' , '''''''''''') + ''''''''' ;
      IF @Type = 'VARBINARY'
      BEGIN
        SET @Alternative = @Text ;
      END ;
      IF @Type = 'VARCHAR' OR @Type = 'NVARCHAR' OR @Type = 'CHAR' OR @Type = 'NCHAR' OR @Type = 'TEXT' OR @Type = 'NTEXT'
      BEGIN
        SET @Alternative = '''N'' + ' + @Alternative ;
      END ;
      IF @IsNull = 0
      BEGIN
        SET @ColumnsB = @ColumnsB + ' , ' + @Alternative + ' AS ' + @Column ;
      END ;
      IF @IsNull = 1
      BEGIN
        SET @ColumnsB = @ColumnsB + ' , CASE WHEN a.' + @Column + ' IS NULL THEN ''NULL'' ELSE ' + @Alternative + ' END AS ' + @Column ;
      END ;
      IF @IsKey = 1
      BEGIN
        SET @ColumnsK = @ColumnsK + ' , ' + @Text + ' AS ' + @Column ;
        SET @ColumnsV = @ColumnsV + ' , ' + @Alternative + ' AS ' + @Column ;
      END ;
      IF @IsValue = 1
      BEGIN
        SET @Comparisation = 'a.' + @Column + ' = b.' + @Column ;
        IF @Type = 'TEXT' OR @Type = 'NTEXT'
        BEGIN
          SET @Comparisation = 'CAST(a.' + @Column + ' AS NVARCHAR(MAX)) = CAST(b.' + @Column + ' AS NVARCHAR(MAX))';
        END ;
        IF @IsNull = 1
        BEGIN
          SET @ColumnsD = @ColumnsD + ' , ' + 'CASE'
            + ' WHEN a.' + @Column + ' IS NULL AND b.' + @Column + ' IS NULL THEN NULL'
            + ' WHEN a.' + @Column + ' IS NULL AND b.' + @Column + ' IS NOT NULL THEN ' + @Null
            + ' WHEN ' + @Comparisation + ' THEN NULL'
            + ' ELSE ' + @Text
            + ' END AS ' + @Column 
            ;
          SET @ColumnsQ = @ColumnsQ + ' , ' + 'CASE'
            + ' WHEN a.' + @Column + ' IS NULL AND b.' + @Column + ' IS NULL THEN NULL'
            + ' WHEN a.' + @Column + ' IS NULL AND b.' + @Column + ' IS NOT NULL THEN ' + '''NULL'''
            + ' WHEN ' + @Comparisation + ' THEN NULL'
            + ' ELSE ' + @Alternative
            + ' END AS ' + @Column 
            ;
        END ;
        IF @IsNull = 0
        BEGIN
          SET @ColumnsD = @ColumnsD + ' , ' + 'CASE'
            + ' WHEN ' + @Comparisation + ' THEN NULL'
            + ' ELSE ' + @Text
            + ' END AS ' + @Column 
            ;
          SET @ColumnsQ = @ColumnsQ + ' , ' + 'CASE'
            + ' WHEN ' + @Comparisation + ' THEN NULL'
            + ' ELSE ' + @Alternative
            + ' END AS ' + @Column 
            ;
        END ;
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
    SET @ColumnsB = SUBSTRING(@ColumnsB , 4 , 1 + LEN(@ColumnsB) - 4) ;
    SET @ColumnsV = SUBSTRING(@ColumnsV , 4 , 1 + LEN(@ColumnsV) - 4) ;

  -- Generate SELECT statement for comparisation --

  DECLARE @SelectScript NVARCHAR(MAX) = '' ;
    DECLARE @QuotedScript NVARCHAR(MAX) = '' ;

    IF @Insert = 1
    BEGIN
      SET @SelectScript = @SelectScript 
        + 'SELECT ''INSERT'' AS ' + @Alias + ' , ' + @ColumnsA
        + CHAR(13) + CHAR(10)
        + 'FROM ' + @Source + ' a'
        + CHAR(13) + CHAR(10)
        + 'LEFT JOIN ' + @Destination + ' b ON ' + @ColumnsJ
        + CHAR(13) + CHAR(10)
        + 'WHERE ' + @ColumnsN
        ;
      SET @QuotedScript = @QuotedScript 
        + 'SELECT ''INSERT'' AS ' + @Alias + ' , ' + @ColumnsB
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
      IF @QuotedScript <> ''
      BEGIN
        SET @QuotedScript = @QuotedScript
          + CHAR(13) + CHAR(10)
          + 'UNION ALL'
          + CHAR(13) + CHAR(10)
          ;
      END ;
      SET @SelectScript = @SelectScript 
        + 'SELECT ''DELETE'' AS ' + @Alias + ' , ' + @ColumnsA
        + CHAR(13) + CHAR(10)
        + 'FROM ' + @Destination + ' a'
        + CHAR(13) + CHAR(10)
        + 'LEFT JOIN ' + @Source + ' b ON ' + @ColumnsJ
        + CHAR(13) + CHAR(10)
        + 'WHERE ' + @ColumnsN
        ;
      SET @QuotedScript = @QuotedScript 
        + 'SELECT ''DELETE'' AS ' + @Alias + ' , ' + @ColumnsB
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
      IF @QuotedScript <> ''
      BEGIN
        SET @QuotedScript = @QuotedScript
          + CHAR(13) + CHAR(10)
          + 'UNION ALL'
          + CHAR(13) + CHAR(10)
          ;
      END ;
      SET @SelectScript = @SelectScript 
        + 'SELECT ''UPDATE'' AS ' + @Alias + ' , ' + @ColumnsK + @ColumnsD
        + CHAR(13) + CHAR(10)
        + 'FROM ' + @Source + ' a'
        + CHAR(13) + CHAR(10)
        + 'JOIN ' + @Destination + ' b ON ' + @ColumnsJ
        + CHAR(13) + CHAR(10)
        + 'WHERE ' + @ColumnsW
        ;
      SET @QuotedScript = @QuotedScript 
        + 'SELECT ''UPDATE'' AS ' + @Alias + ' , ' + @ColumnsV + @ColumnsQ
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
      IF @Quote = 0
      BEGIN
        PRINT CAST(@SelectScript AS NTEXT) ;
      END ;
      IF @Quote = 1
      BEGIN
        PRINT CAST(@QuotedScript AS NTEXT) ;
      END ;
    END ;

    IF @Select = 1 AND @Pretend = 0
    BEGIN
      IF @Quote = 0
      BEGIN
        EXEC sp_executesql @SelectScript ;
      END ;
      IF @Quote = 1
      BEGIN
        EXEC sp_executesql @QuotedScript ;
      END ;
    END ;

    DECLARE @ProcessScript NVARCHAR(MAX) = '' ;
    DECLARE @MergeScript NVARCHAR(MAX) = '' ;

    SET @ProcessScript = @ProcessScript
      + 'DECLARE C CURSOR FOR'
      + CHAR(13) + CHAR(10)
      + @QuotedScript
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
      IF @I > 1 SET @ProcessScript = @ProcessScript + ' , ' ;
      SET @ProcessScript = @ProcessScript + ''' + @' + CONVERT(VARCHAR(5) , @I) + ' + ''' 
        ;
    END ;

    SET @ProcessScript = @ProcessScript
      + ' )'' ;'
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
        + CONVERT(VARCHAR(5) , @I) + ' IS NULL THEN ''IS NULL'' ELSE ''= '' + @' + CONVERT(VARCHAR(5) , @I) + ' + '''' END'
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
      + '    SET @Q = ''UPDATE ' + @Destination + ' SET {:8<-CUT->8:}'''
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
      SET @ProcessScript = @ProcessScript + @Text + ' = '' + @' 
        + CONVERT(VARCHAR(5) , @I + @K) + ' END'
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
        + CONVERT(VARCHAR(5) , @I) + ' IS NULL THEN ''IS NULL'' ELSE ''= '' + @' + CONVERT(VARCHAR(5) , @I) + ' + '''' END'
        ;
    END ;

    SET @ProcessScript = @ProcessScript
      + ' ;'
      + CHAR(13) + CHAR(10)
      + '    SET @Q = REPLACE(@Q , '' SET {:8<-CUT->8:} , '' , '' SET '') ;'
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

IF OBJECT_ID ( 'dbo.x_CopyData' ) IS NULL
EXEC sp_executesql N'CREATE PROCEDURE dbo.x_CopyData AS BEGIN RETURN 0 ; END' ;

GO

--
-- Copy data from one table to another.
--
-- Copying is made with simple query INSERT INTO ... SELECT FROM ... with full list of columns.
-- Optionally create destination table, drop it first, or delete existing data.
-- Will also work with linked servers. 
--
ALTER PROCEDURE dbo.x_CopyData
( 
    @SourceDatabase NVARCHAR(128) = '' , @SourceSchema NVARCHAR(128) = '' , @SourceTable NVARCHAR(128) = '' , @SourceServer NVARCHAR(128) = ''
    ,
    @DestinationDatabase NVARCHAR(128) = '' , @DestinationSchema NVARCHAR(128) = '' , @DestinationTable NVARCHAR(128) = '' , @DestinationServer NVARCHAR(128) = ''
    ,
    @Create BIT = 0 , @Drop BIT = 0 , @Copy BIT = 1 , @Delete BIT = 0 , @Where NVARCHAR(2000) = ''
    ,
    @IncludeIdentity BIT = 1 , @IncludeComputed BIT = 0 , @IdentityNullable BIT = 0
    ,
    @Pretend BIT = 0 , @Help BIT = 0 
)
AS
BEGIN
    IF @Help = 1
    BEGIN
        DECLARE @Parameter TABLE
        (
            [Parameter] NVARCHAR(20) ,
            [Type] NVARCHAR(20) ,
            [Description] NVARCHAR(500)
        );
        INSERT INTO @Parameter ( [Parameter] , [Type] , [Description] )
        VALUES
            ( '@Pretend' , 'BIT' , 'Print queries to be executed but don''t do anything. Will however read column definition from source table.' )
            ,
            ( '@Help' , 'BIT' , 'Show this help' )
            ,
            ( '@SourceDatabase' , 'NVARCHAR(128)' , 'Source database name. Optional.' )
            ,
            ( '@SourceSchema' , 'NVARCHAR(128)' , 'Source schema name. If omited, default "dbo" will be used.' )
            ,
            ( '@SourceTable' , 'NVARCHAR(128)' , 'Source table name. Required.' )
            ,
            ( '@SourceServer' , 'NVARCHAR(128)' , 'Source linked server. Optional.' )
            ,
            ( '@DestinationDatabase' , 'NVARCHAR(128)' , 'Destination database name. If not specified, source database name will be used.' )
            ,
            ( '@DestinationSchema' , 'NVARCHAR(128)' , 'Destination schema name. If omited, default "dbo" will be used.' )
            ,
            ( '@DestinationTable' , 'NVARCHAR(128)' , 'Destination table name. If not specified, source table name will be used.' )
            ,
            ( '@DestinationServer' , 'NVARCHAR(128)' , 'Destination linked server. Optional. Be aware that trying to create or drop table will require linked server to be configured for RPC.' )
            ,
            ( '@Copy' , 'BIT' , 'Copy data with simple query INSERT INTO ... SELECT FROM ... with full list of columns.' )
            ,
            ( '@Create' , 'BIT' , 'Create destination table if not exists.' )
            ,
            ( '@Drop' , 'BIT' , 'Drop destination table if exists.' )
            ,
            ( '@Delete' , 'BIT' , 'Delete data from destination table first.' )
            ,
            ( '@Where' , 'NVARCHAR(2000)' , 'Optional WHERE clausule for SELECT operation.' )
            ,
            ( '@IncludeIdentity' , 'BIT' , 'Include identity columns for copying.' )
            ,
            ( '@IncludeComputed' , 'BIT' , 'Include computed columns for copying. By default computed columns are not copied nor created.' )
            ,
            ( '@IdentityNullable' , 'BIT' , 'Force identity column to be nullable in create table script.' )
            ;
        SELECT [Parameter] , [Type] , [Description ____________________________________________________________________________________________] = [Description] FROM @Parameter ;

        DECLARE @Description TABLE
        (
            [Description] NVARCHAR(200)
        );
        INSERT INTO @Description
        VALUES
            ( 'Copy data from one table to another.' )
            ,
            ( 'Copying is made with simple query INSERT INTO ... SELECT FROM ... with full list of columns.' )
            ,
            ( 'Optionally create destination table, drop it first, or delete existing data.' )
            ,
            ( 'Will also work with linked servers.' )
            ;
        SELECT [Description ____________________________________________________________________________________________] = [Description] FROM @Description ;
        
        RETURN;
    END

    IF @SourceTable IS NULL OR @SourceTable = ''
    BEGIN
        RAISERROR ( 'Source table must be specified' , 18 , 1 ) ;
        RETURN -1 ;
    END

    IF ( @DestinationTable IS NULL OR @DestinationTable = '' ) AND ( @DestinationDatabase IS NULL OR @DestinationDatabase = '' )
        AND ( @Pretend IS NULL OR @Pretend <> 1 )
    BEGIN
        RAISERROR ( 'Destination table or destination database must be specified' , 18 , 1 ) ;
        RETURN -1 ;
    END

    IF @Copy = 0 AND @Create = 0 AND @Drop = 0 AND @Delete = 0
    BEGIN
        RAISERROR ( 'No operation specified' , 18 , 1 ) ;
        RETURN -1 ;
    END

    SET @Create = ISNULL(@Create , 0) ;
    SET @Drop = ISNULL(@Drop , 0) ;
    SET @Copy = ISNULL(@Copy , 0) ;
    SET @Delete = ISNULL(@Delete , 0) ;

    SET @IncludeIdentity = ISNULL(@IncludeIdentity , 0) ;
    SET @IncludeComputed = ISNULL(@IncludeComputed , 0) ;
    SET @IdentityNullable = ISNULL(@IdentityNullable , 0) ;

    SET NOCOUNT ON ;

    DECLARE @SourceLink NVARCHAR(500) ;
    DECLARE @DestinationLink NVARCHAR(500) ;
    DECLARE @SourceFull NVARCHAR(1000) ;
    DECLARE @DestinationFull NVARCHAR(1000) ;
    DECLARE @SourceShort NVARCHAR(1000) ;
    DECLARE @DestinationShort NVARCHAR(1000) ;

    IF @SourceServer IS NULL SET @SourceServer = '' ;
    IF ISNULL(@SourceDatabase , '') = '' SET @SourceDatabase = DB_NAME() ;

    IF @DestinationServer IS NULL SET @DestinationServer = '' ;
    IF ISNULL(@DestinationDatabase , '') = '' SET @DestinationDatabase = DB_NAME() ;

    IF ISNULL(@DestinationTable , '') = '' SET @DestinationTable = @SourceTable ;

    IF ISNULL(@SourceSchema , '') = '' SET @SourceSchema = 'dbo' ;
    IF ISNULL(@DestinationSchema , '') = '' SET @DestinationSchema = 'dbo' ;

    SET @SourceLink = QUOTENAME(@SourceDatabase) ;
    IF @SourceServer <> '' AND SUBSTRING(@SourceServer , 1 , 1) <> '[' SET @SourceServer = QUOTENAME(@SourceServer) ;
    IF @SourceServer <> '' SET @SourceLink = @SourceServer + '.' + @SourceLink ;

    SET @DestinationLink = QUOTENAME(@DestinationDatabase) ;
    IF @DestinationServer <> '' AND SUBSTRING(@DestinationServer , 1 , 1) <> '[' SET @DestinationServer = QUOTENAME(@DestinationServer) ;
    IF @DestinationServer <> '' SET @DestinationLink = @DestinationServer + '.' + @DestinationLink ;

    SET @SourceFull = @SourceLink + '.' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@SourceTable) ;
    SET @DestinationFull = @DestinationLink + '.' + QUOTENAME(@DestinationSchema) + '.' + QUOTENAME(@DestinationTable) ;

    SET @SourceShort = QUOTENAME(@SourceDatabase) + '.' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@SourceTable) ;
    SET @DestinationShort = QUOTENAME(@DestinationDatabase) + '.' + QUOTENAME(@DestinationSchema) + '.' + QUOTENAME(@DestinationTable) ;

    IF @SourceFull = @DestinationFull AND ( @Pretend IS NULL OR @Pretend <> 1 )
    BEGIN
        RAISERROR ( 'Source and destination are the same' , 18 , 1 ) ;
        RETURN -1 ;
    END

    DECLARE @Query NVARCHAR(MAX) ;

    SET @Query = '
SELECT c.[name] AS [Name]
, UPPER(y.[name]) AS [Type]
, c.[is_nullable] AS [Null]
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

    SET @Query = REPLACE(@Query , ':source:' , @SourceLink) ;
    SET @Query = REPLACE(@Query , ':table:' , QUOTENAME(@SourceTable, '''')) ;
    SET @Query = REPLACE(@Query , ':schema:' , QUOTENAME(@SourceSchema, '''')) ;

    SET @Query = 'SET @CursorColumns = CURSOR FAST_FORWARD FOR' + CHAR(13) + CHAR(10) + @Query ;
    SET @Query = @Query + CHAR(13) + CHAR(10) + 'OPEN @CursorColumns ;' ;

    DECLARE @CursorColumns CURSOR ;

    DECLARE @Columns TABLE
    (
        [Name] NVARCHAR(128) ,
        [Type] NVARCHAR(128) ,
        [Null] BIT ,
        [Computed] BIT ,
        [Identity] BIT ,
        [Precision] INT ,
        [Scale] INT ,
        [Length] INT
    ) ;

    DECLARE @DefinitionList TABLE ( [_] NVARCHAR(500) ) ;

    DECLARE @ColumnName NVARCHAR(128) ;
    DECLARE @ColumnType NVARCHAR(128) ;
    DECLARE @ColumnNull BIT ;
    DECLARE @ColumnComputed BIT ;
    DECLARE @ColumnIdentity BIT ;
    DECLARE @ColumnPrecision INT ;
    DECLARE @ColumnScale INT ;
    DECLARE @ColumnLength INT ;

    DECLARE @Text NVARCHAR(4000) ;

    DECLARE @CreateScript NVARCHAR(MAX) = '' ;
    DECLARE @ColumnList NVARCHAR(MAX) = '' ;

    EXECUTE sp_executesql @Query , N'@CursorColumns CURSOR OUTPUT' , @CursorColumns = @CursorColumns OUTPUT ;

    WHILE 1 = 1
    BEGIN
        FETCH NEXT FROM @CursorColumns INTO @ColumnName , @ColumnType , @ColumnNull , @ColumnComputed , @ColumnIdentity , @ColumnPrecision , @ColumnScale , @ColumnLength ;
        IF @@FETCH_STATUS <> 0 BREAK ;

        IF @ColumnIdentity = 1 AND @IncludeIdentity <> 1 CONTINUE ;
        IF @ColumnComputed = 1 AND @IncludeComputed <> 1 CONTINUE ;

        INSERT INTO @Columns VALUES ( @ColumnName , @ColumnType , @ColumnNull , @ColumnComputed , @ColumnIdentity , @ColumnPrecision , @ColumnScale , @ColumnLength ) ;
        SET @Text = QUOTENAME(@ColumnName) + ' ' + @ColumnType ;

        IF @ColumnLength > 0 AND @ColumnType IN ('NCHAR' , 'NVARCHAR')
        BEGIN
          SET @ColumnLength = @ColumnLength / 2 ;
        END

        IF @ColumnType IN ('DATETIME2' , 'DATETIMEOFFSET' , 'TIME')
        BEGIN
          IF @ColumnScale IS NULL
            SET @Text = @Text + '(7)' ;
          IF @ColumnScale >= 0
            SET @Text = @Text + '(' + CONVERT(VARCHAR(10) , @ColumnScale) + ')' ;
        END
        ELSE
        IF @ColumnPrecision > 0
        BEGIN 
            SET @Text = @Text + '(' + CONVERT(VARCHAR(10) , @ColumnPrecision) ;
            IF @ColumnScale > 0 
              SET @Text = @Text + ',' + CONVERT(VARCHAR(10) , @columnScale ) ;
            IF @ColumnScale = 0 AND @ColumnType IN ('DECIMAL' , 'NUMERIC') 
              SET @Text = @Text + ',' + CONVERT(VARCHAR(10) , @columnScale ) ;
            SET @Text = @Text + ')'
        END
        ELSE IF @ColumnLength > 0
        BEGIN
            SET @Text = @Text + '(' + CONVERT(VARCHAR(10) , @ColumnLength) + ')' ;
        END
        ELSE IF @ColumnLength < 0
        BEGIN
            SET @Text = @Text + '(MAX)' ;
        END

        IF @ColumnIdentity = 1 AND @IdentityNullable = 1 SET @ColumnNull = 1 ;

        SET @Text = @Text + ' ' + CASE WHEN @ColumnNull = 1 THEN 'NULL' ELSE 'NOT NULL' END ;

        INSERT INTO @DefinitionList VALUES ( @Text ) ;

        IF @ColumnList <> '' SET @ColumnList = @ColumnList + ' , ' ;
        SET @ColumnList = @ColumnList + QUOTENAME(@ColumnName) ;

        IF @CreateScript <> '' SET @CreateScript = @CreateScript + ' ,' + CHAR(13) + CHAR(10) ;
        SET @CreateScript = @CreateScript + '  ' + @Text ;
    END

    CLOSE @CursorColumns ;
    DEALLOCATE @CursorColumns ;

    SET @CreateScript = 'CREATE TABLE ' + @DestinationShort + CHAR(13) + CHAR(10)
        + '(' + CHAR(13) + CHAR(10) + @CreateScript
        + CHAR(13) + CHAR(10) + ')' ;

    IF @Drop = 1
    BEGIN
        SET @Query = 'IF OBJECT_ID(N''' + + REPLACE(@DestinationShort, '''', '''''') + ''') IS NOT NULL' + CHAR(13) + CHAR(10) 
            + 'DROP TABLE ' + @DestinationShort ;

        IF @DestinationServer <> ''
            SET @Query = 'EXEC (N''' + CHAR(13) + CHAR(10) + REPLACE(@Query, '''', '''''') + CHAR(13) + CHAR(10) + ''') AT ' + @DestinationServer ;

        IF @Pretend = 1
            PRINT @Query ;
        ELSE
            EXECUTE sp_executesql @Query ;
    END

    IF @Create = 1
    BEGIN
        SET @Query = 'IF OBJECT_ID(N''' + + REPLACE(@DestinationShort, '''', '''''') + ''') IS NULL' + CHAR(13) + CHAR(10)
            + @CreateScript ;

        IF @DestinationServer <> ''
            SET @Query = 'EXEC (N''' + CHAR(13) + CHAR(10) + REPLACE(@Query, '''', '''''') + CHAR(13) + CHAR(10) + ''') AT ' + @DestinationServer ;

        IF @Pretend = 1
            PRINT @Query ;
        ELSE
            EXECUTE sp_executesql @Query ;
    END

    IF @Delete = 1
    BEGIN
        SET @Query = 'DELETE FROM ' + @DestinationFull ;

        IF @Pretend = 1
            PRINT @Query ;
        ELSE
            EXECUTE sp_executesql @Query ;
    END

    IF @Copy = 1
    BEGIN
        SET @Query = 'INSERT INTO ' + @DestinationFull + CHAR(13) + CHAR(10) + '( ' + @ColumnList + ' )' + CHAR(13) + CHAR(10)
            + 'SELECT' + CHAR(13) + CHAR(10) + '  ' + @ColumnList + CHAR(13) + CHAR(10)
            + 'FROM ' + @SourceFull ;

        IF ISNULL(@Where , '') <> ''
            SET @Query = @Query + CHAR(13) + CHAR(10) + 'WHERE ' + @Where ;

        IF @Pretend = 1
            PRINT @Query ;
        ELSE
            EXECUTE sp_executesql @Query ;
    END

    IF @Pretend = 1
        RETURN 0 ;
    ELSE
        RETURN 1 ;
END

GO

IF OBJECT_ID ( 'dbo.x_DefaultConstraint' ) IS NULL
EXEC sp_executesql N'CREATE PROCEDURE dbo.x_DefaultConstraint AS BEGIN RETURN 0; END' ;

GO

--
-- Show default contraints.
--
ALTER PROCEDURE dbo.x_DefaultConstraint ( @Database NVARCHAR(128) = NULL , @Table NVARCHAR(128) = NULL , @Schema NVARCHAR(128) = NULL , @Column NVARCHAR(128) = NULL , @Constraint NVARCHAR(128) = NULL , @Pretend BIT = 0 , @Help BIT = 0 )
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
  
        RETURN 0 ;
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

    RETURN 0 ;
END ;

GO

IF OBJECT_ID ( 'dbo.x_FileConfiguration' ) IS NULL
EXEC sp_executesql N'CREATE PROCEDURE dbo.x_FileConfiguration AS BEGIN RETURN 0; END' ;

GO

--
-- Show database files configuration.
--
ALTER PROCEDURE dbo.x_FileConfiguration ( @Database NVARCHAR(260) = NULL , @Pretend BIT = 0 , @Help BIT = 0 )
AS
BEGIN
    IF @Help = 1
    BEGIN
        DECLARE @Parameter TABLE
        (
            [Parameter] NVARCHAR(10) ,
            [Type] NVARCHAR(20) ,
            [Description] NVARCHAR(200)
        ) ;
        INSERT INTO @Parameter ( [Parameter] , [Type] , [Description] )
        VALUES
            ( '@Database' , 'NVARCHAR(260)' , 'Database name' )
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
        
        RETURN 0 ;
    END

    DECLARE @_from NVARCHAR(257) = @Database ;
    IF @_from IS NOT NULL AND @_from <> ''
        SET @_from = CASE WHEN SUBSTRING(@_from , 1 , 1) = '[' THEN @_from ELSE QUOTENAME(@_from) END + '.' ;

    DECLARE @SQL NVARCHAR(2000) = '' ;

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
' ;

    IF @Pretend = 1
        PRINT @SQL ;
    ELSE
        EXECUTE sp_executesql @SQL ;

    RETURN 0 ;
END ;

GO

IF OBJECT_ID ( 'dbo.x_FileSpeed' ) IS NULL
EXEC sp_executesql N'CREATE PROCEDURE dbo.x_FileSpeed AS BEGIN RETURN 0; END' ;

GO

--
-- Show I/O speed of database files.
--
ALTER PROCEDURE dbo.x_FileSpeed ( @Database NVARCHAR(260) = NULL , @Sample INT = NULL 
  , @CountPerSecond BIT = NULL , @ActivityOnly BIT = NULL , @Output NVARCHAR(260) = NULL , @Retain INT = NULL
  , @Now BIT = NULL 
  , @Pretend BIT = NULL , @Help BIT = NULL 
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
            [Description] NVARCHAR(200)
        ) ;
        INSERT INTO @Parameter ( [Parameter] , [Type] , [Description] )
        VALUES
            ( '@Database' , 'NVARCHAR(260)' , 'Database name' )
            ,
            ( '@Sample' , 'INT' , 'Sample time in seconds. Default is 30 seconds and minimum value is 10 seconds.' )
            ,
            ( '@CountPerSecond' , 'BIT' , 'Display total reads and writes per second rather than per minute which is default.' )
            ,
            ( '@ActivityOnly' , 'BIT' , 'Exclude rows where there is no activity' )
            ,
            ( '@Output' , 'NVARCHAR(260)' , 'If this parameter is supplied, results will be inserted to destination table instead of displaying result. Destination table will be created if not exists.' )
            ,
            ( '@Retain' , 'INT' , 'Number of days to keep data in destination table. Default is 7 days after which data will be deleted after execution. When set to 0 or negative value, no data will be deleted.' )
            ,
            ( '@Now' , 'BIT' , 'Include column with current date and time' )
            ,
            ( '@Pretend' , 'BIT' , 'Print query to be executed but don''t do anything' )
            ,
            ( '@Help' , 'BIT' , 'Show this help' )
            ;
        SELECT [Parameter] , [Type] , [Description                                                                     ] = [Description] FROM @Parameter ;

        DECLARE @Description TABLE
        (
            [Description] NVARCHAR(200)
        ) ;
        INSERT INTO @Description ( [Description] )
        VALUES
            ( 'Show I/O speed of database files.' ) 
            ;
        SELECT [Description                                                                     ] = [Description] FROM @Description ;
        
        RETURN 0 ;
    END ;

    DECLARE @SQL NVARCHAR(MAX) = '' ;

    IF @Output IS NOT NULL AND @Output <> ''
    BEGIN
        DECLARE @N01 NVARCHAR(50) = '' ;
        DECLARE @I01 INT = LEN(@Output) ;
        DECLARE @C01 CHAR ;
        WHILE @I01 > 1 AND LEN(@N01) < 50
        BEGIN
            SET @C01 = SUBSTRING(@Output , @I01 , 1) ;
            IF @C01 = '.'
            BREAK ;
            IF @C01 >= 'A' AND @C01 <= 'Z' OR @C01 >= 'a' AND @C01 <= 'z' OR @C01 >= '0' AND @C01 <= '9' OR @C01 = '_'
            SET @N01 = @C01 + @N01 ;
            SET @I01 = @I01 - 1 ;
        END ;
        IF @N01 = '' SET @N01 = 'FileSpeed' ;

        DECLARE @PK_NAME NVARCHAR(60) = 'PK_' + @N01 ;
        DECLARE @DF_TIME_NAME NVARCHAR(60) = 'DF_' + @N01 + '_Time' ;

        SET @SQL = @SQL + 'IF ( SELECT OBJECT_ID(N''' ;
        SET @SQL = @SQL + REPLACE(@Output , '''' , '''''') ;
        SET @SQL = @SQL + ''' , ''U'') ) IS NULL' ;
        SET @SQL = @SQL +
'
CREATE TABLE ' + @Output + '
(
  [Time] DATETIMEOFFSET CONSTRAINT ' + @DF_TIME_NAME + ' DEFAULT GETDATE() NOT NULL ,
  [Database] NVARCHAR (128) NOT NULL ,
  [File] NVARCHAR(260) NOT NULL ,
  [Read speed] DECIMAL(9,2) NOT NULL ,
  [Write speed] DECIMAL(9,2) NOT NULL ,
  [Read count] INT NOT NULL ,
  [Write count] INT NOT NULL ,
  [Total wait] DECIMAL(9,1) NOT NULL ,
  [Read wait] DECIMAL(9,1) NOT NULL ,
  [Write wait] DECIMAL(9,1) NOT NULL ,
  [Type] NVARCHAR(10) NOT NULL ,
  [State] NVARCHAR(16) NOT NULL ,
  [Size] DECIMAL(18,1) NOT NULL ,
  CONSTRAINT ' + @PK_NAME + ' PRIMARY KEY CLUSTERED ( [Time] , [Database] , [File] )
) ;
' ;
        DECLARE @EXEC NVARCHAR(2000) = 'EXEC ' ;
        SET @EXEC = @EXEC + QUOTENAME(DB_NAME()) + '.' + QUOTENAME(OBJECT_SCHEMA_NAME(@@PROCID)) + '.' + QUOTENAME(OBJECT_NAME(@@PROCID)) ;

        IF @Database IS NOT NULL
            SET @EXEC = @EXEC + ' @Database=N''' + REPLACE(@Database , '''' , '''''') + ''' ,' ;
        IF @Sample IS NOT NULL
            SET @EXEC = @EXEC + ' @Sample=' + CONVERT(NVARCHAR(5) , @Sample) + ' ,' ;
        IF @CountPerSecond IS NOT NULL
            SET @EXEC = @EXEC + ' @CountPerSecond=' + CONVERT(NVARCHAR(1) , @CountPerSecond) + ' ,' ;
        IF @ActivityOnly IS NOT NULL
            SET @EXEC = @EXEC + ' @ActivityOnly=' + CONVERT(NVARCHAR(1) , @ActivityOnly) + ' ,' ;

        IF SUBSTRING(@EXEC , LEN(@EXEC) - 1 , 2) = ' ,'
            SET @EXEC = SUBSTRING(@EXEC , 1 , LEN(@EXEC) - 2) ;
            
        SET @EXEC = @EXEC + ' ;' ;

        SET @SQL = @SQL +
'
INSERT INTO [DBAtools].[dbo].[FileSpeed]
( [Database] , [File] , [Read speed] , [Write speed] , [Read count] , [Write count] , [Total wait] , [Read wait] , [Write wait] , [Type] , [State] , [Size] )
' ;

        SET @SQL = @SQL + @EXEC ;

        SET @Retain = ISNULL(@Retain , 7) ;
        IF @Retain > 0
        BEGIN
            SET @SQL = @SQL +
'

DELETE FROM ' + @Output + '
WHERE [Time] < CONVERT(DATETIMEOFFSET , DATEADD(DAY , -' + CONVERT(VARCHAR(5) , @Retain) + ' , CONVERT(DATE , GETDATE()))) ;
' ;
        END ;

        IF ISNULL(@Pretend , 0) = 1
            PRINT @SQL ;
        ELSE
            EXECUTE sp_executesql @SQL ;

        RETURN 0 ;
    END ;

    SET @Sample = ISNULL(@Sample , 30) ;
    
    IF @Sample < 10
        SET @Sample = 10 ;

    DECLARE @_database_text NVARCHAR(260) = 'DEFAULT' ;
    IF @Database IS NOT NULL AND @Database <> N''
        SET @_database_text = 'DB_ID(N''' + REPLACE(@Database , '''' , '''''') + N''')' ;

    SET @SQL = @SQL + 
'
DECLARE @_t_1 TABLE (
  [Database] NVARCHAR (128) ,
  [DatabaseID] INT ,
  [File] NVARCHAR(260) ,
  [FileID] INT ,
  [Sample] BIGINT ,
  [ReadBytes] BIGINT ,
  [WriteBytes] BIGINT ,
  [ReadCount] BIGINT ,
  [WriteCount] BIGINT ,
  [TotalWait] BIGINT ,
  [ReadWait] BIGINT ,
  [WriteWait] BIGINT
)
' ;

    SET @SQL = @SQL +
'
DECLARE @_t_2 TABLE (
  [Database] NVARCHAR (128) ,
  [DatabaseID] INT ,
  [File] NVARCHAR(260) ,
  [FileID] INT ,
  [Sample] BIGINT ,
  [ReadBytes] BIGINT ,
  [WriteBytes] BIGINT ,
  [ReadCount] BIGINT ,
  [WriteCount] BIGINT ,
  [TotalWait] BIGINT ,
  [ReadWait] BIGINT ,
  [WriteWait] BIGINT
)
' ;

    SET @SQL = @SQL + 
'
INSERT INTO @_t_1
SELECT     
    d.[name] [Database] ,
    d.[database_id] [DatabaseID] ,
    f.[physical_name] [File] ,
    f.[file_id] [FileID] ,
    s.[sample_ms] [Sample] ,
    s.[num_of_bytes_read] [ReadBytes] ,
    s.[num_of_bytes_written] [WriteBytes] ,
    s.[num_of_reads] [ReadCount] ,
    s.[num_of_writes] [WriteCount] ,
    s.[io_stall] [TotalWait] ,
    s.[io_stall_read_ms] [ReadWait] ,
    s.[io_stall_write_ms] [WriteWait]
FROM sys.dm_io_virtual_file_stats(' + @_database_text + ' , DEFAULT) s
INNER JOIN sys.master_files f ON s.database_id = f.[database_id] AND s.[file_id] = f.[file_id]
INNER JOIN sys.databases d ON d.[database_id] = s.[database_id]
' ;

    SET @SQL = @SQL +
'
WAITFOR DELAY ''' + SUBSTRING(CONVERT(VARCHAR(12), DATEADD(SECOND , @Sample , 0), 108) , 1 , 8) + '''
' ;

    SET @SQL = @SQL + 
'
INSERT INTO @_t_2
SELECT     
    d.[name] [Database] ,
    d.[database_id] [DatabaseID] ,
    f.[physical_name] [File] , 
    f.[file_id] [FileID] , 
    s.[sample_ms] [Sample] ,
    s.[num_of_bytes_read] [ReadBytes] , 
    s.[num_of_bytes_written] [WriteBytes] ,
    s.[num_of_reads] [ReadCount] ,
    s.[num_of_writes] [WriteCount] ,
    s.[io_stall] [TotalWait] , 
    s.[io_stall_read_ms] [ReadWait] ,
    s.[io_stall_write_ms] [WriteWait]
FROM sys.dm_io_virtual_file_stats(' + @_database_text + ' , DEFAULT) s
INNER JOIN sys.master_files f ON s.database_id = f.[database_id] AND s.[file_id] = f.[file_id]
INNER JOIN sys.databases d ON d.[database_id] = s.[database_id]
' ;

    DECLARE @_count_text NVARCHAR(10) = N' / 60.0' ;
    DECLARE @_count_read_title NVARCHAR(20) = N'[Reads [m]]]' ;
    DECLARE @_count_write_title NVARCHAR(20) = N'[Writes [m]]]' ;

    IF @CountPerSecond IS NOT NULL AND @CountPerSecond = 1
    BEGIN
        SET @_count_text = N'' ;
        SET @_count_read_title = N'[Reads [s]]]' ;
        SET @_count_write_title = N'[Writes [s]]]' ;
    END ;

    DECLARE @_sample_text NVARCHAR(50) ;
    SET @_sample_text = ' / ((b.[Sample] - a.[Sample]) / 1000.0)' ;

    SET @SQL = @SQL +
'SELECT
' ;

    IF @Now = 1
      SET @SQL = @SQL +
'    GETDATE() AS [Now]
    ,
' ;

    SET @SQL = @SQL +
'    a.[Database] , a.[File]
    ,
    CONVERT(DECIMAL(9,2) , (b.[ReadBytes] - a.[ReadBytes]) / 1024.0' + @_sample_text + ') [Read [KB/s]]]
    , 
    CONVERT(DECIMAL(9,2) , (b.[WriteBytes] - a.[WriteBytes]) / 1024.0' + @_sample_text + ') [Write [KB/s]]]
    , 
    CONVERT(INT , CEILING((b.[ReadCount] - a.[ReadCount])' + @_count_text + @_sample_text + ')) ' + @_count_read_title + '
    , 
    CONVERT(INT , CEILING((b.[WriteCount] - a.[WriteCount])' + @_count_text + @_sample_text + ')) ' + @_count_write_title + '
    ,
    CONVERT(DECIMAL(9,1) , (b.[TotalWait] - a.[TotalWait]) / 1000.0' + @_sample_text + ') [Total wait]
    ,
    CONVERT(DECIMAL(9,1) , (b.[ReadWait] - a.[ReadWait]) / 1000.0' + @_sample_text + ') [Read wait]
    ,
    CONVERT(DECIMAL(9,1) , (b.[WriteWait] - a.[WriteWait]) / 1000.0' + @_sample_text + ') [Write wait]
    , 
    f.[type_desc] [Type] , f.[state_desc] [State]
    ,
    CONVERT(DECIMAL(18,1) , 8.0 * f.[size] / 1024.0) [Size [MB]]]
FROM sys.master_files f
JOIN @_t_1 a ON f.[database_id] = a.[DatabaseID] AND f.[file_id] = a.[FileID]
JOIN @_t_2 b ON f.[database_id] = b.[DatabaseID] AND f.[file_id] = b.[FileID]
' ;

    IF ISNULL(@ActivityOnly , 0) = 1
    BEGIN
      SET @SQL = @SQL +
'WHERE 
    b.[ReadBytes] - a.[ReadBytes] > 0 OR
    b.[WriteBytes] - a.[WriteBytes] > 0 OR
    b.[ReadCount] - a.[ReadCount] > 0 OR
    b.[WriteCount] - a.[WriteCount] > 0 OR
    b.[TotalWait] - a.[TotalWait] > 50 OR
    b.[ReadWait] - a.[ReadWait] > 50 OR
    b.[WriteWait] - a.[WriteWait] > 50
' ;
    END ;

    IF @Pretend = 1
        PRINT @SQL ;
    ELSE
        EXECUTE sp_executesql @SQL ;

    RETURN 0 ;
END ;

GO

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

IF OBJECT_ID ( 'dbo.x_FindQuery' ) IS NULL
EXEC sp_executesql N'CREATE PROCEDURE dbo.x_FindQuery AS BEGIN RETURN 0 ; END' ;

GO

--
-- Find specific query in Query Store.
--
ALTER PROCEDURE dbo.x_FindQuery ( @Like NVARCHAR(MAX) = NULL , @Database NVARCHAR(128) = NULL
  , @Group BIT = NULL , @Top SMALLINT = NULL , @Now BIT = NULL
  , @Pretend BIT = 0 , @Help BIT = 0 )
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
        ( '@Like' , 'NVARCHAR(MAX)' , 'Query text filter for LIKE' )
        ,
        ( '@Database' , 'NVARCHAR(128)' , 'Database name' )
        ,
        ( '@Group' , 'BIT' , 'Group queries to show unique entries only' )
        ,
        ( '@Top' , 'BIT' , 'Limit report to maximum number of top records' )
        ,
        ( '@Now' , 'BIT' , 'Include column with current date and time' )
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
        ( 'Find query in Query Store.' )
        ,
        ( 'Search Query Store for specific query.' )
    ;
    SELECT [Description                                                                     ] = [Description] FROM @Description ;

    RETURN 0 ;
  END ;

  IF ISNULL(@Like , '') = ''
  BEGIN
    RAISERROR ( 'Parameter @Like must be not empty. Use @Help=1 to see options.' , 18 , 1 ) ;
    RETURN -1 ;
  END ;

  DECLARE @SQL NVARCHAR(MAX) = '' ;

  IF @Database <> ''
  BEGIN
    SET @SQL = @SQL + 'USE ' ;
    SET @SQL = @SQL + CASE WHEN SUBSTRING(@Database , 1 , 1) = '[' THEN @Database ELSE QUOTENAME(@Database) END ;
    SET @SQL = @SQL + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) ;
  END ;

  SET @SQL = @SQL + 'SELECT' ;

  IF @Top > 0 SET @SQL = @SQL + ' TOP(' + CONVERT(VARCHAR , @Top) + ')' ;

  IF @Now = 1
    SET @SQL = @SQL + '
  GETDATE() as [now] ,' ;

  IF @Group = 1
  BEGIN
    SET @SQL = @SQL + '
  q.query_id , MAX(q.last_execution_time) AS last_execution_time , t.query_sql_text
FROM sys.query_store_query q
INNER JOIN sys.query_store_query_text t
  ON q.query_text_id = t.query_text_id
WHERE
  t.query_sql_text LIKE ' ;
  END
  ELSE
  BEGIN
    SET @SQL = @SQL + '
  q.query_id , q.last_execution_time , t.query_sql_text
FROM sys.query_store_query q
INNER JOIN sys.query_store_query_text t
  ON q.query_text_id = t.query_text_id
WHERE
  t.query_sql_text LIKE ' ;
  END ;
  
  SET @SQL = @SQL + 'N''' + REPLACE(@Like , '''' , '''''') + '''' ;
  
  SET @SQL = @SQL + CHAR(13) + CHAR(10) ;

  IF @Group = 1
  BEGIN
    SET @SQL = @SQL +
'GROUP BY
  q.query_id , t.query_sql_text
ORDER BY
  MAX(q.last_execution_time) DESC
' ;
  END
  ELSE
  BEGIN
    SET @SQL = @SQL +
'ORDER BY
  q.last_execution_time DESC
' ;
  END ;

  IF @Pretend = 1
    PRINT @SQL ;
  ELSE
    EXECUTE sp_executesql @SQL ;

  RETURN 0 ;
END ;

GO

IF OBJECT_ID ( 'dbo.x_IdentitySeed' ) IS NULL
EXEC sp_executesql N'CREATE PROCEDURE dbo.x_IdentitySeed AS BEGIN RETURN 0 ; END' ;

GO

--
-- Show identity seed value for tables in database.
--
-- Generate report for all tables and identity column seed value together
-- with DBCC CHECKIDENT ( '[table]' , RESEED , 434342 ) script pattern to recreate it manually.
--
ALTER PROCEDURE dbo.x_IdentitySeed ( @Database NVARCHAR(128) = NULL , @Table NVARCHAR(128) = NULL , @Schema NVARCHAR(128) = NULL
  , @Operation BIT = 1 , @Plus BIT = 1
  , @Pretend BIT = 0 , @Help BIT = 0 )
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

    RETURN 0 ;
  END

  DECLARE @SQL NVARCHAR(2000) = '' ;
  DECLARE @SQL_1 NVARCHAR(2000) = '' ;

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

  IF @Database <> ''
  BEGIN
    SET @SQL = ''
      + 'USE '
      + CASE WHEN SUBSTRING(@Database , 1 , 1) = '[' THEN @Database ELSE QUOTENAME(@Database) END
      + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) 
      + @SQL 
      ;
  END

  IF @Plus = 1
  BEGIN
      SET @SQL = REPLACE(@SQL , '[Schema]' , '[Schema         +]') ;
      SET @SQL = REPLACE(@SQL , '[Table]' , '[Table                                        +]') ;
      SET @SQL = REPLACE(@SQL , '[Count]' , '[Count               +]') ;
      SET @SQL = REPLACE(@SQL , '[Seed]' , '[Seed                +]') ;
  END

  IF @Pretend = 1
    PRINT @SQL ;
  ELSE
    EXECUTE sp_executesql @SQL ;

  -- Generate DBCC scripts

  IF @Operation = 1
  BEGIN
    SET @SQL = '' ;

    IF @Database <> ''
    BEGIN
      SET @SQL = @SQL + 'USE ' ;
      SET @SQL = @SQL + CASE WHEN SUBSTRING(@Database , 1 , 1) = '[' THEN @Database ELSE QUOTENAME(@Database) END ;
      SET @SQL = @SQL + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) ;
    END ;

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
  SET @sql = ''DBCC CHECKIDENT ( '''''' + REPLACE(@_name , '''''''' , '''''''''''') + '''''' , RESEED , '' + CONVERT(VARCHAR(18) , @_seed) + '' )'' ;
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

    IF @Pretend = 1
    BEGIN
      PRINT CHAR(13) + CHAR(10) + '----------------------------------------' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) ;
      PRINT @SQL ;
    END
    ELSE
      EXECUTE sp_executesql @SQL ;
  END

  RETURN 0 ;
END

GO

IF OBJECT_ID ( 'dbo.x_OperationStatus' ) IS NULL
EXEC sp_executesql N'CREATE PROCEDURE dbo.x_OperationStatus AS BEGIN RETURN 0; END' ;

GO

--
-- Show system operation status.
--
-- Simply display what database server is doing now.
--
ALTER PROCEDURE dbo.x_OperationStatus ( @Now BIT = NULL , @Pretend BIT = 0 , @Help BIT = 0 )
AS
BEGIN
    IF @Help = 1
    BEGIN
        DECLARE @Parameter TABLE
        (
            [Parameter] NVARCHAR(10) ,
            [Type] NVARCHAR(20) ,
            [Description] NVARCHAR(200)
        ) ;
        INSERT INTO @Parameter ( [Parameter] , [Type] , [Description] )
        VALUES
            ( '@Now' , 'BIT' , 'Include column with current date and time' )
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
            ( 'Show system operation status.' ) 
            ,
            ( 'Simply display what database server is doing now.' ) 
            ;
        SELECT [Description                                                                     ] = [Description] FROM @Description ;
        
        RETURN;
    END ;

    DECLARE @SQL NVARCHAR(2000) = '' ;

    SET @SQL = @SQL +
'SELECT
' ;

    IF @Now = 1
        SET @SQL = @SQL +
'    [Now] = GETDATE()
    ,
' ;

    SET @SQL = @SQL +
'    [Database] = DB_NAME(R.database_id)
    ,
    [Command] = R.command
    ,
    [Status] = R.status
    ,
    [%] = CONVERT(DECIMAL(9, 2) , R.percent_complete)
    ,
    [Wait type] = R.wait_type
    ,
    [Start time] = R.start_time
    ,
    [Reads] = R.reads
    ,
    [Writes] = R.writes
    ,
    [Time taken] = CONVERT(VARCHAR , R.total_elapsed_time / 60000) + '':'' + RIGHT(''00'' + CONVERT(VARCHAR , CONVERT(INT , R.total_elapsed_time / 1000 % 60)) , 2)
    ,
    [CPU time] = CONVERT(VARCHAR , R.cpu_time / 60000) + '':'' + RIGHT(''00'' + CONVERT(VARCHAR , CONVERT(INT , R.cpu_time / 1000 % 60)) , 2)
    ,
    [Time left] = CONVERT(VARCHAR , R.estimated_completion_time / 60000) + '':'' + RIGHT(''00'' + CONVERT(VARCHAR , CONVERT(INT , R.estimated_completion_time / 1000 % 60)) , 2)
    ,
    [Session] = R.session_id
    ,
    [Host] = S.[host_name]
    ,
    [Operation                                                                                                               ] = T.text
FROM sys.dm_exec_requests R
CROSS APPLY sys.dm_exec_sql_text(R.sql_handle) T
LEFT JOIN sys.dm_exec_sessions S ON S.session_id = R.session_id
WHERE R.session_id <> @@SPID
ORDER BY R.command
' ;

    IF @Pretend = 1
        PRINT @SQL ;
    ELSE
        EXECUTE sp_executesql @SQL ;

    RETURN 0 ;
END ;

GO

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

IF OBJECT_ID ( 'dbo.x_SessionStatus' ) IS NULL
EXEC sp_executesql N'CREATE PROCEDURE dbo.x_SessionStatus AS BEGIN RETURN 0 ; END' ;

GO

--
-- Show current active sessions with information about state and transaction isolation level.
--
ALTER PROCEDURE dbo.x_SessionStatus ( @Database NVARCHAR(128) = NULL , @SPID BIGINT = -1
  , @Host NVARCHAR(128) = NULL
  , @Now BIT = NULL
  , @Pretend BIT = 0 , @Help BIT = 0 )
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
        ( '@Database' , 'NVARCHAR(128)' , 'Database name' )
        ,
        ( '@Host' , 'NVARCHAR(128)' , 'Filter results by host. Set to ''+'' to include only remote sessions. Set to ''-'' to include only local sessions.' )
        ,
        ( '@Now' , 'BIT' , 'Include column with current date and time' )
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
        ( 'Show current active sessions with information about state and transaction isolation level.' )
    ;
    SELECT [Description                                                                     ] = [Description] FROM @Description ;

    RETURN 0 ;
  END ;

  IF @Host IS NULL 
    SET @Host = '' ;

  IF ISNULL(@SPID , 0) =  0
  BEGIN
    SET @SPID = @@SPID ;
  END ;

  DECLARE @SQL NVARCHAR(MAX) = '' ;

  IF @Database <> ''
  BEGIN
    SET @SQL = @SQL + 'USE ' ;
    SET @SQL = @SQL + CASE WHEN SUBSTRING(@Database , 1 , 1) = '[' THEN @Database ELSE QUOTENAME(@Database) END ;
    SET @SQL = @SQL + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) ;
  END ;

  SET @SQL = @SQL +
'SELECT
' ;

  IF @Now = 1
    SET @SQL = @SQL +
'  GETDATE() AS [Now] ,
' ;

  SET @SQL = @SQL + 
'  session_id AS [SESSION] ,
  UPPER(status) AS [STATUS] ,
  DB_NAME(database_id) AS [DATABASE] ,
  host_name AS [HOST] ,
  CASE transaction_isolation_level
    WHEN 0 THEN ''UNSPECIFIED''
    WHEN 1 THEN ''READ UNCOMMIITTED''
    WHEN 2 THEN ''READ COMMITTED''
    WHEN 3 THEN ''REPEATABLE''
    WHEN 4 THEN ''SERIALIZABLE''
    WHEN 5 THEN ''SNAPSHOT'' 
  END
    AS [ISOLATION]
FROM sys.dm_exec_sessions
' ;

  DECLARE @has_where BIT ;
  SET @has_where = 0 ;

  IF @SPID > 0
  BEGIN

    IF @has_where = 1
      SET @SQL = @SQL + 'AND ' ;
    ELSE
    BEGIN
      SET @SQL = @SQL + 'WHERE ' ;
      SET @has_where = 1 ;
    END

    SET @SQL = @SQL + 'session_id = ' ;
  
    SET @SQL = @SQL + CONVERT(VARCHAR , @SPID) ;
  
    SET @SQL = @SQL + CHAR(13) + CHAR(10) ;

  END ;

  IF @Host IS NOT NULL AND @Host <> '' AND @Host <> '*'
  BEGIN

    IF @has_where = 1
      SET @SQL = @SQL + 'AND ' ;
    ELSE
    BEGIN
      SET @SQL = @SQL + 'WHERE ' ;
      SET @has_where = 1 ;
    END ;

    IF @Host = '-'
      SET @SQL = @SQL + 'host_name IS NULL ' ;
  
    IF @Host = '+'
      SET @SQL = @SQL + 'host_name IS NOT NULL ' ;
  
    IF CHARINDEX(@Host , '-+') = 0
    BEGIN
      
      SET @SQL = @SQL + 'host_name LIKE N''' ;
      SET @SQL = @SQL + REPLACE(@Host , '''' , '''''') ;
      SET @SQL = @SQL + '''' ;
      
      SET @SQL = @SQL + CHAR(13) + CHAR(10) ;
    END ;

  END ;


  IF @Database IS NOT NULL AND @Database <> '' AND @Database <> '*'
  BEGIN

    IF @has_where = 1
      SET @SQL = @SQL + 'AND ' ;
    ELSE
    BEGIN
      SET @SQL = @SQL + 'WHERE ' ;
      SET @has_where = 1 ;
    END ;

    SET @SQL = @SQL + 'DB_NAME(database_id) LIKE N''' ;
    SET @SQL = @SQL + REPLACE(@Database , '''' , '''''') ;
    SET @SQL = @SQL + '''' ;
    
    SET @SQL = @SQL + CHAR(13) + CHAR(10) ;

  END ;

  IF @SPID < 0
  BEGIN

    SET @SQL = @SQL + 
'ORDER BY session_id
' ;

  END ;

  IF @Pretend = 1
    PRINT @SQL ;
  ELSE
    EXECUTE sp_executesql @SQL ;

  RETURN 0 ;
END ;

GO

IF OBJECT_ID ( 'dbo.x_ShowIndex' ) IS NULL
EXEC sp_executesql N'CREATE PROCEDURE dbo.x_ShowIndex AS BEGIN RETURN 0; END' ;

GO

--
-- Show indexes and optionally columns included for one or more tables.
--
ALTER PROCEDURE dbo.x_ShowIndex ( @Database NVARCHAR(128) = NULL , @Table NVARCHAR(128) = NULL , @Schema NVARCHAR(128) = NULL , @Expand BIT = NULL , @Clustered BIT = NULL , @Unique BIT = NULL , @Primary BIT = NULL , @Pretend BIT = 0 , @Help BIT = 0 )
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
        ) ;
        INSERT INTO @Parameter ( [Parameter] , [Type] , [Description] )
        VALUES
            ( '@Database' , 'NVARCHAR(128)' , 'Database name' )
            ,
            ( '@Schema' , 'NVARCHAR(128)' , 'Schema name' )
            ,
            ( '@Table' , 'NVARCHAR(128)' , 'Table name' )
            ,
            ( '@Expand' , 'BIT' , 'Show index columns' )
            ,
            ( '@Clustered' , 'BIT' , 'Show clustered (1) or non-clustered (0) indexes' )
            ,
            ( '@Unique' , 'BIT' , 'Show unique (1) or non-unique (0) indexes' )
            ,
            ( '@Primary' , 'BIT' , 'Show primary (1) or non-primary (0) indexes' )
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
            ( 'Show indexes and optionally columns included for one or more tables.' )
        ;
        SELECT [Description                                                                     ] = [Description] FROM @Description ;
  
        RETURN 0 ;
    END ;

    DECLARE @SQL NVARCHAR(2000) = '' ;

    IF @Database IS NOT NULL
        SET @SQL = @SQL + 'USE ' + QUOTENAME(@Database) + CHAR(13) + CHAR(10) ;

    SET @SQL = @SQL +
'SELECT
    [Schema] = s.name , [Table] = t.name , [Index] = i.name' ;

    IF @Expand IS NOT NULL AND @Expand = 1
      SET @SQL = @SQL + ' , [Column] = c.name';

    SET @SQL = @SQL +
'
    ,
    [Clustered] = CASE WHEN i.index_id = 1 THEN 1 ELSE 0 END
    ,
    [Unique] = i.is_unique
    ,
    [Primary] = i.is_primary_key
FROM
    sys.tables t
INNER JOIN 
    sys.indexes i ON t.object_id = i.object_id
INNER JOIN
    sys.schemas s ON t.schema_id = s.schema_id
' ;

    IF @Expand IS NOT NULL AND @Expand = 1
      SET @SQL = @SQL + 
'INNER JOIN 
    sys.index_columns ic ON i.index_id = ic.index_id AND i.object_id = ic.object_id
INNER JOIN 
    sys.columns c ON ic.column_id = c.column_id AND ic.object_id = c.object_id
' ;

    SET @SQL = @SQL + 
'WHERE
    i.name IS NOT NULL
' ;

    IF @Schema IS NOT NULL AND @Schema <> ''
        SET @SQL = @SQL + 'AND
    s.name = N' + QUOTENAME(@Schema , '''') + CHAR(13) + CHAR(10) ;
    IF @Table IS NOT NULL AND @Table <> ''
        SET @SQL = @SQL + 'AND
    t.name = N' + QUOTENAME(@Table , '''') + CHAR(13) + CHAR(10) ;
    IF @Clustered IS NOT NULL
    BEGIN
        IF @Clustered = 1
            SET @SQL = @SQL + 'AND
    i.index_id = 1' + CHAR(13) + CHAR(10) ;
        ELSE
            SET @SQL = @SQL + 'AND
    i.index_id <> 1' + CHAR(13) + CHAR(10) ;
    END ;
    IF @Unique IS NOT NULL
        SET @SQL = @SQL + 'AND
    i.is_unique = ' + CONVERT(CHAR , @Unique) + CHAR(13) + CHAR(10) ;
    IF @Primary IS NOT NULL
        SET @SQL = @SQL + 'AND
    i.is_primary_key = ' + CONVERT(CHAR , @Primary) + CHAR(13) + CHAR(10) ;

    SET @SQL = @SQL + 'ORDER BY' + CHAR(13) + CHAR(10) + '    s.name , t.name , i.name'

    IF @Pretend = 1
        PRINT @SQL ;
    ELSE
        EXECUTE sp_executesql @SQL ;

    RETURN 0;
END

GO

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

IF OBJECT_ID ( 'dbo.x_SystemMemory' ) IS NULL
EXEC sp_executesql N'CREATE PROCEDURE dbo.x_SystemMemory AS BEGIN RETURN 0; END' ;

GO

--
-- Show basic information about memory amount and state.
--
ALTER PROCEDURE dbo.x_SystemMemory ( @Pretend BIT = 0 , @Help BIT = 0 )
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
        
        RETURN ;
    END ;

    DECLARE @SQL NVARCHAR(2000) = '' ;

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
' ;

    IF @Pretend = 1
        PRINT @SQL ;
    ELSE
        EXECUTE sp_executesql @SQL ;

    RETURN 0 ;
END

GO

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
