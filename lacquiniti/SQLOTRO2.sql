select 
	ROW_NUMBER() over(order by sum(f.fact_total) desc) as renglon, 
	e.empl_nombre as nombre, 
	(select count(*) from Empleado e2 where e2.empl_jefe = e.empl_codigo) as gente_a_cargo,	
	COUNT(distinct f.fact_cliente)as clientes
	from empleado e
	left join Factura f on f.fact_vendedor = e.empl_codigo
	where 
		(select SUM(f2.fact_total) from Factura f2 where f2.fact_vendedor = e.empl_codigo and YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)) >=
		(select SUM(f3.fact_total) from Factura f3 where f3.fact_vendedor = e.empl_codigo and YEAR(f3.fact_fecha) = YEAR(f.fact_fecha) - 1) *2
	and
		(select SUM(f4.fact_total) from Factura f4 where f4.fact_vendedor = e.empl_codigo and YEAR(f4.fact_fecha) = YEAR(f.fact_fecha) - 1) >=
		(select SUM(f5.fact_total) from Factura f5 where f5.fact_vendedor = e.empl_codigo and YEAR(f5.fact_fecha) = YEAR(f.fact_fecha) - 2) *2
	/* segun chatgpt
	WHERE 
    e.empl_codigo IN 
		(SELECT f1.fact_vendedor FROM Factura f1
			JOIN Factura f2 ON f1.fact_vendedor = f2.fact_vendedor AND YEAR(f2.fact_fecha) = YEAR(f1.fact_fecha) - 1
			JOIN Factura f3 ON f1.fact_vendedor = f3.fact_vendedor AND YEAR(f3.fact_fecha) = YEAR(f1.fact_fecha) - 2
			GROUP BY f1.fact_vendedor
			HAVING 
				SUM(CASE WHEN YEAR(f1.fact_fecha) = YEAR(GETDATE()) THEN f1.fact_total ELSE 0 END) >= 
				2 * SUM(CASE WHEN YEAR(f2.fact_fecha) = YEAR(GETDATE()) - 1 THEN f2.fact_total ELSE 0 END)
            AND 
				SUM(CASE WHEN YEAR(f2.fact_fecha) = YEAR(GETDATE()) - 1 THEN f2.fact_total ELSE 0 END) >= 
				2 * SUM(CASE WHEN YEAR(f3.fact_fecha) = YEAR(GETDATE()) - 2 THEN f3.fact_total ELSE 0 END))
	*/
	group by e.empl_nombre, e.empl_codigo



/*solucion de un tipazo q se saco un 8 es practicamente lo mismo pero cuenta las facturas en vez de sumar los montos*/

SELECT
	ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT f.fact_numero) DESC) AS 'N�mero de fila',
	e.empl_nombre, 
	(SELECT COUNT(*) FROM Empleado as _e WHERE _e.empl_jefe = e.empl_codigo) as cantidad_empleados_a_cargo,
	COUNT(DISTINCT f.fact_cliente) as cantidad_de_clientes_vendio
	FROM Empleado as e 
	JOIN Factura as f ON f.fact_vendedor = e.empl_codigo
	WHERE 
		(SELECT COUNT(*) FROM Factura as _f WHERE _f.fact_vendedor =e.empl_codigo 
			AND YEAR(_f.fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura as _f2 WHERE _f2.fact_vendedor =e.empl_codigo)-2)*2 <=
		(SELECT COUNT(*) FROM Factura as _f3 WHERE _f3.fact_vendedor =e.empl_codigo 
			AND YEAR(_f3.fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura as _f5 WHERE _f5.fact_vendedor =e.empl_codigo)-1)
	AND 
		(SELECT COUNT(*) FROM Factura as _f6 WHERE _f6.fact_vendedor =e.empl_codigo
			AND YEAR(_f6.fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura as _f7 WHERE _f7.fact_vendedor =e.empl_codigo)-1)*2 <= 
		(SELECT COUNT(*) FROM Factura as _f8 WHERE _f8.fact_vendedor =e.empl_codigo 
			AND YEAR(_f8.fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura as _f9 WHERE _f9.fact_vendedor =e.empl_codigo))
	GROUP BY e.empl_nombre,e.empl_codigo
	ORDER BY (SELECT COUNT(*) FROM Factura as _f4 WHERE _f4.fact_vendedor = e.empl_codigo) DESC 

