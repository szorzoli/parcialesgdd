--2
/*2. Implementar una regla de negocio en línea que registre los productos
que al momento de venderse registraron un aumento superior al 10 %
del precio de venta que tuvieron en el mes anterior. Se deberá registrar
el producto, la fecha en el cual se hace la venta, el precio anterior y el
precio nuevo.*/

/*
CREATE TABLE Aumentos (
	aum_cod char(8),
	aum_fecha smalldatetime,
	aum_precio_viejo decimal(12,2),
	aum_precio_nuevo decimal(12,2),
	PRIMARY KEY(aum_cod))
	*/


ALTER TRIGGER TRIG_AUM ON Item_Factura AFTER  INSERT
AS
BEGIN
	DECLARE @aum_cod char(8)
	DECLARE @aum_fecha smalldatetime
	DECLARE @aum_precio_viejo decimal(12,2)
	DECLARE @aum_precio_nuevo decimal(12,2)


	DECLARE C_AUM CURSOR FOR
		SELECT i.item_producto, F.fact_fecha, 
			(SELECT MAX(IT.item_precio) FROM Item_Factura IT
				JOIN Factura F2 ON IT.item_numero + IT.item_sucursal + IT.item_tipo = F2.fact_numero + F2.fact_sucursal + F2.fact_tipo
				WHERE IT.item_producto = i.item_producto AND MONTH(F2.fact_fecha) = DATEADD(MONTH, -1, f.fact_fecha) ), 
				i.item_precio FROM inserted i
			JOIN Factura F ON i.item_numero + i.item_sucursal + i.item_tipo = F.fact_numero + F.fact_sucursal + F.fact_tipo
			GROUP BY i.item_producto,F.fact_fecha, i.item_precio

	OPEN C_AUM
	FETCH NEXT FROM C_AUM INTO @aum_cod, @aum_fecha, @aum_precio_viejo, @aum_precio_nuevo
	WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @aum_precio_nuevo > @aum_precio_viejo * 1.1
				BEGIN
					INSERT INTO Aumentos VALUES (@aum_cod, @aum_fecha, @aum_precio_viejo, @aum_precio_nuevo)
				END

			FETCH NEXT FROM C_AUM INTO @aum_cod, @aum_fecha, @aum_precio_viejo, @aum_precio_nuevo
		END

	CLOSE C_AUM
	DEALLOCATE C_AUM
END

drop table aumento_precio_en_10

create table aumento_precio_en_10 (
	producto char(8),
	fecha datetime,
	precio_actual decimal(12,2),
	precio_anterior decimal(12,2)
)

alter trigger precios_aumeto_10porc on Item_Factura
after insert
as
begin
	declare @producto char(8)
	declare @precio_distinto decimal(12,2)
	declare @precio_viejo decimal(12,2)
	declare @fecha_compra datetime

	declare cursor_productos cursor for	
		select i.item_producto, i.item_precio as nuevo_precio, i2.item_precio as viejo_precio, f.fact_fecha
		from inserted i
		join Factura f on i.item_tipo = f.fact_tipo AND i.item_sucursal = f.fact_sucursal AND i.item_numero = f.fact_numero
		JOIN Item_Factura i2 ON i2.item_producto = i.item_producto
		JOIN Factura f2 ON i2.item_tipo = f2.fact_tipo AND i2.item_sucursal = f2.fact_sucursal AND i2.item_numero = f2.fact_numero
		where i2.item_precio < i.item_precio + i2.item_precio * 0.1 and month(f2.fact_fecha) = MONTH(f.fact_fecha) - 1 

	open cursor_productos
	fetch next from cursor_productos into @producto, @precio_distinto, @precio_viejo, @fecha_compra

	while @@fetch_status = 0
	begin
		insert into aumento_precio_en_10 (producto, fecha, precio_actual, precio_anterior)
		values (@producto, @precio_distinto, @precio_viejo, @fecha_compra)	
		fetch next from cursor_productos into @producto, @precio_distinto, @precio_viejo, @fecha_compra
	end
	close cursor_productos
	deallocate cursor_productos
end