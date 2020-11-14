
--
-- Insert data
--

IF NOT EXISTS ( SELECT 1 FROM dbo.[Contact] WHERE FirstName = N'Joe' AND SecondName = '' AND LastName = N'Doe' )
INSERT INTO dbo.[Contact] ( FirstName , SecondName , LastName , Title ) VALUES ( N'Joe' , '' , N'Doe' , '' )
;

IF NOT EXISTS ( SELECT 1 FROM dbo.[Contact] WHERE FirstName = N'Amy' AND SecondName = '' AND LastName = '' )
INSERT INTO dbo.[Contact] ( FirstName , SecondName , LastName , Title ) VALUES ( N'Amy' , '' , '' , '' )
;

IF NOT EXISTS ( SELECT 1 FROM dbo.[Contact] WHERE FirstName = N'Bob' AND SecondName = '' AND LastName = '' )
INSERT INTO dbo.[Contact] ( FirstName , SecondName , LastName , Title ) VALUES ( N'Bob' , '' , '' , '' )
;
