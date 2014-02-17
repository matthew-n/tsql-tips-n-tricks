/*
 Descriptions: Two column unpivot
 Author: Matthew Naul
*/

SELECT
	PhoneTable.FirstName,
	PhoneTable.LastName,
	phone_unpvt.*
FROM (
	VALUES
		( 'Bob','Smith','home','806-555-1234', 'work','806-555-2843',NULL, NULL),
		( 'Jane', 'Doe', 'work', '806-555-0282', 'cell', '806-555-9028', 'home', '806-555-2103'),
		( 'John', 'Jones', NULL, NULL, NULL, NULL, NULL, NULL)
) AS PhoneTable(FirstName, LastName, phonetype1, phone1, phonetype2, phone2, phonetype3, phone3)
CROSS APPLY
( 
	SELECT 1, phone1, phonetype1 UNION ALL
	SELECT 2, phone2, phonetype2 UNION ALL
	SELECT 3, phone3, phonetype3 
)AS phone_unpvt(ord, number, phonetype) -- will use loop join and constant table scan like unpivot