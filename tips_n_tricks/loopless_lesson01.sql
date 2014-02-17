/*
 Descriptions: Removing loops 1
 Author: Matthew Naul
*/

USE tempdb;

/*
	setup a resource table a little like standard libaries
	12.563 MB storage/1 Million records of 4byte int
*/

CREATE TABLE numbers(n INT NOT NULL PRIMARY KEY CLUSTERED (n) WITH(FILLFACTOR =100));
go

WITH -- popular way to make a list of number from 0...N
  L0 AS(SELECT 1 AS c UNION ALL SELECT 1),
  L1 AS(SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),
  L2 AS(SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),
  L3 AS(SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),
  L4 AS(SELECT 1 AS c FROM L3 AS A CROSS JOIN L3 AS B),
  L5 AS(SELECT 1 AS c FROM L4 AS A CROSS JOIN L4 AS B),
  Nums AS(SELECT 0 AS n UNION ALL SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS n FROM L5)

-- write the values 1-1M in order serialy exclusive lock the table
INSERT INTO numbers WITH(TABLOCKX)
	(n)
SELECT TOP (1000000) --1 Million
	n 
FROM Nums 
ORDER BY n
OPTION( MAXDOP 1 ); 

SELECT
/*
Some table_1 of XFactor v. YFactor results in some business metric
	( F(x,y)=value for software)
this value changes often and is autorhored by an external source
so we _do not_ want to hardcode it into the program.

table_1
		   100    090    080    070    060    050    040    030    020    010
	100    F(x,y) F(x,y) F(x,y) F(x,y) F(x,y) F(x,y) F(x,y) F(x,y) F(x,y) F(x,y)
	090	    N     F(x,y) F(x,y) F(x,y) F(x,y) F(x,y) F(x,y) F(x,y) F(x,y) F(x,y)
	080	    N      N     F(x,y) F(x,y) F(x,y) F(x,y) F(x,y) F(x,y) F(x,y) F(x,y)
	070	    N      N      N     F(x,y) F(x,y) F(x,y) F(x,y) F(x,y) F(x,y) F(x,y)
	060	    N      N      N       N    F(x,y) F(x,y) F(x,y) F(x,y) F(x,y) F(x,y)
	050	    N      N      N       N     N     F(x,y) F(x,y) F(x,y) F(x,y) F(x,y)
	040	    N      N      N       N     N       N    F(x,y) F(x,y) F(x,y) F(x,y)
	030	    N      N      N       N     N       N     N     F(x,y) F(x,y) F(x,y)
	020	    N      N      N       N     N       N     N      N     F(x,y) F(x,y)
	010	    N      N      N       N     N       N     N      N      N     F(x,y)

note: F(x,y) - Result of a function, N - Null (Not applicable/ don't care)

	code solution
	for int y=10; y<110; y+=10
	begin
		for int x=10; x<110; x+=10
		begin
			 //print y+','+x+'\t'
			  calc = do_stuff(x,y)
			 insert_into_table (x,y,calc) -- executes 100 times
		end
		//print '\r\n'
	end
*/
-- debug info
SET STATISTICS IO ON



/*
	y values 10 to 100 multiples of 10
*/
SELECT
	n AS y_itr
FROM numbers
WHERE
	-- init
	n >0 AND -- starting point 
	-- upper limit
	n < 110 AND 
	-- step 
	n %10 = 0 -- multiples of 10, instead of add 10


/*
   for each y(10 to 100 multiples of 10 ) 
     x values 10 to 100 multiples of 10
   whe acutaly want the cartiesan product
   all combinations y_itr,x_itr
*/
-- option A
SELECT
	yloop.y_itr,
	xloop.x_itr,
	(1.0*(xloop.x_itr)+5)/(yloop.y_itr ) AS calc
FROM 
	(SELECT n AS y_itr FROM numbers WHERE n >0 AND n < 110 AND n %10 = 0) AS yloop,
		(SELECT n AS x_itr FROM numbers WHERE n >0 AND n < 110 AND n %10 = 0) AS xloop

--option B
SELECT
	yloop.n AS y_itr,
	xloop.n AS x_itr,
	(1.0*(xloop.N)+5)/(yloop.N ) AS calc
FROM 
	numbers AS yloop,
		numbers AS xloop
WHERE
	(yloop.n >0 AND yloop.n < 110 AND yloop.n %10 = 0 )
		AND
		(xloop.n >0 AND xloop.n < 110 AND xloop.n %10 = 0)


/*
	we don't want the bottom half of the line x=y
*/
SELECT
	xloop.N AS x_itr,
	yloop.N AS y_itr,
	(1.0*(xloop.N)+5)/(yloop.N ) AS calc
FROM  dbo.numbers AS yloop
CROSS JOIN dbo.numbers AS xloop -- new syntax for "FROM  numbers AS yloop, numbers AS xloop"
WHERE
	(yloop.n >0 AND yloop.n < 110 AND yloop.n % 10 = 0) AND
	(xloop.n >0 AND xloop.n < 110 AND xloop.n % 10 = 0) AND 
	xloop.n <= yloop.n
--ORDER BY -- debug: so we can varify the data is expected
--	x_itr,
--	y_itr;


/* 
	move the factor of 10 to the output side
*/
SELECT
	10*xloop.N AS x_itr,
	10*yloop.N AS y_itr,
	((10.*xloop.N)+5)/(10*yloop.N ) AS calc
FROM numbers AS yloop
CROSS JOIN numbers AS xloop 
WHERE
	xloop.n >0 AND xloop.n < 11 AND 
	yloop.n >0 AND yloop.n < 11 AND
	xloop.n <= yloop.n;


/*
	readablity, at least for DBAs
*/
WITH itrations(itr) AS (
	SELECT N  FROM numbers WHERE N > 0 AND N <11
)	
SELECT
	scale.x_itr,
	scale.y_itr,
	1.0*(scale.x_itr+5)/scale.y_itr AS calc
FROM  itrations AS yloop
CROSS JOIN itrations AS xloop
CROSS APPLY ( 
	SELECT 
		10*xloop.itr AS x_itr,
		10*yloop.itr AS y_itr
)AS scale(x_itr, y_itr)
WHERE
	xloop.itr <= yloop.itr;

/* clean up */
DROP TABLE numbers
SET STATISTICS IO OFF

GO