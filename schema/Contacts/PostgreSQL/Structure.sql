
--
-- Create structure
--

CREATE TABLE IF NOT EXISTS "Contact"
(
    "Id" SERIAL ,
    "Title" character varying(100) ,
    "FirstName" character varying(50) ,
    "SecondName" character varying(50) ,
    "LastName" character varying(50) ,
    CONSTRAINT "PK_Contact" PRIMARY KEY ("Id")
) ;
