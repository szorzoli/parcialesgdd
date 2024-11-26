--1
SELECT P.prod_codigo, P.prod_detalle, 
	(SELECT MAX(item_precio) FROM Item_Factura
		JOIN Factura ON item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo
		WHERE YEAR(fact_fecha) = 2011 AND item_producto = P.prod_codigo) AS 'PRECIO MAXIMO' FROM Producto P
	JOIN Composicion C ON P.prod_codigo = C.comp_producto
	WHERE P.prod_codigo NOT IN 
		(SELECT comp_producto FROM Composicion
			JOIN Item_Factura ON comp_componente = item_producto
			JOIN Factura ON item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo
			WHERE YEAR(fact_fecha) = 2012
			GROUP BY comp_producto) AND
		P.prod_codigo IN 
		(SELECT comp_producto FROM Composicion
			JOIN Item_Factura ON comp_componente = item_producto
			JOIN Factura ON item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo
			WHERE YEAR(fact_fecha) = 2011
			GROUP BY comp_producto)
	GROUP BY P.prod_codigo, P.prod_detalle
	HAVING COUNT(C.comp_componente) >= 2 AND COUNT(C.comp_componente) <= 4
	ORDER BY (SELECT SUM(item_cantidad) FROM Item_Factura
				JOIN Factura ON item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo
				WHERE YEAR(fact_fecha) = 2011 AND item_producto = P.prod_codigo) DESC
