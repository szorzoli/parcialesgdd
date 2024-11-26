--use GD2015C1
/*
X_TSQL_2023_07_04_TM.sql
2. Actualmente el campo fact_vendedor representa al empleado que vendió la factura. Implementar el/los objetos necesarios para respetar la 
integridad referenciales de dicho campo suponiendo que no existe una foreign key entre ambos.
NOTA: No se puede usar una foreign key para el ejercicio, deberá buscar*/
otro método

create table fact_rechazadas(
	rech_numero char(8),
	rech_vendedor numeric(6)
)


alter procedure pr_fact_ven
as
begin
	insert into fact_rechazadas (rech_numero,rech_vendedor)
		select fact_numero, fact_vendedor from Factura
			where fact_vendedor not in (select empl_codigo from Empleado)

	if exists (select 1 from fact_rechazadas)
		begin
			select * from fact_rechazadas
			--raiserror ('error en las siguientes facturas',16,1)
		end
end


alter trigger tr_fact_ven on factura instead of insert,update
as
begin
	
	declare @vendedor numeric(6)
	
	declare c_ven_err cursor for
		select fact_vendedor from inserted

	open c_ven_err
	fetch next from c_ven_err into  @vendedor
	while @@FETCH_STATUS = 0
		begin
			if @vendedor not in (select empl_codigo from Empleado)
			begin
				raiserror ('no existe el vendedor',16,1)
				rollback transaction
			end
		end
	fetch next from c_ven_err into  @vendedor
	close c_ven_err
	deallocate c_ven_err	
end



truncate table fact_rechazadas
exec dbo.pr_fact_ven
--select * from Empleado
--select * from Factura*/


/*
X_TSQL_2023_07_04.sql
2. Se requiere realizar una verificación de los precios de los COMBOS, para ello se solicita que cree el o los objetos necesarios para realizar 
una operación que actualice que el precio de un producto compuesto (COMBO) es el 90% de la suma de los precios de sus componentes por las 
cantidades que los componen. Se debe considerar que un producto compuesto puede estar compuesto por otros productos compuestos.
	Pensamientos para encararlo:
	-Una funcion que me devuelve la sumatoria del precio de los componentes de un producto compuesto. Para eso esa funcion deberia fijarse si ese 
	producto compuesto tiene un producto compuesto dentro de si mismo.

	- Un proccedure que le pasamos el codigo de un producto compuesto y le actualiza el precio utilizando la funcion que hicimos anteriormente*/



alter function fun_combos (@prod char(8))
	returns decimal(12,2)
begin 
	declare @total decimal(12,2)
	set @total =  (select SUM(dbo.fun_combos(comp_componente)) from Composicion where comp_producto = @prod)

	if @total is null
		begin
			set @total = (select prod_precio from Producto where prod_codigo = @prod)
		end
	return @total
end

alter procedure prod_combos
as
begin
	declare @prod char(8)

	declare c_combos cursor for
		select prod_codigo from Producto where prod_codigo in (select comp_producto from Composicion)

	open c_combos
	fetch next from c_combos into  @prod
	while @@FETCH_STATUS = 0
		begin
			update Producto set prod_precio = dbo.fun_combos(@prod) * 0.9 where prod_codigo = @prod
			fetch next from c_combos into  @prod
		end
	close c_combos
	deallocate c_combos
end



/*
X_TSQL_2022_11_15.sq
1. Implementar una regla de negocio en línea que al realizar una venta (SOLO INSERCION) permita componer los productos descompuestos, es decir, 
si se guardan en la factura 2 hamb. 2 papas 2 gaseosas se deberá guardar en la factura 2 (DOS) COMBO 1. Si 1 combo 1 equivale a: 1 hamb. 1 papa y 
1 gaseosa.

Nota: Considerar que cada vez que se guardan los items, se mandan todos los productos de ese item a la vez, y no de manera parcial.*/


