
SELECT '' [ ]
UNION ALL
SELECT ''
UNION ALL
SELECT N'.    ┌─────────────────────────────────────┐    .'
UNION ALL
SELECT N':    │                                     │    :'
UNION ALL 
SELECT N':    │   ENABLE "RESULT TO TEXT" OPTION    │    :'
UNION ALL
SELECT N':    │                                     │    :'
UNION ALL
SELECT N':    │              (CTRL+T)               │    :'
UNION ALL
SELECT N':    │                                     │    :'
UNION ALL
SELECT N'''    └─────────────────────────────────────┘    '''
UNION ALL
SELECT ''
UNION ALL
SELECT ''

GO

WAITFOR DELAY '00:00:01' ;

GO

-- PART X --

SET NOCOUNT ON ;


DECLARE @N INT ;
DECLARE @M INT ;

DECLARE @I INT ;
DECLARE @K INT ;

DECLARE @L NVARCHAR(MAX) ;

SET @N = 0 ;
SET @M = 50 ;

SET @L = '' ;
WHILE @N < @M BEGIN SET @N = @N + 1 ; SET @L = @L + CHAR(13) + CHAR(10) ; END ;

RAISERROR( @L , 0 , 1) WITH NOWAIT ;
WAITFOR DELAY '00:00:01' ;





DECLARE @CHARS TABLE
(
_ int not null identity(1,1) , c char(1) , t nvarchar(10)
) ;
INSERT INTO @CHARS ( c , t ) VALUES ('' , '')
, ( ' ' , N'       ' )
, ( ' ' , N'       ' )
, ( ' ' , N'       ' )
, ( NULL , '' )
, ( 'A' , N'  ┌───┐' )
, ( 'A' , N' ┌────┤' )
, ( 'A' , N'┌┘    │' )
, ( 'A' , N'└┐    │' )
, ( 'A' , N' └────┘' )
, ( NULL , '' )
, ( 'B' , N'┌───┐  ' )
, ( 'B' , N'│   │  ' )
, ( 'B' , N'├───┴─┐' )
, ( 'B' , N'│     │' )
, ( 'B' , N'└─────┘' )
, ( NULL , '' )
, ( 'C' , N' ┌───┐ ' )
, ( 'C' , N'┌┘     ' )
, ( 'C' , N'│      ' )
, ( 'C' , N'└┐     ' )
, ( 'C' , N' └───┘ ' )
, ( NULL , '' )
, ( 'H' , N'┌──   ' )
, ( 'H' , N'│     ' )
, ( 'H' , N'├────┐' )
, ( 'H' , N'│    │' )
, ( 'H' , N'└    ┘' )
, ( NULL , '' )
, ( 'E' , N' ┌───┐ ' )
, ( 'E' , N'┌┘   │ ' )
, ( 'E' , N'├────┘ ' )
, ( 'E' , N'└┐     ' )
, ( 'E' , N' └───┘ ' )
, ( NULL , '' )
, ( 'L' , N' ─┐  ' )
, ( 'L' , N'  │  ' )
, ( 'L' , N'  │  ' )
, ( 'L' , N'  │  ' )
, ( 'L' , N'──┴──' )
, ( NULL , '' )
, ( 'O' , N' ┌───┐ ' )
, ( 'O' , N'┌┘   └┐' )
, ( 'O' , N'│     │' )
, ( 'O' , N'└┐   ┌┘' )
, ( 'O' , N' └───┘ ' )
, ( NULL , '' )
, ( 'V' , N'└┐     ┌┘' )
, ( 'V' , N' └┐   ┌┘' )
, ( 'V' , N'  └┐ ┌┘' )
, ( 'V' , N'   └─┘' )
, ( NULL , '' )
, ( 'R' , N' ┌───┐ ' )
, ( 'R' , N' │     ' )
, ( 'R' , N' │     ' )
, ( 'R' , N' │     ' )
, ( NULL , '' )
, ( 'Y' , N'└┐   ┌┘' )
, ( 'Y' , N' └┐ ┌┘' )
, ( 'Y' , N'  └┬┘' )
, ( 'Y' , N'  ┌┘' )
, ( 'Y' , N' ─┘' )
, ( NULL , '' )
, ( 'D' , N'     │' )
, ( 'D' , N'     │' )
, ( 'D' , N' ┌───┤' )
, ( 'D' , N'┌┘   │' )
, ( 'D' , N'│    │' )
, ( 'D' , N'└┐   │' )
, ( 'D' , N' └───┘' )
, ( NULL , '' )
, ( 'N' , N'┌────┐ ' )
, ( 'N' , N'│    └┐' )
, ( 'N' , N'│     │' )
, ( 'N' , N'│     │ ' )
, ( NULL , '' )
, ( 'W' , N'│      │' )
, ( 'W' , N'│  ┌┐  │' )
, ( 'W' , N'└┐┌┘└┐┌┘' )
, ( 'W' , N' └┘  └┘' )
, ( NULL , '' )
, ( 'M' , N'┌──┬──┐' )
, ( 'M' , N'│  └┐ └┐' )
, ( 'M' , N'│   │  │' )
, ( 'M' , N'│      │ ' )
, ( NULL , '' )
, ( 'T' , N'  │  ' )
, ( 'T' , N'──┼──' )
, ( 'T' , N'  │  ' )
, ( 'T' , N'  │  ' )
, ( 'T' , N'  └─┘' )
, ( NULL , '' )
, ( 'S' , N' ┌───┐ ' )
, ( 'S' , N'┌┘   └┐' )
, ( 'S' , N'└──┐   ' )
, ( 'S' , N'   └──┐' )
, ( 'S' , N'└┐   ┌┘' )
, ( 'S' , N' └───┘ ' )
, ( NULL , '' )
, ( 'Q' , N' ┌───┐' )
, ( 'Q' , N'┌┘   │' )
, ( 'Q' , N'│    │' )
, ( 'Q' , N'└┐   │' )
, ( 'Q' , N' └───┤' )
, ( 'Q' , N'     │' )
, ( 'Q' , N'     │' )
, ( NULL , '' )
, ( 'I' , N' ┌┐  ' )
, ( 'I' , N' └┘  ' )
, ( 'I' , N' ─┐  ' )
, ( 'I' , N'  │  ' )
, ( 'I' , N'  │  ' )
, ( 'I' , N'──┴──' )
, ( NULL , '' )
, ( 'P' , N'┌────┐ ' )
, ( 'P' , N'│    └┐' )
, ( 'P' , N'│     │' )
, ( 'P' , N'│    ┌┘' )
, ( 'P' , N'├────┘ ' )
, ( 'P' , N'│' )
, ( NULL , '' )
, ( 'G' , N' ┌───┐' )
, ( 'G' , N'┌┘   │' )
, ( 'G' , N'│    │' )
, ( 'G' , N'└┐   │' )
, ( 'G' , N' └───┤' )
, ( 'G' , N'     │' )
, ( 'G' , N' └───┘' )
, ( NULL , '' )
, ( 'K' , N'│    ' )
, ( 'K' , N'│   ┌' )
, ( 'K' , N'├──┬┘' )
, ( 'K' , N'│  └┐' )
, ( 'K' , N'    └' )
, ( NULL , '' )
, ( 'Z' , N' ┌───┐' )
, ( 'Z' , N'    ┌┘' )
, ( 'Z' , N'   ┌┘ ' )
, ( 'Z' , N'  ┌┘  ' )
, ( 'Z' , N' ┌┘   ' )
, ( 'Z' , N' └───┘' )
, ( NULL , '' )
, ( 'F' , N'  ┌──' )
, ( 'F' , N'  │  ' )
, ( 'F' , N'──┼──' )
, ( 'F' , N'  │  ' )
, ( 'F' , N'  │  ' )
, ( 'F' , N'  │  ' )
, ( NULL , '' )
, ( 'U' , N'│     │' )
, ( 'U' , N'│     │' )
, ( 'U' , N'└┐   ┌┘' )
, ( 'U' , N' └───┘ ' )
, ( NULL , '' )
, ( '?' , N' ┌──┐ ' )
, ( '?' , N'┌┘  └┐' )
, ( '?' , N'    ┌┘' )
, ( '?' , N'   ┌┘ ' )
, ( '?' , N'   │  ' )
, ( '?' , N'  ┌┐  ' )
, ( '?' , N'  └┘  ' )
;

