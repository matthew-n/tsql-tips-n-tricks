

SELECT
    FirstName
   ,LastName
   --,calc.phoneList.query('child::node()/*') AS phonlist -- drop the root from the cross applied element
   ,ISNULL(calc.phoneList,(SELECT NULL FOR XML PATH('phonelist'), ELEMENTS XSINIL)) AS "node()" -- musch cheaper
FROM (
	VALUES
		( 'Bob','Smith','home','806-555-1234', 'work','806-555-2843',NULL, NULL),
		( 'Jane', 'Doe', 'work', '806-555-0282', 'cell', '806-555-9028', 'home', '806-555-2103'),
		( 'John', 'Jones', NULL, NULL, NULL, NULL, NULL, NULL)
) AS PhoneTable(FirstName, LastName, phonetype1, phone1, phonetype2, phone2, phonetype3, phone3)
CROSS APPLY
(
	SELECT 
		ord AS "@ord", --tag attribute
		phonetype AS "@type", --tag attribute
		number AS "text()" --body of tag function, node(), text(), comment(),.. add URL
	FROM
	( 
		SELECT 1, phone1, phonetype1 UNION ALL
		SELECT 2, phone2, phonetype2 UNION ALL
		SELECT 3, phone3, phonetype3 
	)AS phone_unpvt(ord, number, phonetype) -- will use loop join and constant table scan like unpivot
	WHERE 
		number IS NOT NULL
	 FOR XML PATH('phonenumber'),ROOT('phonelist'), ELEMENTS XSINIL, TYPE --"TYPE" so it is not escaped on the outside
) AS calc(phonelist) -- I prefer named table row instead of correlated queries in select clause
FOR XML PATH('customer'), ROOT('bookofbusiness'), ELEMENTS XSINIL 



/*
Result:
<bookofbusiness xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <customer>
    <FirstName>Bob</FirstName>
    <LastName>Smith</LastName>
    <phonlist>
      <phonenumber ord="1" type="home">806-555-1234</phonenumber>
      <phonenumber ord="2" type="work">806-555-2843</phonenumber>
    </phonlist>
  </customer>
  <customer>
    <FirstName>Jane</FirstName>
    <LastName>Doe</LastName>
    <phonlist>
      <phonenumber ord="1" type="work">806-555-0282</phonenumber>
      <phonenumber ord="2" type="cell">806-555-9028</phonenumber>
      <phonenumber ord="3" type="home">806-555-2103</phonenumber>
    </phonlist>
  </customer>
  <customer>
    <FirstName>John</FirstName>
    <LastName>Jones</LastName>
    <phonlist xsi:nil="true" />
  </customer>
</bookofbusiness>

*/


