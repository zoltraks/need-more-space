
--
-- Create indexes
--

CREATE UNIQUE INDEX "UX_FirstName_SecondName_LastName" ON "Contact" USING btree
(
	"FirstName" ASC NULLS LAST, 
	"SecondName" ASC NULLS LAST, 
	"LastName" ASC NULLS LAST
)
;
