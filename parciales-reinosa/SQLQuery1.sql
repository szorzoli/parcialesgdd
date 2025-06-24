--4/7/2023
select z.zona_detalle, count(distinct d.depo_codigo),
	(select count(c.comp_producto) from Producto p
		join Composicion c on c.comp_producto = p.prod_codigo
		join STOCK s2 on s2.stoc_producto = c.comp_producto
		join DEPOSITO d2 on depo_codigo = s2.stoc_deposito
		where d2.depo_zona = z.zona_codigo
		group by d2.depo_zona) AS cant_producs,
	(select top 1 i.item_producto from Item_Factura i
		JOIN Factura f on i.item_numero = f.fact_numero and i.item_sucursal = f.fact_sucursal and i.item_tipo = f.fact_tipo
		join STOCK s2 on s2.stoc_producto  = i.item_producto
		join DEPOSITO d2 on depo_codigo = s2.stoc_deposito
		where year(f.fact_fecha) = 2012 and d2.depo_zona = z.zona_codigo
		group by i.item_producto, d2.depo_zona
		having sum(s2.stoc_cantidad) > 0
		order by sum(i.item_cantidad)),
	(select top 1 d2.depo_encargado from DEPOSITO d2
		left join Factura f on d2.depo_encargado = f.fact_vendedor
		left JOIN Item_Factura i on i.item_numero = f.fact_numero and i.item_sucursal = f.fact_sucursal and i.item_tipo = f.fact_tipo
		where d2.depo_zona = z.zona_codigo
		group by d2.depo_encargado, d2.depo_zona
		order by sum(i.item_cantidad) desc)
	from DEPOSITO d
	join Zona z on d.depo_zona = z.zona_codigo
	left join STOCK s on d.depo_codigo = s.stoc_deposito
	group by z.zona_codigo,z.zona_detalle
	having COUNT(distinct d.depo_codigo) >= 3
	order by 
		(select top 1 sum(i.item_cantidad) from DEPOSITO d2
			left join Factura f on d2.depo_encargado = f.fact_vendedor
			left JOIN Item_Factura i on i.item_numero = f.fact_numero and i.item_sucursal = f.fact_sucursal and i.item_tipo = f.fact_tipo
			where d2.depo_zona = z.zona_codigo
			group by d2.depo_encargado, d2.depo_zona
			order by sum(i.item_cantidad) desc)


--4/7/2023
select top 10 c.clie_razon_social, count(distinct i.item_producto),
	(select sum(i2.item_cantidad) from Item_Factura i2
		join Factura f2 on i2.item_numero = f2.fact_numero and i2.item_sucursal = f2.fact_sucursal and i2.item_tipo = f2.fact_tipo
		where f2.fact_cliente = f.fact_cliente and YEAR(f2.fact_fecha) = 2012 and MONTH(f2.fact_fecha)<= 6)
	from Factura f
	join Cliente c on c.clie_codigo = f.fact_cliente
	join Item_Factura i on i.item_numero = f.fact_numero and i.item_sucursal = f.fact_sucursal and i.item_tipo = f.fact_tipo
	where year(f.fact_fecha) = 2012 
	group by f.fact_cliente, c.clie_razon_social
	having count(distinct f.fact_vendedor) > 3
	order by sum(i.item_cantidad) desc, f.fact_cliente


--20/6/2024
select p.prod_detalle, count(*),
	CASE 
		WHEN COUNT(DISTINCT CASE WHEN YEAR(f.fact_fecha) = 2012 THEN f.fact_numero END) > 100
			THEN 'Popular'
			ELSE 'Sin interés'
		END AS leyenda,
	(select top 1 f2.fact_cliente from Item_Factura i2
		join Factura f2 on i2.item_numero = f2.fact_numero and i2.item_sucursal = f2.fact_sucursal and i2.item_tipo = f2.fact_tipo
		where year(f2.fact_fecha) = 2012 and i2.item_producto = i.item_producto
		group by i2.item_producto, f2.fact_cliente
		order by sum(i2.item_cantidad) desc, f2.fact_cliente desc) as cliente
	from Item_Factura i
	join Producto p on p.prod_codigo = i.item_producto
	join Factura f on i.item_numero = f.fact_numero and i.item_sucursal = f.fact_sucursal and i.item_tipo = f.fact_tipo
	where year(f.fact_fecha) = 2012
	group by i.item_producto, p.prod_detalle
	having sum(i.item_cantidad) >  
		(select 0.15 * sum(i2.item_cantidad)/2 from Item_Factura i2
			join Factura f2 on i2.item_numero = f2.fact_numero and i2.item_sucursal = f2.fact_sucursal and i2.item_tipo = f2.fact_tipo
			where i2.item_producto = i.item_producto and year(f2.fact_fecha) between 2010 and 2011
			group by i2.item_producto)

