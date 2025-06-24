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

ALTER FUNCTION sumatoria_precio_componentes(@codigo_producto CHAR(8))
RETURNS INT
AS
BEGIN
        DECLARE @componente CHAR(8), @precio_final DECIMAL(12,2) = 0 ,@cantidad_componente INT ,@precio_componente DECIMAL(12,2)

        if exists( SELECT * FROM Composicion C where C.comp_producto = @codigo_producto )
                begin
                        DECLARE el_cursor CURSOR FOR 
                                SELECT 
                                C.comp_componente, P.prod_precio,C.comp_cantidad
                                FROM Composicion C
                                        INNER JOIN Producto P ON
                                                P.prod_codigo = C.comp_componente
                                WHERE C.comp_producto = @codigo_producto

                        OPEN el_cursor
                        FETCH NEXT FROM el_cursor INTO  @componente, @precio_componente,@cantidad_componente
                        WHILE(@@FETCH_STATUS = 0)
                                BEGIN
                                        IF NOT EXISTS(SELECT * FROM Composicion C1 WHERE C1.comp_producto = @componente)
                                                BEGIN
                                                        SET @precio_final = @precio_final + @precio_componente*@cantidad_componente
                                                END
                                        ELSE
                                                BEGIN
                                                        SET @precio_final = @precio_final + dbo.sumatoria_precio_componentes(@componente) * @cantidad_componente
                                                END
                                        FETCH NEXT FROM el_cursor INTO  @componente, @precio_componente,@cantidad_componente
                                END

                        CLOSE el_cursor
                        DEALLOCATE el_cursor
                end

        RETURN @precio_final
END


GO
ALTER PROCEDURE verificar_cumplimiento_combos        -- SE DEBE EJECUTAR A MANO 1 VEZ PARA PONER AL DIA LA VERIFICACIÒN
as
BEGIN
        declare @comp_producto char(8)                

                DECLARE cd_cursor CURSOR FOR
                SELECT 
                        C.comp_producto
                FROM Producto P
                        INNER JOIN Composicion C
                                ON P.prod_codigo = C.comp_producto 

        OPEN cd_cursor
                FETCH NEXT FROM cd_cursor INTO @comp_producto
                while(@@FETCH_STATUS = 0)
                        begin
                                --acciones
                                UPDATE Producto
                                SET prod_precio = dbo.sumatoria_precio_componentes(@comp_producto) * 0.9
                                WHERE prod_codigo = @comp_producto;

                                FETCH NEXT FROM cd_cursor INTO @comp_producto
                        end
        CLOSE cd_cursor
        DEALLOCATE cd_cursor
END


GO
alter TRIGGER trigerActualizadorProductos ON Producto AFTER INSERT
AS
BEGIN 
        exec verificar_cumplimiento_combos
END

GO
CREATE TRIGGER trigerActualizadorCombos ON Composicion AFTER INSERT,UPDATE
AS
BEGIN 
        exec verificar_cumplimiento_combos
END

SELECT C.comp_producto,P.prod_precio FROM Composicion C INNER JOIN Producto P ON P.prod_codigo = C.comp_producto


-- OTRA VERSION ABAJO:


