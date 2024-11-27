use GD2015C1
/*
SQL_2023_07_04
1. Se solicita estadística por Año y familia, para ello se deberá mostrar. Año, Código de familia, Detalle de familia, cantidad de facturas, 
cantidad de productos con Composición vendidos, monto total vendido. Solo se deberán considerar las familias que tengan al menos un producto con 
composición y que se hayan vendido conjuntamente (en la misma factura) con otra familia distinta.
NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el usuario para este punto*/

select YEAR(f.fact_fecha) as 'Año', fl.fami_detalle, COUNT(distinct f.fact_numero + f.fact_sucursal + f.fact_tipo) as 'cantidad de facturas',
	(select COUNT( distinct c.comp_producto) from Composicion c 
		join Producto p2 on c.comp_producto = p2.prod_codigo
		join Item_Factura i3 on p2.prod_codigo = i3.item_producto
		join Factura f3 on f3.fact_numero + f3.fact_sucursal +f3.fact_tipo = i3.item_numero + i3.item_sucursal + i3.item_tipo
		where p2.prod_familia = fl.fami_id and YEAR(f3.fact_fecha) = YEAR(f.fact_fecha)) as cant_prod_comp,
	SUM(i.item_precio*i.item_cantidad) as 'monto total vendido' from Factura f
	join Item_Factura i on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
	join Producto p on i.item_producto = p.prod_codigo
	join Familia fl on p.prod_familia = fl.fami_id
	where (select COUNT(c.comp_componente) from Composicion c 
			join Producto p2 on c.comp_producto = p2.prod_codigo
			where p2.prod_familia = fl.fami_id) >= 1
		and exists
			(select 1 from Item_Factura i2
				join Producto p2 ON i2.item_producto = p2.prod_codigo
				WHERE i2.item_tipo = f.fact_tipo and i2.item_sucursal = f.fact_sucursal and i2.item_numero = f.fact_numero 
					and p2.prod_familia <> p.prod_familia)
	group by YEAR(f.fact_fecha), fl.fami_detalle, fl.fami_id



/*
SQL_2023_07_08
Se pide que realice un reporte generado por una sola query que de cortes de informacion por periodos (anual,semestral y bimestral). Un corte por el año, un corte 
por el semestre el año y un corte por bimestre el año. En el corte por año mostrar las ventas totales realizadas por año, la cantidad de rubros distintos 
comprados por año, la cantidad de productos con composicion distintos comporados por año y la cantidad de clientes que compraron por año. Luego, en la informacion 
del semestre mostrar la misma informacion, es decir, las ventas totales por semestre, cantidad de rubros por semestre, etc. y la misma logica por bimestre. 
El orden tiene que ser cronologico.*/



select YEAR(f.fact_fecha) as anio, sum(f.fact_total) as total_vent,
	(select COUNT(distinct p.prod_rubro) from Item_Factura i
		join Factura f2 on f2.fact_numero + f2.fact_sucursal + f2.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
		join Producto p on i.item_producto = p.prod_codigo
		where YEAR(f.fact_fecha) = YEAR(f2.fact_fecha)) as rubros,
	(select COUNT(distinct c.comp_producto) from Composicion c
		join Item_Factura i on c.comp_producto = i.item_producto
		join Factura f2 on f2.fact_numero + f2.fact_sucursal + f2.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
		where YEAR(f.fact_fecha) = YEAR(f2.fact_fecha)) as prod_comp,
	count(distinct f.fact_cliente) as clientes
	from Factura f
	where YEAR(f.fact_fecha) is not null
	group by YEAR(f.fact_fecha)

union