--25/06/2024
select d.depo_codigo, d.depo_domicilio,
	(select COUNT( distinct c.comp_producto) from Composicion c
		join stock s2 on c.comp_producto = s2.stoc_producto
		where s2.stoc_deposito = d.depo_codigo
		group by s2.stoc_deposito
		having sum(s2.stoc_cantidad) > 0) as compuestos,
	(select COUNT( distinct p.prod_codigo) from Producto p
		join stock s2 on p.prod_codigo = s2.stoc_producto
		where s2.stoc_deposito = d.depo_codigo and p.prod_codigo not in (select distinct comp_producto from Composicion)
		group by s2.stoc_deposito
		having sum(s2.stoc_cantidad) > 0) as simples,
	CASE 
		WHEN 
			(select COUNT( distinct c.comp_producto) from Composicion c
				join stock s2 on c.comp_producto = s2.stoc_producto
				where s2.stoc_deposito = d.depo_codigo
				group by s2.stoc_deposito
				having sum(s2.stoc_cantidad) > 0) > 
			(select COUNT( distinct p.prod_codigo) from Producto p
				join stock s2 on p.prod_codigo = s2.stoc_producto
				where s2.stoc_deposito = d.depo_codigo and p.prod_codigo not in (select distinct comp_producto from Composicion)
				group by s2.stoc_deposito
				having sum(s2.stoc_cantidad) > 0)
			THEN 'mayoria compuestos'
			ELSE 'mayoria no compuestos'
		END AS leyenda
	from DEPOSITO d
	left join STOCK s on s.stoc_deposito = d.depo_codigo
	group by d.depo_codigo, d.depo_domicilio
	having count(s.stoc_producto) between 0 and 1000

--25/6/24
select p.prod_codigo, p.prod_detalle,
	case when
		(select top 1 sum(i3.item_cantidad) from Item_Factura i3
			join Factura f2 on i3.item_numero = f2.fact_numero and i3.item_sucursal = f2.fact_sucursal 
			where i3.item_producto = p.prod_codigo
			group by i3.item_producto, year(f2.fact_fecha)
			order by year(f2.fact_fecha) desc) >
		(select top 1 sum(i3.item_cantidad) from Item_Factura i3
			join Factura f2 on i3.item_numero = f2.fact_numero and i3.item_sucursal = f2.fact_sucursal 
			where i3.item_producto = 00001718 and 
				year(f2.fact_fecha) = (select top 1 year(fact_fecha) -1 from Factura order by year(fact_fecha) desc)
			group by i3.item_producto, year(f2.fact_fecha)
			order by year(f2.fact_fecha) desc)
		then 'mas ventas'
		else 'menos ventas'
		end as leyenda
	,e.enva_detalle from Item_Factura i
	join Producto p on i.item_producto = p.prod_codigo
	join Envases e on p.prod_envase = e.enva_codigo
	where p.prod_codigo in 
		(select top 5 i2.item_producto from Item_Factura i2
			join Factura f2 on i2.item_numero = f2.fact_numero and i2.item_sucursal = f2.fact_sucursal 
				and i2.item_tipo = f2.fact_tipo
			where YEAR(f2.fact_fecha) = 2012
			group by i2.item_producto
			order by sum(i2.item_cantidad) desc)
		or p.prod_codigo in
			(select top 5 i2.item_producto from Item_Factura i2
				join Factura f2 on i2.item_numero = f2.fact_numero and i2.item_sucursal = f2.fact_sucursal 
					and i2.item_tipo = f2.fact_tipo
				where YEAR(f2.fact_fecha) = 2012
				group by i2.item_producto
				order by sum(i2.item_cantidad) asc)
	group by p.prod_codigo, p.prod_detalle,e.enva_detalle
	order by e.enva_detalle desc

