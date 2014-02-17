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


/*
   for each y(10 to 100 multiples of 10 ) 
     x values 10 to 100 multiples of 10
   whe acutaly want the cartiesan product
   all combinations y_itr,x_itr
*/



/*
	we don't want the bottom half of the line x=y
*/



/* 
	move the factor of 10 to the output side
*/



/* clean up */
DROP TABLE numbers
SET STATISTICS IO OFF

GO