select (case when(MONTH(f.fact_fecha)>= 6) then 0 else 1 end) as semestre, sum(f.fact_total) as total_vent,
	(select COUNT(distinct p.prod_rubro) from Item_Factura i
		join Factura f2 on f2.fact_numero + f2.fact_sucursal + f2.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
		join Producto p on i.item_producto = p.prod_codigo
		where YEAR(f.fact_fecha) = YEAR(f2.fact_fecha)) as rubros,
	(select COUNT(distinct c.comp_producto) from Composicion c
		join Item_Factura i on c.comp_producto = i.item_producto
		join Factura f2 on f2.fact_numero + f2.fact_sucursal + f2.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
		where YEAR(f.fact_fecha) = YEAR(f2.fact_fecha)) as prod_comp,
	count(distinct f.fact_cliente) as clientes
	from Factura f
	where YEAR(f.fact_fecha) is not null
	group by YEAR(f.fact_fecha), (case when(MONTH(f.fact_fecha)>= 6) then 0 else 1 end)

union

select (FLOOR((MONTH(f.fact_fecha)-1)/2)+1), sum(f.fact_total) as total_vent,
	(select COUNT(distinct p.prod_rubro) from Item_Factura i
		join Factura f2 on f2.fact_numero + f2.fact_sucursal + f2.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
		join Producto p on i.item_producto = p.prod_codigo
		where YEAR(f.fact_fecha) = YEAR(f2.fact_fecha)) as rubros,
	(select COUNT(distinct c.comp_producto) from Composicion c
		join Item_Factura i on c.comp_producto = i.item_producto
		join Factura f2 on f2.fact_numero + f2.fact_sucursal + f2.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
		where YEAR(f.fact_fecha) = YEAR(f2.fact_fecha)) as prod_comp,
	count(distinct f.fact_cliente) as clientes
	from Factura f
	where YEAR(f.fact_fecha) is not null
	group by YEAR(f.fact_fecha), (FLOOR((MONTH(f.fact_fecha)-1)/2)+1)

/*
SQL_parcial_2021
1. Armar una consulta Sql que retorne: 
	Razón social del cliente
	Límite de crédito del cliente
	Producto más comprado en la historia (en unidades)    
Solamente deberá mostrar aquellos clientes que tuvieron mayor cantidad de ventas en el 2012 que en el 2011 en cantidades y cuyos montos de ventas en dichos años 
sean un 30 % mayor el 2012 con respecto al 2011. El resultado deberá ser ordenado por código de cliente ascendente*/



select c.clie_razon_social,c.clie_limite_credito,
	(select top 1 i.item_producto from Item_Factura i 
		join Factura f on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
		where f.fact_cliente = c.clie_codigo
		group by i.item_producto
		order by SUM(i.item_cantidad) desc) as prod_max
	from Cliente c 
	where 
			(select SUM(i.item_cantidad) from Factura f 
				join Item_Factura i on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
				where f.fact_cliente = c.clie_codigo and YEAR(f.fact_fecha) = 2012
				group by f.fact_cliente) > 
			(select SUM(i.item_cantidad) from Factura f 
				join Item_Factura i on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
				where f.fact_cliente = c.clie_codigo and YEAR(f.fact_fecha) = 2011
				group by f.fact_cliente)
		and
			(select SUM(i.item_precio *i.item_cantidad) from Factura f 
				join Item_Factura i on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
				where f.fact_cliente = c.clie_codigo and YEAR(f.fact_fecha) = 2012
				group by f.fact_cliente) > 
			(select SUM(i.item_precio *i.item_cantidad) from Factura f 
				join Item_Factura i on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
				where f.fact_cliente = c.clie_codigo and YEAR(f.fact_fecha) = 2011
				group by f.fact_cliente) * 1.3
	group by c.clie_codigo, c.clie_razon_social, c.clie_limite_credito
	order by c.clie_codigo asc


/* 
SQL_parcial_2022_11_08
todavia no lo compare con nadie
1. Realizar una consulta SQL que permita saber si un cliente compro un producto en todos los meses del 2012.

Además, mostrar para el 2012: 
1. El cliente
2. La razón social del cliente
3. El producto comprado
4. El nombre del producto
5. Cantidad de productos distintos comprados por el cliente.
6. Cantidad de productos con composición comprados por el cliente.

El resultado deberá ser ordenado poniendo primero aquellos clientes que compraron más de 10 productos distintos en el 2012. */