DECLARE @textLeft NVARCHAR(MAX) ;

DECLARE @textLeftCount INT ;
DECLARE @textLeftIndex INT ;
DECLARE @textLeftCharacter CHAR(1) ;
DECLARE @textLeftHeight INT ;
DECLARE @textLeftOffset INT ;
DECLARE @textLeftLine NVARCHAR(MAX) ;

SET @textLeft = ''
+CHAR(32)+CHAR(72)+CHAR(69)+CHAR(76)+CHAR(76)+CHAR(79)+CHAR(32)+CHAR(124)+CHAR(87)+CHAR(79)+CHAR(82)+CHAR(76)+CHAR(68)+CHAR(32)+CHAR(124)
+CHAR(65)+CHAR(78)+CHAR(68)+CHAR(32)+CHAR(124)+CHAR(87)+CHAR(69)+CHAR(76)+CHAR(67)+CHAR(79)+CHAR(77)+CHAR(69)+CHAR(32)+CHAR(124)+CHAR(84)+CHAR(79)
+CHAR(32)+CHAR(124)+CHAR(80)+CHAR(82)+CHAR(79)+CHAR(71)+CHAR(82)+CHAR(65)+CHAR(77)+CHAR(32)+CHAR(124)+CHAR(67)+CHAR(65)+CHAR(76)+CHAR(76)+CHAR(69)+CHAR(68)
+CHAR(32)+CHAR(124)+CHAR(83)+CHAR(81)+CHAR(76)+CHAR(86)+CHAR(69)+CHAR(83)+CHAR(89)+CHAR(78)+CHAR(32)+CHAR(124)+CHAR(87)+CHAR(72)+CHAR(69)+CHAR(82)+CHAR(69)
+CHAR(32)+CHAR(124)+CHAR(68)+CHAR(79)+CHAR(32)+CHAR(124)+CHAR(89)+CHAR(79)+CHAR(85)+CHAR(32)+CHAR(124)+CHAR(87)+CHAR(65)+CHAR(78)+CHAR(84)+CHAR(32)
+CHAR(124)+CHAR(84)+CHAR(79)+CHAR(32)+CHAR(124)+CHAR(71)+CHAR(79)+CHAR(124)+CHAR(63)+CHAR(32)+CHAR(124)+CHAR(80)+CHAR(82)+CHAR(79)+CHAR(71)+CHAR(82)
+CHAR(65)+CHAR(77)+CHAR(77)+CHAR(69)+CHAR(68)+CHAR(32)+CHAR(124)+CHAR(66)+CHAR(89)+CHAR(32)+CHAR(124)+CHAR(90)+CHAR(79)+CHAR(76)+CHAR(84)+CHAR(82)+CHAR(65)
+CHAR(75)+CHAR(83)+CHAR(32)+CHAR(124)+CHAR(84)+CHAR(65)+CHAR(75)+CHAR(69)+CHAR(32)+CHAR(124)+CHAR(67)+CHAR(65)+CHAR(82)+CHAR(69)+CHAR(32)+CHAR(124)
;