Create trigger tr_combo on factura instead of insert
As
Begin
	declare @combo char(8)
	Declare @tipo char(1)
	Declare @sucursal char(4)
	Declare @numero char(8)

	Declare c_combos cursor for Select fact_tipo, fact_sucursal, fact_numero from inserted

	Open c_combos
	Fetch next from c_combos into @tipo, @sucursal, @numero
	While @@FETCH_STATUS = 0
		Begin
			declare @cant decimal (12,2)
			declare @cantcombo decimal(12,2)

			declare c_prod cursor for
				select c.comp_producto, i.item_cantidad from Item_Factura i
					join Composicion c on i.item_producto = c.comp_componente
					where i.item_numero = @numero
						and i.item_sucursal = @sucursal
						and i.item_tipo = @tipo
						and c.comp_producto = @combo
					group by c.comp_producto
					having COUNT(*) = (select COUNT(*) from Composicion c2 where c.comp_producto = c2.comp_producto)
			
			Open c_prod
			Fetch next from c_prod into @combo, @cant
			While @@FETCH_STATUS = 0
				begin
					select @cantcombo = @cant/c.comp_cantidad from Item_Factura i
						join Composicion c on i.item_producto = c.comp_componente
						where i.item_numero = @numero
							and i.item_sucursal = @sucursal
							and i.item_tipo = @tipo
							and c.comp_producto = @combo
					
					insert into Item_Factura (item_tipo, item_numero, item_sucursal, item_cantidad, item_producto, item_precio)
									select @tipo, @numero, @sucursal, @cantcombo, @combo, (select prod_precio from Producto	where prod_codigo = @combo) * @cantcombo
																														
					Fetch next from c_prod into @combo, @cant
				end

			close c_prod
			deallocate c_prod
			Fetch next from c_combos into @tipo, @sucursal, @numero

		End
		close c_combos
		deallocate c_combos
End



/*
TSQL_2023_07_08
2. Por un error de programación la tabla item factura le ejecutaron DROP a la primary key y a sus foreign key.Este evento permitió la inserción de filas duplicadas 
(exactas e iguales) y también inconsistencias debido a la falta de FK. Realizar un algoritmo que resuelva este inconveniente depurando los datos de manera coherente 
y lógica y que deje la estructura de la tabla item factura de manera correcta*/

create table item_factura_corregido(
	item_tipo char(1), 
	item_sucursal char(4), 
	item_numero char(8), 
	item_producto char(8), 
	item_cantidad decimal(12,2),
	item_precio decimal(12,2)
)

insert into item_factura_corregido (item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio)
	select distinct item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio from Item_Factura

alter table item_factura_corregido add foreign key (item_tipo, item_sucursal, item_numero) references factura (fact_tipo, fact_sucursal, fact_numero)
alter table item_factura_corregido add foreign key (item_producto) references producto (prod_codigo)

 

 /*
TSQL_2023_07_01
2. Implementar una regla de negocio para mantener siempre consistente (actualizada bajo cualquier circunstancia) INSERT UPDATE DELETE una nueva tabla llamada 
PRODUCTOS_VENDIDOS. En esta tabla debe registrar el periodo (YYYYMM), el código de producto, el precio máximo de venta y las unidades vendidas. Toda esta 
información debe estar por periodo (YYYYMM).*/


create table PRODUCTOS_VENDIDOS(
	periodo char(6),
	codigo char(8),
	precio_max decimal(12,2),
	cant decimal (12,2)
)


create procedure prod_PRODUCTOS_VENDIDOS
as
begin
	insert into PRODUCTOS_VENDIDOS (periodo,codigo,precio_max,cant)
		select CONCAT(YEAR(f.fact_fecha),MONTH(f.fact_fecha)), i.item_producto, MAX(i.item_precio), SUM(i.item_cantidad) from Item_Factura i
			join Factura f ON i.item_numero = f.fact_numero
				and i.item_sucursal = f.fact_sucursal
				and i.item_tipo= f.fact_tipo
			group by CONCAT(YEAR(f.fact_fecha),MONTH(f.fact_fecha)),i.item_producto
end

create trigger tr_PRODUCTOS_VENDIDOS on Item_Factura instead of insert, update, delete
as
begin
	declare @periodo char(6)
	declare @codigo char(8)
	declare @precio_max decimal(12,2)
	declare @cant decimal (12,2)

	declare c_PRODUCTOS_VENDIDOS cursor for
		select CONCAT(YEAR(f.fact_fecha),MONTH(f.fact_fecha)), i.item_producto, MAX(i.item_precio), SUM(i.item_cantidad) from Item_Factura i
				join Factura f ON i.item_numero = f.fact_numero
					and i.item_sucursal = f.fact_sucursal
					and i.item_tipo= f.fact_tipo
				group by CONCAT(YEAR(f.fact_fecha),MONTH(f.fact_fecha)),i.item_producto

	open c_PRODUCTOS_VENDIDOS
	fetch next from c_PRODUCTOS_VENDIDOS into @periodo, @codigo, @precio_max, @cant
	while @@FETCH_STATUS = 0
		begin
			if not exists (select 1 from PRODUCTOS_VENDIDOS where periodo= @periodo and codigo=@codigo)
				begin
					insert into PRODUCTOS_VENDIDOS values (@periodo, @codigo, @precio_max, @cant)
				end
			else
				begin
					update PRODUCTOS_VENDIDOS 
						set cant = cant + @cant,
							precio_max = case when (@precio_max > precio_max) then @precio_max else precio_max
						where periodo= @periodo and codigo=@codigo
				end
			fetch next from c_PRODUCTOS_VENDIDOS into @periodo, @codigo, @precio_max, @cant
		end
	close c_PRODUCTOS_VENDIDOS
	deallocate c_PRODUCTOS_VENDIDOS