select c.clie_codigo, c.clie_razon_social, 
	(select top 1 i.item_producto from item_factura i
		join Factura f on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
		where f.fact_cliente = c.clie_codigo
		group by i.item_producto
		order by SUM(i.item_cantidad) desc) as prod_max,
	(select top 1 p.prod_detalle from item_factura i
		join Factura f on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
		join Producto p on p.prod_codigo = i.item_producto
		where f.fact_cliente = c.clie_codigo
		group by i.item_producto, p.prod_detalle
		order by SUM(i.item_cantidad) desc) as det_prod_max,
	(select COUNT(distinct i.item_producto) from Item_Factura i
		join Factura f on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
		where f.fact_cliente = c.clie_codigo) as cant_prod_dif,
	(select COUNT(distinct com.comp_producto) from Composicion com
		join Item_Factura i on com.comp_producto = i.item_producto
		join Factura f on f.fact_numero + f.fact_sucursal + f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
		where f.fact_cliente = c.clie_codigo) as prod_comp
	from Cliente c
	join Factura f2 on f2.fact_cliente = c.clie_codigo
	group by  c.clie_codigo, c.clie_razon_social
	having COUNT(distinct MONTH(f2.fact_fecha)) = 12
	order by case when 
		(select COUNT(distinct i.item_producto) from Item_Factura i
			join Factura f on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
			where f.fact_cliente = c.clie_codigo and YEAR(f.fact_fecha) = 2012) >= 10 then 1 else 0 end desc


/* 
SQL_parcial_2022_11_12
Realizar una consulta SQL que permita saber los clientes que compraron por encima del promedio de compras (fact_total) de todos los clientes del 2012.
De estos clientes mostrar para el 2012:
	1.El código del cliente
	2.La razón social del cliente
	3.Código de producto que en cantidades más compro.
	4.El nombre del producto del punto 3.
	5.Cantidad de productos distintos comprados por el cliente,
	6.Cantidad de productos con composición comprados por el cliente,
EI resultado deberá ser ordenado poniendo primero aquellos clientes que compraron más de entre 5 y 10 productos distintos en el 2012 */

select c.clie_codigo, c.clie_razon_social,
	(select top 1 i.item_producto from Item_Factura i
		join Factura f on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
		where f.fact_cliente = c.clie_codigo and YEAR(f.fact_fecha) = 2012
		group by i.item_producto
		order by sum(i.item_cantidad)desc) as prod_max,
	(select top 1 p.prod_detalle from Item_Factura i
		join Producto p on p.prod_codigo = i.item_producto
		join Factura f on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
		where f.fact_cliente = c.clie_codigo and YEAR(f.fact_fecha) = 2012
		group by i.item_producto, p.prod_detalle
		order by sum(i.item_cantidad) desc) as prod_max,
	(select COUNT(distinct i.item_producto) from Item_Factura i
		join Factura f on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
		where f.fact_cliente = c.clie_codigo and YEAR(f.fact_fecha) = 2012) as cant_prod,
	(select COUNT(distinct i.item_producto) from Item_Factura i
		join Composicion comp on comp.comp_producto = i.item_producto
		join Factura f on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
		where f.fact_cliente = c.clie_codigo and YEAR(f.fact_fecha) = 2012) as cant_com_prod
	from Cliente c

	where 
		(select sum(f.fact_total) from Factura f where c.clie_codigo = f.fact_cliente and YEAR(f.fact_fecha) = 2012) >=
		(select AVG(f.fact_total) from Factura f where YEAR(f.fact_fecha) = 2012)
	group by c.clie_codigo, c.clie_razon_social
	order by case when 
		(select count(distinct i.item_producto) from Item_Factura i
			join Factura f on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
			where f.fact_cliente = c.clie_codigo and YEAR(f.fact_fecha) = 2012) between 5 and 10 then 1 else 0 end desc

--alguien mejor que vos

