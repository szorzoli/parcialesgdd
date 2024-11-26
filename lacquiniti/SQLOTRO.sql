--1
SELECT ROW_NUMBER() OVER(ORDER BY SUM(I.item_cantidad) DESC) AS RENGLON,
	C.clie_codigo, C.clie_razon_social, SUM(I.item_cantidad) AS CANT,
	(SELECT TOP 1 R.rubr_detalle FROM Rubro R
		JOIN Producto P ON R.rubr_id = P.prod_rubro
		JOIN Item_Factura I ON P.prod_codigo = I.item_producto
		JOIN Factura F ON I.item_numero + I.item_sucursal + I.item_tipo = F.fact_numero + F.fact_sucursal + F.fact_tipo
		WHERE F.fact_cliente = C.clie_codigo
		GROUP BY R.rubr_detalle
		ORDER BY SUM(I.item_cantidad)) AS CATEGORIA
	FROM Cliente C
	JOIN Factura F ON C.clie_codigo = F.fact_cliente
	JOIN Item_Factura I ON F.fact_numero + F.fact_sucursal + F.fact_tipo = I.item_numero + I.item_sucursal + I.item_tipo
	WHERE C.clie_codigo NOT IN (SELECT fact_cliente FROM Factura WHERE YEAR(fact_fecha) % 2 != 0)
		AND C.clie_codigo IN (SELECT fact_cliente FROM Factura WHERE YEAR(fact_fecha) % 2 = 0) 
	GROUP BY C.clie_codigo, C.clie_razon_social 
	HAVING (SELECT COUNT (DISTINCT R.rubr_detalle) FROM Rubro R
				JOIN Producto P ON R.rubr_id = P.prod_rubro
				JOIN Item_Factura I ON P.prod_codigo = I.item_producto
				JOIN Factura F ON I.item_numero + I.item_sucursal + I.item_tipo = F.fact_numero + F.fact_sucursal + F.fact_tipo
				WHERE F.fact_cliente = C.clie_codigo AND YEAR(F.fact_fecha) = 2012) > 3


