--2
CREATE TABLE Auditoria(
	aud_id int IDENTITY (1,1) PRIMARY KEY,
	aud_codigo char(6),
	aud_razon_social char(100),
	aud_telefono char(100),
	aud_domicilio char(100),
	aud_limite_credito decimal(12,2),
	aud_vendedor numeric(6),
	aud_opercaion char(20),
	aud_fecha smalldatetime DEFAULT GETDATE())

CREATE TRIGGER AUD_INS ON Cliente INSTEAD OF INSERT
AS
BEGIN
	INSERT INTO Auditoria (aud_codigo,aud_razon_social,aud_telefono,aud_domicilio,aud_limite_credito,aud_vendedor,aud_opercaion)
		SELECT i.clie_codigo, i.clie_razon_social, i.clie_telefono, i.clie_domicilio, i.clie_limite_credito, i.clie_vendedor, 
			'INSERT' FROM inserted i
END

CREATE TRIGGER AUD_UP ON Cliente INSTEAD OF UPDATE
AS
BEGIN
	INSERT INTO Auditoria (aud_codigo,aud_razon_social,aud_telefono,aud_domicilio,aud_limite_credito,aud_vendedor,aud_opercaion)
		SELECT i.clie_codigo + d.clie_codigo, i.clie_razon_social+ d.clie_razon_social, i.clie_telefono +d.clie_telefono, 
		i.clie_domicilio + d.clie_domicilio, i.clie_limite_credito + d.clie_limite_credito, i.clie_vendedor + d.clie_vendedor, 'UPDATE' 
		FROM inserted i
		JOIN deleted d on i.clie_codigo = d.clie_codigo
END

CREATE TRIGGER AUD_DEL ON Cliente INSTEAD OF INSERT
AS
BEGIN
	INSERT INTO Auditoria (aud_codigo,aud_razon_social,aud_telefono,aud_domicilio,aud_limite_credito,aud_vendedor,aud_opercaion)
		SELECT d.clie_codigo, d.clie_razon_social, d.clie_telefono, d.clie_domicilio, d.clie_limite_credito, d.clie_vendedor, 
			'DELETE' FROM deleted d
END

CREATE TRIGGER AUD_OM ON Cliente INSTEAD OF INSERT, DELETE, UPDATE
AS
BEGIN
	IF (SELECT COUNT(*) FROM inserted) > 1 OR (SELECT COUNT(*) FROM deleted) > 1
		BEGIN
			INSERT INTO Auditoria (aud_opercaion) VALUES('OPERACION_MASIVA')
			RAISERROR ('NO SE PUEDEN REALIZAR OPERACIONES MASIVAS',16,1)
			ROLLBACK
			RETURN
		END
	IF EXISTS (SELECT * FROM inserted)
		BEGIN
			INSERT INTO Cliente SELECT * FROM inserted
		END
	IF EXISTS (SELECT * FROM deleted)
		BEGIN
			DELETE FROM Cliente WHERE clie_codigo IN (SELECT clie_codigo FROM deleted)
		END
END