select	f.fact_cliente,
		c.clie_razon_social,

		(select top 1 i2.item_producto
		 from Item_Factura i2
		 join Factura f2 on f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero and f2.fact_cliente=f.fact_cliente
		 where year(f2.fact_fecha)=2012
		 group by i2.item_producto
		 order by sum(i2.item_cantidad) desc) as 'Cod_Producto_Mas_Comprado',

		 (select top 1 p.prod_detalle
		 from Item_Factura i2
		 join Factura f2 on f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero and f2.fact_cliente=f.fact_cliente
		 join Producto p on p.prod_codigo=i2.item_producto
		 where year(f2.fact_fecha)=2012
		 group by i2.item_producto, p.prod_detalle
		 order by sum(i2.item_cantidad) desc) as 'Producto_Mas_Comprado',
		
		 count(distinct i.item_producto) as 'Productos_Distintos_Comprados',

		 (select isnull(sum(i2.item_cantidad),0)
		  from Item_Factura i2
		  join Factura f2 on f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero and f2.fact_cliente=f.fact_cliente
		  where year(f2.fact_fecha)=2012 and i2.item_producto in (select c.comp_producto from Composicion c)) 
				
from Factura f
join Cliente c on f.fact_cliente=c.clie_codigo
join Item_Factura i on f.fact_tipo+f.fact_sucursal+f.fact_numero = i.item_tipo+i.item_sucursal+i.item_numero
where year(f.fact_fecha)=2012
group by f.fact_cliente, c.clie_razon_social
having sum(i.item_cantidad*i.item_precio) >  (select avg(f2.fact_total)
					      from Factura f2
					      where year(f2.fact_fecha)=2012
					      )
order by case when count(distinct i.item_producto) between 5 and 10 then 1 else 0 end desc




/*
SQL_parcial_2022_11_15
1.Realizar una consulta SQL que permita saber los clientes que compraron todos los rubros disponibles del sistema en el 2012.
De estos clientes mostrar, siempre para el 2012: 
	1.El código del cliente
	2.Código de producto que en cantidades más compro.
	3.El nombre del producto del punto 2.
	4.Cantidad de productos distintos comprados por el cliente.
	5.Cantidad de productos con composición comprados por el cliente.
El resultado deberá ser ordenado por razón social del cliente alfabéticamente primero y luego, los clientes que compraron entre un 20 % y 30% del total facturado 
en el 2012 primero, luego, los restantes,*/


select c.clie_codigo, c.clie_razon_social,
	(select top 1 i.item_producto from Item_Factura i
		join Factura f on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
		where f.fact_cliente = c.clie_codigo and YEAR(f.fact_fecha) = 2012
		group by i.item_producto
		order by sum(i.item_cantidad) desc) as max_prod,
	(select top 1 p.prod_detalle from Item_Factura i
		join Producto p on p.prod_codigo = i.item_producto
		join Factura f on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
		where f.fact_cliente = c.clie_codigo and YEAR(f.fact_fecha) = 2012
		group by i.item_producto, p.prod_detalle
		order by sum(i.item_cantidad) desc) as max_prod_det,
	(select COUNT(distinct i.item_producto) from Item_Factura i
		join Factura f on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
		where f.fact_cliente = c.clie_codigo and YEAR(f.fact_fecha) = 2012) as cant_prod,
	(select COUNT(distinct i.item_producto) from Item_Factura i
		join Composicion comp on comp.comp_producto = i.item_producto
		join Factura f on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
		where f.fact_cliente = c.clie_codigo and YEAR(f.fact_fecha) = 2012) as cant_com_prod
	 from Cliente c
	 where 
		(select COUNT(distinct p.prod_rubro) from Item_Factura i
			join Producto p on p.prod_codigo = i.item_producto
			join Factura f on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
			where f.fact_cliente = c.clie_codigo and YEAR(f.fact_fecha) = 2012) = (select COUNT(distinct rubr_id) from Rubro)
	 group by c.clie_codigo, c.clie_razon_social
	 order by c.clie_razon_social, 
		case when (select SUM(f.fact_total) from Factura f where f.fact_cliente = c.clie_codigo and YEAR(f.fact_fecha)=2012) between 
			(select SUM(f.fact_total) from Factura f where YEAR(f.fact_fecha)=2012) * 0.2 and
			(select SUM(f.fact_total) from Factura f where YEAR(f.fact_fecha)=2012) *0.3 then 1 else 0 end des