SET @textLeftCount = LEN(@textLeft) ;
SET @textLeftIndex = 1 ;



SET @N = 0 ;
SET @M = 0 ;

DECLARE @S NVARCHAR(MAX) ;

DECLARE @A FLOAT ;
DECLARE @B FLOAT ;
DECLARE @V FLOAT ;
DECLARE @X INT ;
DECLARE @Y INT ;

DECLARE @PAUSE NVARCHAR(MAX) ;

SET @N = 0 ;
SET @M = 500 - 15 ;

WHILE @N < @M
BEGIN
  SET @N = @N + 1 ;

  SET @A = 15.0 ;
  --SET @A = @A + 0.3 * (@N % 10) ;
  SET @B = 0.1 + 0.0005 * (@N / 10 % 10) ;
  SET @V = @A + @A * COS(-PI() + @N * @B) ;

  SET @Y = 1 + @V ;
  SET @X = 40 - @Y ;

  SET @S = '' ;
  SET @I = 0 ; WHILE @I < @X BEGIN SET @I = @I + 1 ; SET @S = @S + ' ' ; END ; 
  SET @I = 0 ; WHILE @I < @Y + @Y BEGIN SET @I = @I + 1 ; SET @S = @S + '*' ; END ; 

  SET @textLeftLine = NULL ;

  IF @textLeftIndex <= @textLeftCount OR @textLeftCharacter IS NOT NULL
  BEGIN



  IF @textLeftCharacter IS NULL
  BEGIN
    WHILE 1=1
    BEGIN
      SET @textLeftCharacter = SUBSTRING(@textLeft , @textLeftIndex , 1 ) ;
      IF @textLeftCharacter = '|'
      BEGIN
        SET @PAUSE = 'WAITFOR DELAY ''00:00:00.777''' ;
      END ;
      SET @textLeftIndex = @textLeftIndex + 1 ;
      IF EXISTS ( SELECT TOP(1) 1 FROM @CHARS WHERE c = @textLeftCharacter )
        BREAK ;
      IF @textLeftIndex > @textLeftCount 
      BEGIN
        SET @textLeftCharacter = NULL ;
        BREAK ;
      END ;
    END ;

    SET @textLeftHeight = ( SELECT MAX(_) FROM @CHARS WHERE c = @textLeftCharacter ) ;
    SET @textLeftOffset = ( SELECT MIN(_) FROM @CHARS WHERE c = @textLeftCharacter ) ;
  END ;

  IF @textLeftOffset <= @textLeftHeight
  BEGIN
    SET @textLeftLine = ( SELECT t FROM @CHARS WHERE _ = @textLeftOffset ) ;
    SET @textLeftOffset = @textLeftOffset + 1 ;
  END ;

  IF @textLeftOffset > @textLeftHeight
  BEGIN
    SET @textLeftCharacter = NULL ;
  END ;

  END ;

  SET @textLeftLine = '         ' + LEFT(ISNULL(@textLeftLine , '') + '          ', 8) + '        ' ;

  SET @S = @textLeftLine + @S ;

  -- PAUSE --
  
  IF @PAUSE IS NOT NULL
  BEGIN
    EXEC sp_executesql @PAUSE ;
    SET @PAUSE = NULL ;
  END ;

  -- RENDER --

  RAISERROR( @S , 0 , 1) WITH NOWAIT ;

  WAITFOR DELAY '00:00:00.039' ;
END ;

GO