end



exec dbo.prod_PRODUCTOS_VENDIDOS
select * from PRODUCTOS_VENDIDOS


/*
TSQL_2023_06_29
2. Suponiendo que se aplican los siguientes cambios en el modelo de datos:
Cambio 1) create table provincia (id 'int primary key, nómbre char(100)) ;
Cambio 2) alter table cliente add pcia_id int null:
Crear el/los objetos necesarios para implementar el concepto de foreign key entre 2 cliente y provincia,
Nota: No se permite agregar una constraint de tipo FOREIGN KEY entre la tabla y el campo agregado.

--create table provincia (id int primary key, nómbre char(100))
--alter table cliente add pcia_id int null*/

create trigger tr_provincia on cliente instead of insert, update
as
begin
	declare @prov int

	declare c_prov cursor for
		select pcia_id from inserted

	open c_prov
	fetch next from c_prov into @prov
	while @@FETCH_STATUS = 0
		begin
			if not exists (select 1 from Provincia where id = @prov)
				begin
					raiserror('no existe la provincia',16,1)
					rollback
				end
			fetch next from c_prov into @prov
		end
end


insert into Cliente (clie_codigo, clie_razon_social, clie_telefono, clie_domicilio, clie_limite_credito, clie_vendedor,pcia_id)
	values ('6666','kkkk','null','xxxx','3648.00','4','99')


/*
TSQL_2022_11_22
1. Implementar una regla de negocio en línea donde se valide que nunca un producto compuesto pueda estar compuesto por componentes de rubros distintos a el.

*/
create function fun_rubros (@prod char(8))
	returns int
begin
	declare @comp char(8)
	declare c_rubros cursor for select comp_componente from Composicion where comp_producto = @prod

	open c_rubros
	fetch next from c_rubros into @comp
	while @@FETCH_STATUS = 0
	begin
		if (select prod_rubro from Producto where prod_codigo = @comp) != (select prod_rubro from Producto where prod_codigo = @prod)
			begin
				return 0
			end

		fetch next from c_rubros into @comp
	end

	close c_rubros
	deallocate c_rubros

	return 1
end

alter trigger tr_rubros on producto instead of insert,update
as
begin
	if(select dbo.fun_rubros(i.prod_codigo) from inserted i) = 0
		begin
			raiserror('no puede haber productos compuestos por roductos de diferentes rubros',16,1)
			rollback transaction
		end
end

insert into Producto (prod_codigo,prod_detalle,prod_envase,prod_familia,prod_precio,prod_rubro)
	values ('11111111','kkk','1','999','24483.75','001')

insert into Composicion (comp_producto,comp_componente,comp_cantidad)
	values('11111111','00001711','1.00'),
		  ('11111111','00001531','1.00')

update Producto set prod_precio = '5555.00' where prod_codigo = '11111111'


/*
TSQL_2022_11_19
1. Implementar una regla de negocio en línea donde nunca una factura nueva tenga un precio de producto distinto al que figura en la tabla PRODUCTO. 
Registrar en una estructura adicional todos los casos donde se intenta guardar un precio distinto.*/

create table precios_mal(
	prod_cod char(8),
	prod_precio decimal(12,2),
	item_precio decimal(12,2),
	item_tipo char(1),
	item_sucursal char(4),
	item_numero char(8),
)


alter trigger tr_precios_mal on Item_Factura instead of insert
as
begin
	declare @prod char(8)
	declare @precio_item decimal(12,2)
	Declare @tipo char(1)
	Declare @sucursal char(4)
	Declare @numero char(8)
	declare @precio_prod decimal(12,2)
	declare @cant decimal(12,2)

	declare c_precios_mal cursor for 
		select i.item_producto,i.item_precio,i.item_tipo,i.item_sucursal,i.item_numero,i.item_cantidad from inserted i

	open c_precios_mal
	fetch next from c_precios_mal into @prod,@precio_item,@tipo,@sucursal,@numero,@cant
	while @@FETCH_STATUS = 0
		begin
			set @precio_prod = (select prod_precio from Producto where prod_codigo = @prod)
			if @precio_prod != @precio_item
				begin
					insert into precios_mal values(@prod,@precio_prod,@precio_item,@tipo,@sucursal,@numero)
					
					insert into Item_Factura values(@tipo,@sucursal,@numero,@prod,@cant,@precio_prod)
				end
			else
			begin
				insert into Item_Factura values(@tipo,@sucursal,@numero,@prod,@cant,@precio_item)
			end
			update Factura 
				set fact_total = 
					(select SUM(i.item_precio * i.item_cantidad) from Item_Factura i 
						where i.item_numero = @numero
						and i.item_sucursal = @sucursal
						and i.item_tipo = @tipo
						group by i.item_numero,i.item_sucursal,i.item_tipo
					)
				where fact_numero = @numero and fact_sucursal = @sucursal and fact_tipo = @tipo
		end
	close c_precios_mal
	deallocate c_precios_mal