/* SQL_parcial_2022_11_22
pensar en un big mac : buger papa coca
Realizar una consulta SQL que muestre aquellos productos que tengan 3 componentes a nivel producto y cuyos componentes tengan 2 rubros distintos.
De estos productos mostrar:
	 i.El código de producto.
	 ii.El nombre del producto.
	 iii.La cantidad de veces que fueron vendidos sus componentes en el 2012.
	 iv.Monto total vendido del producto.
El resultado ser ordenado por cantidad de facturas del 2012 en las cuales se vendieron los componentes.*/

select p.prod_codigo,p.prod_detalle,
	ISNULL((select SUM(i.item_cantidad) from item_factura i 
				join Composicion c2 on c2.comp_componente = i.item_producto
				join Factura f on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
				where c2.comp_producto = p.prod_codigo and YEAR(f.fact_fecha) = 2012
				group by c2.comp_producto),0) as cant_vent_comp,
	ISNULL((select SUM(i.item_precio * i.item_cantidad) from Item_Factura i
				join Factura f on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
				where i.item_producto = p.prod_codigo and YEAR(f.fact_fecha) = 2012),0) as monto_toal
	from Producto p
	join Composicion c on c.comp_producto = p.prod_codigo
	group by p.prod_codigo,p.prod_detalle
	having COUNT(distinct comp_componente) > 1 /*se tiene q cambiar a 3*/ 
		and (select COUNT(distinct p2.prod_rubro) from producto p2 
			join Composicion c2 on p2.prod_codigo = c2.comp_componente
			where c2.comp_producto = p.prod_codigo) > 1
	order by 
		(select COUNT(distinct f.fact_numero + f.fact_sucursal +f.fact_tipo) from Item_Factura i
			join Factura f on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
			join Composicion c2 on c2.comp_componente = i.item_producto
			where c2.comp_producto = p.prod_codigo and YEAR(f.fact_fecha) = 2012
			group by c2.comp_producto) desc

/*
SQL_parcial_2023_06_27_TM
I.Realizar una consulta SQL que retorne para todas las zonas que tengan 3 (tres) o más depósitos.
	Detalle Zona
	Cantidad de Depósitos x Zona
	Cantidad de Productos distintos compuestos en sus depósitos
	Producto mas vendido en el año 2012 que tonga stock en al menos uno de sus depósitos.
	Mejor encargado perteneciente a esa zona (El que mas vendió en la historia).
El resultado deberá ser ordenado por monto total vendido del encargado DESC.*/


select z.zona_codigo, z.zona_detalle ,COUNT(d.depo_codigo) as cant_depos,  
	(select COUNT(distinct s.stoc_producto) from STOCK s
		join DEPOSITO d2 on s.stoc_deposito = d2.depo_codigo
		where d2.depo_zona = z.zona_codigo and s.stoc_producto in (select distinct comp_producto from Composicion)) as cant_prod,
	(select top 1 i.item_producto from Item_Factura i
		join Factura f on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
		join Producto p on i.item_producto = p.prod_codigo
		join STOCK s on s.stoc_producto = p.prod_codigo
		join DEPOSITO d3 on s.stoc_deposito = d3.depo_codigo
		where YEAR(f.fact_fecha) = 2012 and d3.depo_zona = z.zona_codigo
		group by i.item_producto
		order by SUM(i.item_cantidad) desc) as max_prod_zona,
	(select top 1 e.empl_codigo from Empleado e
		join DEPOSITO d4 on d4.depo_encargado = e.empl_codigo
		join Factura f on f.fact_vendedor = e.empl_codigo
		where d4.depo_zona = z.zona_codigo
		group by e.empl_codigo
		order by SUM(f.fact_total) desc) as encargado_top
	from DEPOSITO d
	join Zona z on d.depo_zona = z.zona_codigo
	group by z.zona_detalle,z.zona_codigo
	having count(distinct d.depo_codigo) >= 3
	order by 
		(select top 1 SUM(f.fact_total) from Empleado e
			join DEPOSITO d5 on d5.depo_encargado = e.empl_codigo
			join Factura f on f.fact_vendedor = e.empl_codigo
			where d5.depo_zona = z.zona_codigo
			group by e.empl_codigo, f.fact_vendedor
			order by SUM(f.fact_total) desc) desc


