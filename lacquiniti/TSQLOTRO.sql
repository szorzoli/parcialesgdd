--2
/*
CREATE TABLE MasVendidos (
	mas_codigo char(8),
	mas_anio int,
	mas_detalle char(50),
	mas_cantidad decimal(12,2),
	PRIMARY KEY(mas_codigo,mas_anio))*/
	
	

ALTER PROCEDURE PROD_VENT 
AS
BEGIN
	DECLARE @CONT INT
	DECLARE @PROD char(8)
	DECLARE @DET char(50)
	DECLARE @CANT decimal(12,2)
	DECLARE @ANIO INT
	DECLARE @RENG INT

	SET @CONT = 10
	DECLARE C_VENT_MAX CURSOR FOR
		SELECT I.item_producto, YEAR(F.fact_fecha), P.prod_detalle, SUM(I.item_cantidad),
			ROW_NUMBER() OVER(PARTITION BY YEAR(F.fact_fecha)  ORDER BY SUM(I.item_cantidad) DESC) AS ranking FROM Item_Factura I
			JOIN Producto P ON P.prod_codigo = I.item_producto
			JOIN Factura F ON I.item_numero = F.fact_numero
				AND I.item_sucursal = F.fact_sucursal
				AND I.item_tipo= F.fact_tipo
		GROUP BY I.item_producto, P.prod_detalle,YEAR(F.fact_fecha)
	OPEN C_VENT_MAX
	FETCH NEXT FROM C_VENT_MAX INTO @PROD, @ANIO, @DET, @CANT, @RENG
	WHILE @@FETCH_STATUS = 0
		BEGIN
			 IF @RENG <= @CONT
				BEGIN
					INSERT INTO MasVendidos VALUES(@PROD, @ANIO, @DET, @CANT)
				END
			FETCH NEXT FROM C_VENT_MAX INTO @PROD, @ANIO, @DET, @CANT, @RENG
		END
	CLOSE C_VENT_MAX
	DEALLOCATE C_VENT_MAX
END


ALTER TRIGGER TRIG_MASVENT ON Item_Factura INSTEAD OF INSERT
AS
BEGIN
	IF (SELECT SUM(i.item_cantidad) FROM inserted i GROUP BY i.item_producto) > 
		(SELECT TOP 1 M.mas_cantidad FROM MasVendidos M
			WHERE M.mas_anio = 
				(SELECT YEAR(F.fact_fecha) FROM inserted i 
					JOIN Factura F ON i.item_numero + i.item_sucursal + i.item_tipo = F.fact_numero + F.fact_sucursal + F.fact_tipo)
			--GROUP BY M.mas_cantidad
			ORDER BY M.mas_cantidad)
		BEGIN
			DELETE FROM MasVendidos WHERE mas_codigo = 
				(SELECT TOP 1 M.mas_cantidad FROM MasVendidos M WHERE M.mas_anio = (SELECT YEAR(F.fact_fecha) FROM inserted i 
					JOIN Factura F ON i.item_numero + i.item_sucursal + i.item_tipo = F.fact_numero + F.fact_sucursal + F.fact_tipo))
			INSERT INTO MasVendidos
				SELECT i.item_producto,YEAR(F.fact_fecha), P.prod_detalle, SUM(i.item_cantidad) FROM inserted i
					JOIN Factura F ON i.item_numero + i.item_sucursal + i.item_tipo = F.fact_numero + F.fact_sucursal + F.fact_tipo
					JOIN Producto P ON i.item_producto = P.prod_codigo 
				GROUP BY I.item_producto, P.prod_detalle,YEAR(F.fact_fecha)
		END
	
END




--EXEC dbo.PROD_VENT
--SELECT * FROM MasVendidos



	

				

				
				