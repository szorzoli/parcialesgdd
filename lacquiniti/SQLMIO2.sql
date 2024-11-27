select ROW_NUMBER() over(order by COUNT(distinct i.item_producto) desc) as renglon,
	f.fact_cliente, c.clie_razon_social, COUNT(distinct i.item_producto) as cant_item, SUM(f.fact_total) as total from Factura f
	join Cliente c on c.clie_codigo = f.fact_cliente
	join Item_Factura i on i.item_numero + i.item_sucursal + i.item_tipo = f.fact_numero + f.fact_sucursal + f.fact_tipo
	--where exists (select 1 from Factura f2 where f2.fact_cliente = f.fact_cliente and DATEDIFF(month, f.fact_fecha, f2.fact_fecha) >= 5)
	group by f.fact_cliente,c.clie_razon_social
	having MIN(f.fact_fecha) <= DATEADD(MONTH, -5, MAX(f.fact_fecha)) 


	