/*
SQL_parcial_2023_06_27_TN
1. Realizar una consulta SOL que retorne para los 10 clientes que más compraron en el 2012 y que fueron atendldos por más de 3 vendedores distintos:
	Apellido y Nombro del Cliento.
	Cantidad de Productos distmtos comprados en el 2012,
	Cantidad de unidades compradas dentro del pomer semestre del 2012.
El resultado deberá mostrar ordenado ta cantidad de ventas descendente del 2012 de cada cliente, en caso de igualdad de ventasi ordenar porcódigo de cliente.
*/

select top 10 c.clie_razon_social,
	(select COUNT(distinct i.item_producto) from Item_Factura i
		join Factura f2 on f2.fact_numero + f2.fact_sucursal +f2 .fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
		where f2.fact_cliente = c.clie_codigo and YEAR(f2.fact_fecha) = 2012) as cant_prod_2012,
	(select SUM(i.item_cantidad) from Item_Factura i
		join Factura f2 on f2.fact_numero + f2.fact_sucursal +f2 .fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
		where f2.fact_cliente = c.clie_codigo and month(f2.fact_fecha) <= 6 and  YEAR(f2.fact_fecha) = 2012) as cant_prim_sem
	from Cliente c
	join Factura f on f.fact_cliente = c.clie_codigo
	where YEAR(f.fact_fecha) = 2012
	group by c.clie_razon_social, c.clie_codigo
	--having COUNT(distinct f.fact_vendedor) >= 3
	order by COUNT (distinct  f.fact_numero + f.fact_sucursal +f.fact_tipo) desc, c.clie_codigo 


/*
SQL_parcial_2023_06_29
1.Realizar una consulta SQL que devuelva todos los clientes que durante 2 años consecutivos compraron al menos 5 productos distintos. 
De esos clientes mostrar:
	El codigo de cliente
	El monto total comprado en el 2012
	La cantidad de unidades de productos compradas en el 2012
El resultado debe ser ordenado primero por aquellos clientes que compraron solo productos compuestos en algun momento, luego el resto.*/


select f.fact_cliente, SUM(f.fact_total) as monto, SUM(i.item_cantidad) as cant_unidades from Factura f
	join Item_Factura i on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
	where YEAR(f.fact_fecha) = 2012
	group by f.fact_cliente
	having (select top 1 COUNT(distinct i2.item_producto) + COUNT(distinct i3.item_producto) from Factura f2
				join Item_Factura i2 on f2.fact_numero + f2.fact_sucursal +f2 .fact_tipo = i2.item_numero + i2.item_sucursal + i2.item_tipo 
				join Factura f3 on f2.fact_cliente = f3.fact_cliente
				join Item_Factura i3 on f3.fact_numero + f3.fact_sucursal +f3 .fact_tipo = i3.item_numero + i3.item_sucursal + i3.item_tipo 
				where f2.fact_cliente = f.fact_cliente and DATEDIFF(YEAR,f2.fact_fecha,f3.fact_fecha) = 1 and i2.item_producto != i3.item_producto) > 4
	order by case when f.fact_cliente in 
		(select f.fact_cliente from Factura f2
			join Item_Factura i2 on f2.fact_numero + f2.fact_sucursal +f2 .fact_tipo = i2.item_numero + i2.item_sucursal + i2.item_tipo
			join Composicion comp on comp.comp_producto = i2.item_producto) then 0 else 1 end asc




