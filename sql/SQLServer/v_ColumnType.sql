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
