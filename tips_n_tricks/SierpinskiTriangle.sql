DECLARE 
	@itrations INT = 12,
	@seed geometry = geometry::STGeomFromText ('LINESTRING (9 12, 0 0, 18 0, 9 12)',0);

WITH SierpinskiTriangle(lvl,width,[Ax],[Ay],[Bx],[By],[Cx],[Cy], shape) AS (
	SELECT
		1 lvl,
		[Cx] - [Bx],
		base.[Ax],base.[Ay],
		base.[Bx],base.[By],
		base.[Cx],base.[Cy],
		CONCAT('MULTIPOLYGON( (( ',[Ax],' ',[Ay],',',
							[Bx],' ',[By],',',
							[Cx],' ',[Cy],',',
							[Ax],' ',[Ay],')) )') as shape
	FROM (
		SELECT 
			@seed.STPointN(1).STX as [Ax], @seed.STPointN(1).STY as [Ay],
			@seed.STPointN(2).STX as [Bx], @seed.STPointN(2).STY as [By],
			@seed.STPointN(3).STX as [Cx], @seed.STPointN(3).STY as [Cy]
	) AS base
UNION ALL
	SELECT
		itr.lvl+1 AS lvl,
		itr.width/2,
		new.[Ax],new.[Ay],
		new.[Bx],new.[By],
		new.[Cx],new.[Cy],
		CONCAT('MULTIPOLYGON( (( ',new.[Ax],' ',new.[Ay],',',
							new.[Bx],' ',new.[By],',',
							new.[Cx],' ',new.[Cy],',',
							new.[Ax],' ',new.[Ay],')) )') as shape
	FROM SierpinskiTriangle AS itr
	CROSS APPLY(
		SELECT
			(itr.[Bx]+itr.[Cx])*.5 as [A0x], (itr.[By]+itr.[Cy])*.5 as [A0y],
			(itr.[Cx]+itr.[Ax])*.5 as [B0x], (itr.[Cy]+itr.[Ay])*.5 as [B0y],
			(itr.[Ax]+itr.[Bx])*.5 as [C0x], (itr.[Ay]+itr.[By])*.5 as [C0y]
	) AS mid
	CROSS APPLY(
		SELECT 1, itr.[Ax] , itr.[Ay] , mid.[C0x], mid.[C0y], mid.[B0x], mid.[B0y] UNION ALL
		SELECT 2, mid.[C0x], mid.[C0y], itr.[Bx] , itr.[By] , mid.[A0x], mid.[A0y] UNION ALL
		SELECT 3, mid.[B0x], mid.[B0y], mid.[A0x], mid.[A0y], itr.[Cx] , itr.[Cy] 
	) AS  new(number, [Ax],[Ay],[Bx],[By],[Cx],[Cy])

	WHERE 
		(itr.width > .00002 ) and --triagnel with inside geometry type error. Too small, bail
		itr.lvl < @itrations
)

SELECT
   sys.GeometryUnionAggregate(geometry::STMPolyFromText(shape,0))
FROM
	SierpinskiTriangle
WHERE
	lvl = @itrations