end



--select * from producto
--select * from Item_Factura

drop trigger tr_fact_ven

/*
TSQL_2022_11_12
2. Implementar una regla de negocio de validación en línea que permita validar el STOCK al realizarse una venta. Cada venta se debe descontar 
sobre el depósito 00. En caso de que se venda un producto compuesto, el descuento de stock se debe realizar por sus componentes. Si no hay 
STOCK para ese artículo, no se deberá guardar ese artículo, pero si los otros en los cuales hay stock positivo. Es decir, solamente se deberán 
guardar aquellos para los cuales si hay stock, sin guardarse los que no poseen cantidades suficientes.*/


create trigger tr_stock on Item_Factura instead of insert
as
begin
	declare @prod char(8)
	declare @cant decimal(12,2)
	
	set @prod = (select i.item_producto from inserted i)
	set @cant = (select i.item_cantidad from inserted i)

	if @prod in (select comp_producto from Composicion)
		begin
			
			declare @comp char(8)
			declare @cantcomp decimal(12,2)

			declare c_stock cursor for
				select i.item_producto, c.comp_componente, i.item_cantidad, c.comp_cantidad from inserted i
					join Composicion c on i.item_producto = c.comp_producto
			open c_stock
			fetch next from c_stock into @prod,@comp,@cant,@cantcomp
			while @@FETCH_STATUS = 0
				begin
					if (@cant *@cantcomp) <= (select stoc_cantidad from STOCK where stoc_deposito = '0' and stoc_producto = @comp)
						begin
							update STOCK set stoc_cantidad = stoc_cantidad - (@cant *@cantcomp)
								where stoc_deposito = '00' and stoc_producto = @comp
							insert into Item_Factura (item_tipo,item_sucursal,item_numero,item_producto,item_cantidad,item_precio)  
								select * from inserted 
						end
					else 
						rollback
					fetch next from c_stock into @prod,@comp,@cant,@cantcomp
				end
		end
	else
		begin
			if @cant <= (select stoc_cantidad from STOCK where stoc_deposito = '0' and stoc_producto = @prod)
						begin
							update STOCK set stoc_cantidad = stoc_cantidad - @cant
								where stoc_deposito = '00' and stoc_producto = @prod
							insert into Item_Factura (item_tipo,item_sucursal,item_numero,item_producto,item_cantidad,item_precio)  
								select * from inserted 
						end
					else 
						rollback
	
		end 
end


/*
TSQL_2021_XX_XX
2. Implementar una regla de negocio de validación en línea que permita implementar una lógica de control de precios en las ventas. Se deberá
poder seleccionar una lista de rubros y aquellos productos de los rubros que sean los seleccionados no podrán aumentar por mes más de un 2%. 
En caso que no se tenga referencia del mes anterior no validar dicha regla.*/


create table rub_sel(
	rubr_id char(4)
)

create trigger tr_rubr on producto instead of update
as
begin
	declare @mes char(2)
	set @mes = (select MONTH(f.fact_fecha) from inserted i
				join Item_Factura it on i.prod_codigo = it.item_producto
				join Factura f on f.fact_numero + f.fact_sucursal +f.fact_tipo = it.item_numero + it.item_sucursal + it.item_tipo ) 
	if (select i.prod_rubro from inserted i) in (select rubr_id from rub_sel)
		begin
			if 
			(select it.item_precio from inserted i
				join Item_Factura it on i.prod_codigo = it.item_producto) 			
			>(select it.item_precio from inserted i
				join Item_Factura it on i.prod_codigo = it.item_producto
				join Factura f on f.fact_numero + f.fact_sucursal +f.fact_tipo = it.item_numero + it.item_sucursal + it.item_tipo
				where MONTH(f.fact_fecha) = @mes +1) *1.02
				begin
					rollback
				end
			else
				begin
					update Producto set prod_precio = (select i.prod_precio from inserted i)
						where prod_codigo = (select i.prod_rubro from inserted i)
				end
		end
	else
		begin
			update Producto set prod_precio = (select i.prod_precio from inserted i)
				where prod_codigo = (select i.prod_rubro from inserted i)
		end
end














































