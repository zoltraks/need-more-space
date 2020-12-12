
--
-- Insert data
--

INSERT INTO "Contact" ( "FirstName" , "SecondName" , "LastName" , "Title" )
SELECT 'Joe' , '' , 'Doe' , ''
WHERE NOT EXISTS (
  SELECT 1 FROM "Contact" WHERE "FirstName" = 'Joe' AND "SecondName" = '' AND "LastName" = 'Doe'
) ;

INSERT INTO "Contact" ( "FirstName" , "SecondName" , "LastName" , "Title" )
SELECT 'Amy' , '' , '' , ''
WHERE NOT EXISTS (
  SELECT 1 FROM "Contact" WHERE "FirstName" = 'Amy' AND "SecondName" = '' AND "LastName" = ''
) ;

INSERT INTO "Contact" ( "FirstName" , "SecondName" , "LastName" , "Title" )
SELECT 'Bob' , '' , '' , ''
WHERE NOT EXISTS (
  SELECT 1 FROM "Contact" WHERE "FirstName" = 'Bob' AND "SecondName" = '' AND "LastName" = ''
) ;