/* 
SQL_parcial_2023_07_01
1. Realizar una consulta SQL que muestre aquellos clientes que en 2 años consecutivos compraron.
De estos clientes mostrar
	i.El código de cliente.
	iii.El nombre del cliente.
	iv.El numero de rubros que compro el cliente.
	La cantidad de productos con composición que compro el cliente en el 2012.
El resultado deberá ser ordenado por cantidad de facturas del cliente en toda la historia, de manera ascendente.*/

select c.clie_codigo, c.clie_razon_social,
	COUNT(distinct p2.prod_rubro)  as rubros,
	ISNULL((select SUM(i.item_cantidad) from Item_Factura i
		join Producto p on p.prod_codigo = i.item_producto
		join Factura f on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
		where f.fact_cliente = c.clie_codigo and i.item_producto in (select comp.comp_producto from Composicion comp) 
			and YEAR(f.fact_fecha) = 2012),0) as prod_comp
	from Cliente c
	join Factura f2 on f2.fact_cliente = c.clie_codigo
	join Item_Factura i2 on f2.fact_numero + f2.fact_sucursal +f2 .fact_tipo = i2.item_numero + i2.item_sucursal + i2.item_tipo
	join Producto p2 on i2.item_producto = p2.prod_codigo
	where
		(select SUM(i.item_cantidad) from Item_Factura i
			join Factura f on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
			where YEAR(f.fact_fecha) = YEAR(f2.fact_fecha) and f.fact_cliente = c.clie_codigo) > 0 and
		(select SUM(i.item_cantidad) from Item_Factura i
			join Factura f on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
			where YEAR(f.fact_fecha) = YEAR(f2.fact_fecha) + 1 and f.fact_cliente = c.clie_codigo) > 0 
	group by c.clie_codigo, c.clie_razon_social		
	order by COUNT(distinct f2.fact_numero + f2.fact_sucursal +f2.fact_tipo) asc


/*
X_SQL_parcial_2022_11_19
I.Realizar una consulta SQL que permita saber los clientes que compraron en el 2012 al menos 1 unidad de todos los productos compuestos.
De estos clientes mostrar, siempre para el 2012:
		1. El código del cliente
		2. Código de producto que en cantidades más compro.
		3. El número de fila según el orden establecido con un alias llamado ORDINAL. 
		4. Cantidad de productos distintos comprados por el cliente.
		5. Monto total comprado.
El resultado deberá ser ordenado por razón social del cliente alfabéticamente primero y luego, los clientes que compraron entre un 20 % y 30% del 
total facturado en el 2012 primero, luego, los restantes.*/

select c.clie_codigo,
	(select top 1 i.item_producto from Item_Factura i
		join Factura f on f.fact_numero + f.fact_sucursal +f.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo
		where f.fact_cliente = c.clie_codigo
		group by i.item_producto
		order by SUM(i.item_cantidad)) as max_prod,
	ROW_NUMBER() 
		over (order by c.clie_razon_social, case when (select SUM(f.fact_total) from Factura f) 
				between (select SUM(f.fact_total) from Factura f where YEAR(f.fact_fecha) = 2012) *0.2 and
						(select SUM(f.fact_total) from Factura f where YEAR(f.fact_fecha) = 2012)*0.3 then 1 else 0 end desc) as ordinal,
	COUNT (distinct i2.item_producto) as cant_prod,
	SUM(f2.fact_total) as monto_total
	from Cliente c
	join Factura f2 on f2.fact_cliente = c.clie_codigo
	join Item_Factura i2 on f2.fact_numero + f2.fact_sucursal +f2 .fact_tipo = i2.item_numero + i2.item_sucursal + i2.item_tipo
	left join Composicion comp on comp.comp_producto = i2.item_producto
	where YEAR(f2.fact_fecha) = 2012
	group by c.clie_codigo, c.clie_razon_social
	having (select COUNT(distinct comp_producto) from Composicion) = COUNT(comp.comp_producto)