--14/11/2023
select p.prod_codigo, p.prod_detalle, d.depo_domicilio,
	(select ISNULL(count (distinct s2.stoc_deposito),0) from STOCK s2 
		join DEPOSITO d2 on d2.depo_codigo = s2.stoc_deposito
		where s2.stoc_producto = p.prod_codigo and s2.stoc_cantidad>s2.stoc_punto_reposicion) 
	from Producto p
	left join STOCK s on s.stoc_producto = p.prod_codigo
	join DEPOSITO d on s.stoc_deposito = d.depo_codigo
	where (s.stoc_cantidad = 0 or s.stoc_cantidad is null) and 
		exists (select 1 from STOCK s2 
			where s2.stoc_producto = p.prod_codigo and s2.stoc_cantidad>s2.stoc_punto_reposicion
				and s2.stoc_deposito != d.depo_codigo)
	group by p.prod_codigo, p.prod_detalle, d.depo_domicilio
	order by 1 desc

--11/7/2023
select c.clie_razon_social, 
	case when COUNT(*) > 1
		then 'recurrente'
		else 'unica vez'
	end,
	sum(i.item_cantidad),
	(select top 1 i2.item_producto from Item_Factura i2 
		join Factura f2 on i2.item_numero = f2.fact_numero and i2.item_sucursal = f2.fact_sucursal and i2.item_tipo = f2.fact_tipo
		where f2.fact_cliente = c.clie_codigo
		group by i2.item_producto
		order by sum(i2.item_cantidad) desc, i2.item_producto desc)
	from Cliente c
	left join Factura f on c.clie_codigo = f.fact_cliente
	join Item_Factura i on i.item_numero = f.fact_numero and i.item_sucursal = f.fact_sucursal 
		and i.item_tipo = f.fact_tipo
	where YEAR(f.fact_fecha) = 2012
	group by c.clie_codigo, c.clie_razon_social
	having sum(f.fact_total) < 0.25 * 
		(select sum(f2.fact_total)/2 from Factura f2 where f2.fact_cliente = c.clie_codigo 
			and (year(f2.fact_fecha) = 2010 or year(f2.fact_fecha) = 2011))

--4/72023
select year(f.fact_fecha), fl.fami_id, fl.fami_detalle, count(distinct f.fact_numero + f.fact_tipo + f.fact_sucursal),
	count (distinct c.comp_producto),sum(f.fact_total), sum(f.fact_total) from Familia fl
	join Producto p on fami_id = p.prod_familia
	join Item_Factura i on p.prod_codigo = i.item_producto
	JOIN Factura f on i.item_numero = f.fact_numero and i.item_sucursal = f.fact_sucursal and i.item_tipo = f.fact_tipo
	left join Composicion c on p.prod_codigo = c.comp_producto
	join Item_Factura i2 on i2.item_tipo = f.fact_tipo and i2.item_sucursal = f.fact_sucursal AND i2.item_numero = f.fact_numero
	JOIN Producto p2 ON p2.prod_codigo = i2.item_producto
	JOIN Familia fl2 ON fl2.fami_id = p2.prod_familia
	where fl.fami_id <> fl2.fami_id
	group by year(f.fact_fecha), fl.fami_id, fl.fami_detalle
	having count (distinct c.comp_producto) >=1

--hoy
select e.empl_apellido as apellido, e.empl_nombre as nombre,sum(i.item_cantidad) as cantidad_vendida,
	sum(i.item_precio * i.item_cantidad)/count(distinct f.fact_numero+f.fact_sucursal+f.fact_tipo) as monto_promedio, 
	sum(i.item_precio * i.item_cantidad) as monto_total from Factura f
	join Empleado e on f.fact_vendedor = e.empl_codigo
	JOIN Item_Factura i on i.item_numero = f.fact_numero and i.item_sucursal = f.fact_sucursal and i.item_tipo = f.fact_tipo
	where f.fact_vendedor in
		(select top 5 f2.fact_vendedor from Factura f2 
			where year(f2.fact_fecha) = (select max(year(fact_fecha)) from Factura)
			group by f2.fact_vendedor
			order by count(distinct f2.fact_cliente) asc, sum (f2.fact_total) desc)
		 and year(f.fact_fecha) =  (select max(year(fact_fecha)) from Factura) 
		 and 
			(select count(*) from Item_Factura i2 
				where i2.item_numero = f.fact_numero and i2.item_sucursal = f.fact_sucursal and i2.item_tipo = f.fact_tipo)
			> 2
	group by f.fact_vendedor, e.empl_apellido, e.empl_nombre
	order by count( f.fact_numero+f.fact_sucursal+f.fact_tipo) desc, f.fact_vendedor