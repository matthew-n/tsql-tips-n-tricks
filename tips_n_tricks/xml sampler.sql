/*
 Descriptions: reference for all the xml shapping I've learned
 Author: Mattehw Naul

 Explanation: 
	for each person do a correlated query for phone numbers,
	format them mixing attributes and element values,
	serialize to xml with nils and "TYPE" so that it is treated as xml by the outer query,
	name the cross apply result,
	when phonelist is null add nil phonelist node
*/
SELECT
    FirstName
   ,LastName   
   /* so phonelist will always be present */
   ,ISNULL(calc.phoneList,(SELECT NULL AS "phonelist" FOR XML PATH(''), ELEMENTS XSINIL, TYPE) ) AS "node()" 

   /* absent if empty solution */
  --calc.phoneList  AS "node()" 

  /*
	 Drop the root from the cross applied element. 
	 Removes redundant namespace declarations; however, very costly. 
  */
  --,calc.phoneList.query('child::node()/*') AS phonlist 
FROM ( -- quick inline test data
	VALUES
		( 1, 'Bob',  'Smith'),
		( 2, 'Jane', 'Doe'),
		( 3, 'John', 'Jones')
) AS Person(id, FirstName, LastName)

-- I prefer correlated queries in cross apply
CROSS APPLY (
	SELECT
		ord AS "@ord", --tag attribute
		phonetype AS "@type", --tag attribute
		number AS "text()" --body of tag function see below
		/* 
			Reference:
			Books On-Line : Columns with the Name of an XPath Node Test
			http://technet.microsoft.com/en-us/library/bb522573.aspx
		*/
	FROM (-- quick inline test data
		VALUES
			(1, 1, 'home', '806-555-1234'), 
			(1, 2, 'work', '806-555-2843'),
			(2, 1, 'work', '806-555-0282'),
			(2, 2, 'cell', '806-555-9028'), 
			(2, 3, 'home', '806-555-2103')
	) AS PhoneTable(personid, ord, phonetype, number) 
	where 
		Person.id = PhoneTable.personid
	FOR XML PATH('phonenumber'),ROOT('phonelist'), ELEMENTS XSINIL, TYPE
) AS calc(phonelist) 

FOR XML PATH('customer'), ROOT('bookofbusiness'), ELEMENTS XSINIL 

/*
Result:
<bookofbusiness xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <customer>
    <FirstName>Bob</FirstName>
    <LastName>Smith</LastName>
    <phonelist xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <phonenumber ord="1" type="home">806-555-1234</phonenumber>
      <phonenumber ord="2" type="work">806-555-2843</phonenumber>
    </phonelist>
  </customer>
  <customer>
    <FirstName>Jane</FirstName>
    <LastName>Doe</LastName>
    <phonelist xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <phonenumber ord="1" type="work">806-555-0282</phonenumber>
      <phonenumber ord="2" type="cell">806-555-9028</phonenumber>
      <phonenumber ord="3" type="home">806-555-2103</phonenumber>
    </phonelist>
  </customer>
  <customer>
    <FirstName>John</FirstName>
    <LastName>Jones</LastName>
    <phonelist xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:nil="true" />
  </customer>
</bookofbusiness>
*/