--interpreto que el control es manual para cada producto composicion.
GO
CREATE FUNCTION sumatoria_precio_componentes(@codigo_producto_compuesto char(8))
RETURNS decimal(12,2)
AS
BEGIN

        DECLARE @componente char(8), @cantidad_componente decimal(12,2)
        DECLARE @sumatoria_precio_componentes decimal(12,2) = 0

        DECLARE cursor_funcion CURSOR FOR
                select 
                        C.comp_componente,
                        C.comp_cantidad
                from Composicion C 
                where C.comp_producto = @codigo_producto_compuesto

                        OPEN cursor_funcion
                                FETCH NEXT FROM cursor_funcion INTO @componente, @cantidad_componente
                                WHILE(@@FETCH_STATUS = 0)
                                        BEGIN
                                                --ACCIONES
                                                IF NOT EXISTS(SELECT * FROM Composicion C1 WHERE C1.comp_producto = @componente)
                                                        BEGIN        --si no existe , el componente no es un producto compuesto
                                                                set @sumatoria_precio_componentes = @sumatoria_precio_componentes + ((select P.prod_precio from Producto P where P.prod_codigo = @componente) * @cantidad_componente)
                                                        END
                                                ELSE
                                                        BEGIN -- el componente del producto compuesto, es otro producto compuesto
                                                                set @sumatoria_precio_componentes = @sumatoria_precio_componentes + dbo.sumatoria_precio_componentes(@componente)
                                                        END
                                                FETCH NEXT FROM cursor_funcion INTO @componente, @cantidad_componente
                                        END
                        CLOSE cursor_funcion
                        DEALLOCATE cursor_funcion
        RETURN @sumatoria_precio_componentes
END




------ si el ejericio fuera para corregir los productos composicion manualmente.
GO
CREATE PROCEDURE actualizarPrecioProductoComposicion (@producto_composicion char(8)) 
AS
BEGIN
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE

        UPDATE Producto
        SET prod_precio = dbo.sumatoria_precio_componentes(@producto_composicion)
        WHERE prod_codigo = @producto_composicion;
END
GO

-- para actualizar todos los productos composicion en un proccedure
GO
CREATE PROCEDURE actualizarPrecioProductoComposicion () 
AS
BEGIN
        declare @comp_producto char(8)
        SET tRaNsACtiOn isolation LEVEL SERIALIZABLE

                DECLARE mi_cursor CURSOR FOR
                SELECT 
                        C.comp_producto
                FROM Producto P
                        INNER JOIN Composicion C
                                ON P.prod_codigo = C.comp_producto 

        OPEN mi_cursor
                FETCH NEXT FROM mi_cursor INTO @comp_producto
                while(@@FETCH_STATUS = 0)
                        begin
                                UPDATE Producto
                                SET prod_precio = dbo.sumatoria_precio_componentes(@comp_producto) * 0.9
                                WHERE prod_codigo = @comp_producto;

                                FETCH NEXT FROM mi_cursor INTO @comp_producto
                        end
        CLOSE mi_cursor
        DEALLOCATE mi_cursor
END
GO


-- problema: si actualizan la cantidad en composicion, no se da cuenta
CREATE TRIGGER trigerActualizador ON Producto AFTER INSERT,UPDATE
AS
BEGIN 
        declare @comp_producto char(8)
        SET tRaNsACtiOn isolation LEVEL SERIALIZABLE

                DECLARE mi_cursor CURSOR FOR
                SELECT 
                        C.comp_producto
                FROM Producto P
                        INNER JOIN Composicion C
                                ON P.prod_codigo = C.comp_producto 

        OPEN mi_cursor
                FETCH NEXT FROM mi_cursor INTO @comp_producto
                while(@@FETCH_STATUS = 0)
                        begin
                                --acciones
                                UPDATE Producto
                                SET prod_precio = dbo.sumatoria_precio_componentes(@comp_producto) * 0.9
                                WHERE prod_codigo = @comp_producto;

                                FETCH NEXT FROM mi_cursor INTO @comp_producto
                        end
        CLOSE mi_cursor
        DEALLOCATE mi_cursor
END






----------------------------------------------------------------------------------------------------------


Select C.comp_producto , 
dbo.sumatoria_precio_componentes(C.comp_producto) as precio_funcion,
C.comp_componente,
P.prod_precio,
C.comp_cantidad,
P.prod_precio * C.comp_cantidad as precioXcantidad
from Composicion C
INNER JOIN Producto P 
        ON P.prod_codigo = C.comp_componente

--select * from Composicion C2 
--        join Producto on C2.comp_producto = prod_codigo