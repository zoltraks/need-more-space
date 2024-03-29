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
