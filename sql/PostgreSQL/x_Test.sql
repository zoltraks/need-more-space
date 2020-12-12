CREATE OR REPLACE PROCEDURE public."x_Test"
(
	help bit DEFAULT NULL::"bit"
)
LANGUAGE 'plpgsql'
AS $$
begin
	SHOW ALL ;
end ;
$$ ;

call "x_Test"()
