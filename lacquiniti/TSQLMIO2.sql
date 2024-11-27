CREATE PROCEDURE PROD_VENT 
AS
BEGIN
	DECLARE @item_tipo char(1) 
	DECLARE @item_sucursal char(4) 
	DECLARE @item_numero char(8) 
	DECLARE @item_producto char(8) 
	DECLARE @item_cantidad decimal(12,2)
	DECLARE @item_precio decimal(12,2)

	DECLARE C_ERROR_VENT CURSOR FOR
		SELECT IT.item_tipo, IT.item_sucursal,IT.item_numero, IT.item_producto, IT.item_cantidad, IT.item_precio FROM Item_Factura IT

	OPEN C_ERROR_VENT
	FETCH NEXT FROM C_ERROR_VENT INTO @item_tipo,@item_sucursal,@item_numero,@item_producto,@item_cantidad,@item_precio
	WHILE @@FETCH_STATUS = 0
		BEGIN 
			IF @item_producto IN (SELECT comp_producto FROM Composicion)
				BEGIN
					DELETE FROM Item_Factura WHERE item_producto = @item_producto 
						and item_numero = @item_numero and item_sucursal = @item_sucursal and item_tipo = @item_tipo

					INSERT INTO Item_Factura
						SELECT @item_tipo, @item_sucursal, @item_numero, C.comp_componente, @item_cantidad, P.prod_precio * @item_cantidad 
							FROM Composicion C
							JOIN Producto P ON C.comp_componente = P.prod_codigo
							WHERE C.comp_producto = @item_producto
				END
		END

	CLOSE C_ERROR_VENT
	DEALLOCATE C_ERROR_VENT
END


CREATE TRIGGER TRIG_VENT ON Item_Factura instead of INSERT
AS
BEGIN
	DECLARE @item_tipo char(1) 
	DECLARE @item_sucursal char(4) 
	DECLARE @item_numero char(8) 
	DECLARE @item_producto char(8) 
	DECLARE @item_cantidad decimal(12,2)
	DECLARE @item_precio decimal(12,2)

	DECLARE C_ERROR_VENT CURSOR FOR
		SELECT IT.item_tipo, IT.item_sucursal,IT.item_numero, IT.item_producto, IT.item_cantidad, IT.item_precio FROM inserted IT

	OPEN C_ERROR_VENT
	FETCH NEXT FROM C_ERROR_VENT INTO @item_tipo,@item_sucursal,@item_numero,@item_producto,@item_cantidad,@item_precio
	WHILE @@FETCH_STATUS = 0
		BEGIN 
			IF @item_producto IN (SELECT comp_producto FROM Composicion)
				BEGIN
					INSERT INTO Item_Factura
						SELECT @item_tipo, @item_sucursal, @item_numero, C.comp_componente, @item_cantidad, P.prod_precio * @item_cantidad 
							FROM Composicion C
							JOIN Producto P ON C.comp_componente = P.prod_codigo
							WHERE C.comp_producto = @item_producto
				END
		END

	CLOSE C_ERROR_VENT
	DEALLOCATE C_ERROR_VENT
END