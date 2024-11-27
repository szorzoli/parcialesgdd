create table comisiones (
	com_empl numeric(6),
	com_empl_comision decimal (12,2),
	com_fact_numero char(8),
	com_fact_sucursal char(4),
	com_fact_tipo char (1),
	com_fact_comision decimal(12,2),
	com_fact_fecha smalldatetime
	)


alter procedure pr_comisiones
as
begin
	declare @com_empl numeric(6)
	declare @com_empl_comision decimal (12,2)
	declare @com_fact_numero char(8)
	declare @com_fact_sucursal char(4)
	declare @com_fact_tipo char (1)
	declare @com_fact_comision decimal(12,2)
	declare @com_fact_fecha smalldatetime

	declare c_comisiones cursor for
		select f.fact_vendedor, e.empl_comision, f.fact_numero,f.fact_sucursal,f.fact_tipo,(e.empl_comision/SUM(f.fact_total)), f.fact_fecha from Factura f
			join Empleado e on e.empl_codigo = f.fact_vendedor
			group by f.fact_vendedor, e.empl_comision, f.fact_numero,f.fact_sucursal,f.fact_tipo, f.fact_fecha

	open c_comisones 
	fetch next from c_comisones into @com_empl,@com_empl_comision,@com_fact_numero,@com_fact_sucursal,@com_fact_tipo,@com_fact_comision,@com_fact_fecha
	while @@FETCH_STATUS = 0
		begin
			if (select e.empl_comision from Empleado e join Factura f on e.empl_codigo = f.fact_vendedor
				where YEAR(f.fact_fecha) = YEAR(@com_fact_fecha) and month(f.fact_fecha) = month(@com_fact_fecha) and e.empl_codigo = @com_empl) =
				(select e.empl_comision from Empleado e join Factura f on e.empl_codigo = f.fact_vendedor
				where YEAR(f.fact_fecha) = YEAR(@com_fact_fecha) and month(f.fact_fecha) = month(@com_fact_fecha)-1 and e.empl_codigo = @com_empl)
				begin
					insert into comisiones (com_empl,com_empl_comision,com_fact_numero ,com_fact_sucursal,com_fact_tipo,com_fact_comision,com_fact_fecha)
						values (@com_empl,@com_empl_comision,@com_fact_numero,@com_fact_sucursal,@com_fact_tipo,@com_fact_comision,@com_fact_fecha)
				end
			fetch next from c_comisones into @com_empl,@com_empl_comision,@com_fact_numero,@com_fact_sucursal,@com_fact_tipo,@com_fact_comision,@com_fact_fecha
		end
	close c_comisones
	deallocate c_comisones
end*/

create trigger tr_comisiones on empleado instead of update
as
begin
	declare @fecha smalldatetime
	set @fecha = (select top 1 f.fact_fecha from  Factura f join inserted i on f.fact_vendedor = i.empl_codigo order by f.fact_fecha desc)
	if (select i.empl_comision from inserted i) = 
		(select e.empl_comision from Empleado e join Factura f on f.fact_vendedor = e.empl_codigo 
			where MONTH(f.fact_fecha) = MONTH(@fecha) and year(f.fact_fecha) = year(@fecha))
		begin
			update Empleado set empl_comision = (select i.empl_comision from inserted i) where empl_codigo = (select i.empl_codigo from inserted i) 
		end
	else 
		rollback
end

CREATE VIEW comisiones_mensuales 
AS
	SELECT MONTH(f.fact_fecha) AS mes, c.com_empl, SUM(c.com_fact_comision) AS comi_total FROM comisiones AS c
		JOIN Factura AS f ON f.fact_numero = c.com_fact_numero AND f.fact_sucursal = c.com_fact_sucursal AND f.fact_tipo = c.com_fact_tipo