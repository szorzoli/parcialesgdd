--4/7/2023
create trigger tr_fact_vendedor on Factura instead of insert
as
begin
	if exists (select 1 from inserted i where not exists (select 1 from Empleado where i.fact_vendedor = empl_codigo))
		begin
			raiserror('no existe el vendedor')
			rollback transaction
			return
		end
	else
		begin
			insert into 
				Factura (fact_cliente, fact_fecha, fact_numero, fact_sucursal, fact_tipo, fact_total, 
					fact_total_impuestos,fact_vendedor)
				select fact_cliente, fact_fecha, fact_numero, fact_sucursal, fact_tipo, fact_total, 
					fact_total_impuestos,fact_vendedor 
					from inserted
		end
end

--4/7/2023
create procedure prod_consecutivos (@produc char(8), @fecha smalldatetime, @cont_dias int OUTPUT)
as
begin
	if not exists
		(select 1 from Factura f 
			join Item_Factura i ON i.item_tipo =f.fact_tipo AND i.item_sucursal = F.fact_sucursal 
				AND i.item_numero = F.fact_numero
			where i.item_producto = @produc and f.fact_fecha = @fecha)
		begin
			set @cont_dias = 0
			return
		end

	else
		begin
			set @cont_dias = 1
			declare @c_fecha smalldatetime

			declare c_dias cursor for
				select f.fact_fecha from Factura f 
					join Item_Factura i ON i.item_tipo =f.fact_tipo AND i.item_sucursal = F.fact_sucursal 
						AND i.item_numero = F.fact_numero
					where i.item_producto = @produc and f.fact_fecha > @fecha
					group by f.fact_fecha
					order by f.fact_fecha asc
	
			open c_dias 
			FETCH NEXT FROM c_dias into @c_fecha

			while @@FETCH_STATUS = 0
				begin
					set @fecha = @fecha + 1
					if @fecha != @c_fecha
						begin
							return
						end
					else
						begin
							set @cont_dias = @cont_dias + 1
							FETCH NEXT FROM c_dias into @c_fecha
						end
				end
			
			close c_dias
			deallocate c_dias
		end
end

--25/06/2024
create trigger ver_precios on Item_factura instead of insert
as
begin
	declare @precio decimal(12,2)
	declare @produc char(8)
	declare @fecha smalldatetime

	declare c_precios cursor for
		select i.item_precio,i.item_producto, f.fact_fecha from inserted i
			join Factura f ON i.item_tipo = f.fact_tipo AND i.item_sucursal = f.fact_sucursal 
				AND i.item_numero = f.fact_numero

	declare @precio_mes_ant decimal(12,2)
	declare @precio_anio_ant decimal(12,2)

	open c_precios 
	FETCH NEXT FROM c_precios into @precio,@produc,@fecha

	while @@FETCH_STATUS = 0
		begin
			set @precio_mes_ant = 
				(select top 1 it.item_precio from Item_Factura it
					join Factura f ON it.item_tipo = f.fact_tipo AND it.item_sucursal = f.fact_sucursal 
						AND it.item_numero = f.fact_numero
					where  it.item_producto= @produc 
						and month(f.fact_fecha) = month(DATEADD(month,-1,@fecha)) 
						and year(f.fact_fecha) = year(DATEADD(month,-1,@fecha))
					order by f.fact_fecha desc) 
			set @precio_anio_ant = 
				(select top 1 it.item_precio from Item_Factura it
					join Factura f ON it.item_tipo = f.fact_tipo AND it.item_sucursal = f.fact_sucursal 
						AND it.item_numero = f.fact_numero
					where it.item_producto=@produc 
						and month(f.fact_fecha) = month(DATEADD(YEAR,-1,@fecha)) 
						and year(f.fact_fecha) = year(DATEADD(year,-1,@fecha))
					order by f.fact_fecha desc)

			if @precio_mes_ant is not null and
				(@precio < @precio_mes_ant or @precio > @precio_mes_ant *1.05)
				begin
					raiserror('el precio no cumple las normas de negocio')
					rollback transaction
				end

			if @precio_anio_ant is not null and @precio_mes_ant > @precio_anio_ant *1.5
				begin
					raiserror('el precio no cumple las normas de negocio')
					rollback transaction
				end

			FETCH NEXT FROM c_precios into @tipo,@sucursal,@numero,@precio,@produc,@fecha
		end

		close c_precios
		deallocate c_precios
end

--25/6/2024
create table clie_mensaje(
	men_clie char(6),
	men_nombre char(100),
	men_mensaje char (100)
)

create procedure noti_clien
as
begin
	declare @cliente char(6)
	declare @nombre char(100)

	declare c_clie cursor for
		select F.fact_cliente, c.clie_razon_social from Item_Factura i
			join Factura f on i.item_numero = f.fact_numero and i.item_sucursal = f.fact_sucursal and i.item_tipo = f.fact_tipo
			join Producto p  on i.item_producto = p.prod_codigo
			join Rubro r on p.prod_rubro = r.rubr_id
			join Cliente c on f.fact_cliente = c.clie_codigo
			where (r.rubr_detalle = 'PILAS'  or r.rubr_detalle = 'PASTILLAS') and c.clie_limite_credito<15000
			GROUP BY f.fact_cliente, c.clie_razon_social
			order by f.fact_cliente
	
	open c_clie
	FETCH NEXT FROM c_clie into @cliente, @nombre

	while @@FETCH_STATUS = 0
		begin
			insert into clie_mensaje 
				values(@cliente,@nombre, 'Recuerde solicitar su regalo sorpresa en su proxima compra')
			FETCH NEXT FROM c_clie into @cliente, @nombre
		end

	deallocate c_clie
	close c_clie
end

--11/7/23
create table Reponer_stock(
	repo_produc char(8),
	repo_produc decimal(12,2)
)

create procedure tr_repo (@fechabase smalldatetime)
as
begin
	declare @fechafin smalldatetime 
	set @fechafin = dateadd(month,-3,@fechabase)

	insert into Reponer_stock(repo_produc,repo_produc)
		select i.item_producto, SUM(i.item_cantidad)/3 from Item_Factura i
			JOIN Factura f on i.item_numero = f.fact_numero and i.item_sucursal = f.fact_sucursal and i.item_tipo = f.fact_tipo
			where f.fact_fecha <= @fechabase and f.fact_fecha >= @fechafin
			group by i.item_producto
end

select fl.fami_id, fl.fami_detalle from Familia fl