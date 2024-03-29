IF OBJECT_ID('dbo.EXTREME_EVERY_TYPE' , 'U') IS NULL
CREATE TABLE dbo.EXTREME_EVERY_TYPE
(
  _ INT IDENTITY(1,1) ,

  -- Exact numerics --

  _BIT_ BIT NULL ,
  _INT_ INT NULL ,
  _SMALLINT_ SMALLINT NULL ,
  _TINYINT_ TINYINT NULL ,
  _BIGINT_ BIGINT NULL ,
  _DECIMAL_ DECIMAL NULL ,
  _DECIMAL_10 DECIMAL(10) NULL ,
  _DECIMAL_18_4 DECIMAL(18 , 4) NULL ,
  _DECIMAL_38_18 DECIMAL(38 , 18) NULL ,
  _NUMERIC_ NUMERIC NULL ,
  _NUMERIC_38 NUMERIC(38) NULL ,
  _NUMERIC_38_18 NUMERIC(38,18) NULL ,
  _MONEY_ MONEY NULL ,
  _SMALLMONEY_ SMALLMONEY NULL ,

  -- Approximate numerics --

  _FLOAT_ FLOAT NULL ,
  _FLOAT_1 FLOAT(1) NULL ,
  _FLOAT_23 FLOAT(23) NULL ,
  _FLOAT_24 FLOAT(24) NULL ,
  _FLOAT_25 FLOAT(25) NULL ,
  _REAL_ REAL NULL ,
  _DOUBLE_PRECISION_ DOUBLE PRECISION NULL ,

  -- Date and time --

  _DATETIME_ DATETIME NULL ,
  _DATETIME2_ DATETIME2 NULL ,
  _DATETIME2_0 DATETIME2(0) NULL ,
  _DATETIME2_3 DATETIME2(3) NULL ,
  _SMALLDATETIME_ SMALLDATETIME NULL ,
  _TIME_ TIME NULL ,
  _TIME_0 TIME(0) NULL ,
  _TIME_3 TIME(3) NULL ,
  _DATETIMEOFFSET_ DATETIMEOFFSET NULL ,
  _DATETIMEOFFSET_3 DATETIMEOFFSET(3) NULL ,
  _TIMESTAMP_ TIMESTAMP NULL ,

  -- Character strings --

  _CHAR_ CHAR NULL ,
  _CHAR_3 CHAR(3) NULL ,
  _VARCHAR_ VARCHAR NULL ,
  _VARCHAR_1 VARCHAR(1) NULL ,
  _VARCHAR_MAX VARCHAR(MAX) NULL ,
  _TEXT_ TEXT NULL ,
  
  -- Unicode character strings --

  _NCHAR_ NCHAR NULL ,
  _NCHAR_3 NCHAR(3) NULL ,
  _NVARCHAR_ NVARCHAR NULL ,
  _NVARCHAR_1 NVARCHAR(1) NULL ,
  _NVARCHAR_MAX NVARCHAR(MAX) NULL ,
  _NTEXT_ NTEXT NULL ,
  
  -- Other data types --

  _BINARY_ BINARY NULL ,
  _BINARY_3 BINARY(3) NULL ,
  _VARBINARY_ VARBINARY NULL ,
  _VARBINARY_3 VARBINARY(3) NULL ,
  _VARBINARY_MAX VARBINARY(MAX) NULL ,
  _IMAGE_ IMAGE NULL ,
  _UNIQUEIDENTIFIER_ UNIQUEIDENTIFIER NULL ,
  _XML_ XML NULL ,
  _HIERARCHYID_ HIERARCHYID NULL ,
  _GEOMETRY_ GEOMETRY NULL ,
  _GEOGRAPHY_ GEOGRAPHY NULL ,

  _SQL_VARIANT_ SQL_VARIANT NULL ,

  _SYSNAME_ SYSNAME NULL ,

  CONSTRAINT PK_EXTREME_EVERY_TYPE PRIMARY KEY CLUSTERED (_)
)
;
