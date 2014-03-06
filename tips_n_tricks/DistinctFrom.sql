/*
 Descriptions: workaround for "IS [NOT] DISTINCT FROM" syntax in sql server
 Author: Paul White
 Reference: http://sqlblog.com/blogs/paul_white/archive/2011/06/22/undocumented-query-plans-equality-comparisons.aspx
*/

DECLARE	@Set1 TABLE
	(
	 pk BIGINT PRIMARY KEY
	,ival INTEGER NULL
	,cval CHAR(1) NULL
	,mval MONEY NULL );

DECLARE	@Set2 TABLE
	(
	 pk BIGINT PRIMARY KEY
	,ival INTEGER NULL
	,cval CHAR(1) NULL
	,mval MONEY NULL );

INSERT	@Set1
		( pk, ival, cval, mval )
VALUES
		( 1, 1000, 'a', $1 ),
		( 2, NULL, 'b', $2 ),
		( 3, 3000, 'c', NULL ),
		( 4, NULL, 'd', $4 ),
		( 5, 5000, 'e', $5 );

INSERT	@Set2
		( pk, ival, cval, mval )
VALUES
		( 1, 1000, 'a', NULL ),
		( 2, 2000, 'b', $2 ),
		( 3, NULL, 'c', $3 ),
		( 4, NULL, 'd', $4 ),
		( 5, 5999, 'z', $5 );

-- Incorrect results, doesn't account for NULLs
SELECT
	*
FROM
	@Set1 AS t
JOIN @Set2 AS s
ON	s.pk = t.pk
WHERE
	s.ival <> t.ival OR
	s.cval <> t.cval OR
	s.mval <> t.mval;

-- Correct, but verbose and error-prone    
SELECT
	*
FROM
	@Set1 AS t
JOIN @Set2 AS s
ON	s.pk = t.pk
WHERE
	s.ival <> t.ival OR
	(
	  s.ival IS NULL AND
	  t.ival IS NOT NULL
	) OR
	(
	  s.ival IS NOT NULL AND
	  t.ival IS NULL
	) OR
	s.cval <> t.cval OR
	(
	  s.cval IS NULL AND
	  t.cval IS NOT NULL
	) OR
	(
	  s.cval IS NOT NULL AND
	  t.cval IS NULL
	) OR
	s.mval <> t.mval OR
	(
	  s.mval IS NULL AND
	  t.mval IS NOT NULL
	) OR
	(
	  s.mval IS NOT NULL AND
	  t.mval IS NULL
	);

-- COALESCE: Correct results, but problematic
SELECT
	*
FROM
	@Set1 AS t
JOIN @Set2 AS s
ON	s.pk = t.pk
WHERE
	COALESCE(s.ival, -2147483648) <> COALESCE(t.ival, -2147483648) OR
	COALESCE(s.cval, '¥') <> COALESCE(t.cval, '¥') OR
	COALESCE(s.mval, $-922337203685477.5808) <> COALESCE(t.mval, $-922337203685477.5808)

-- ISNULL: Correct results, but problematic
SELECT
	*
FROM
	@Set1 AS t
JOIN @Set2 AS s
ON	s.pk = t.pk
WHERE
	ISNULL(s.ival, -2147483648) <> ISNULL(t.ival, -2147483648) OR
	ISNULL(s.cval, '¥') <> ISNULL(t.cval, '¥') OR
	ISNULL(s.mval, $-922337203685477.5808) <> ISNULL(t.mval, $-922337203685477.5808)

-- INTERSECT:
-- Correct results in a compact form
-- uses "IS" operator for comparision
SELECT
	*
FROM
	@Set1 AS t
JOIN @Set2 AS s
ON	s.pk = t.pk
WHERE
	NOT EXISTS ( SELECT
					s.*
				 INTERSECT
				 SELECT
					t.* )

-- NOT EXISTS:
-- Same query plan, but different results!
-- uses "EQ" operator for comparision

SELECT
	*
FROM
	@Set2 AS s
JOIN @Set1 AS t
ON	t.pk = s.pk
WHERE
	NOT EXISTS ( SELECT
					1
				 WHERE
					t.pk = s.pk AND
					t.ival = s.ival AND
					t.cval = s.cval AND
					t.mval = s.mval )


--- Except versions:
--- from post may produce 'less optimal plans'
SELECT
	*
FROM
	@Set1 AS t
JOIN @Set2 AS s
ON	s.pk = t.pk
WHERE
	EXISTS ( SELECT
				s.*
			EXCEPT
			SELECT
				t.* )

