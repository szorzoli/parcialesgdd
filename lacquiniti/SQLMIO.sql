--1
SELECT ROW_NUMBER() OVER(ORDER BY SUM(I.item_cantidad) DESC) AS RENGLON,
	C.clie_codigo AS CLIENTE,
	(SELECT TOP 1 P.prod_detalle FROM Item_Factura I
		JOIN Factura F ON F.fact_numero + F.fact_sucursal + F.fact_tipo = I.item_numero + I.item_sucursal + I.item_tipo
		JOIN Producto P ON I.item_producto = P.prod_codigo 
		WHERE C.clie_codigo = F.fact_cliente
		GROUP BY I.item_producto,P.prod_detalle
		ORDER BY SUM(I.item_cantidad)) AS PRODUCTO,
	(SELECT SUM(I.item_cantidad) FROM Item_Factura I
		JOIN Factura F ON F.fact_numero + F.fact_sucursal + F.fact_tipo = I.item_numero + I.item_sucursal + I.item_tipo
		WHERE F.fact_cliente = C.clie_codigo) AS CANTIDAD
	FROM Cliente C
	JOIN Factura F ON C.clie_codigo = F.fact_cliente
	JOIN Item_Factura I ON F.fact_numero + F.fact_sucursal + F.fact_tipo = I.item_numero + I.item_sucursal + I.item_tipo
	WHERE C.clie_codigo NOT IN (SELECT fact_cliente FROM Factura WHERE YEAR(fact_fecha) % 2 != 0)
		AND C.clie_codigo IN (SELECT fact_cliente FROM Factura WHERE YEAR(fact_fecha) % 2 = 0)
	GROUP BY C.clie_codigo
