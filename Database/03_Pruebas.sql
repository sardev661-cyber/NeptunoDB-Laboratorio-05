-- Pruebas de integración reales. Ejecutar después de 01 y 02 en SQL Server.
-- Todo se revierte con ROLLBACK; los contadores IDENTITY sí pueden avanzar.
-- No presupone que los IDs de los datos originales sigan siendo 1 a 5.
USE NeptunoDB;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @cat int, @prov int, @prod int, @ped int, @filas int;
    EXEC dbo.usp_Categorias_Insertar N'LAB05 prueba', N'Categoría temporal', @filas OUTPUT, @cat OUTPUT;
    IF @filas <> 1 OR @cat IS NULL THROW 51001, N'Falla insertar categoría.', 1;
    EXEC dbo.usp_Categorias_Actualizar @cat, N'LAB05 editada', N'Actualizada', @filas OUTPUT;
    IF NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE CategoriaID=@cat AND NombreCategoria=N'LAB05 editada' AND Activo=1)
        THROW 51002, N'Falla actualizar categoría o valor Activo inicial.', 1;

    EXEC dbo.usp_Proveedores_Insertar N'LAB05 proveedor', N'ZZLAB05Contacto', NULL, NULL, N'ZZLAB05Ciudad', NULL, NULL, NULL, NULL, @filas OUTPUT, @prov OUTPUT;
    EXEC dbo.usp_Proveedores_Actualizar @prov, N'LAB05 proveedor editado', N'ZZLAB05Contacto', NULL, NULL, N'ZZLAB05Ciudad', NULL, NULL, NULL, NULL, @filas OUTPUT;
    IF NOT EXISTS (SELECT 1 FROM dbo.Proveedores WHERE ProveedorID=@prov AND CompaniaNombre=N'LAB05 proveedor editado' AND Activo=1)
        THROW 51003, N'Falla CRUD proveedor.', 1;
    CREATE TABLE #Proveedores (ProveedorID int, CompaniaNombre nvarchar(60), NombreContacto nvarchar(40), CargoContacto nvarchar(40), Direccion nvarchar(80), Ciudad nvarchar(30), CodigoPostal nvarchar(10), Pais nvarchar(30), Telefono nvarchar(24), Fax nvarchar(24), Activo bit);
    INSERT INTO #Proveedores EXEC dbo.usp_Proveedores_Buscar N'LAB05Contacto', N'LAB05Ciudad';
    IF NOT EXISTS (SELECT 1 FROM #Proveedores WHERE ProveedorID=@prov) THROW 51004, N'Falla búsqueda combinada parcial.', 1;
    TRUNCATE TABLE #Proveedores;
    INSERT INTO #Proveedores EXEC dbo.usp_Proveedores_Buscar N'LAB05Contacto', N'ZZNoCoincide';
    IF EXISTS (SELECT 1 FROM #Proveedores WHERE ProveedorID=@prov) THROW 51005, N'Los filtros deben combinarse con AND.', 1;

    EXEC dbo.usp_Productos_Insertar N'LAB05 producto', @prov, @cat, N'1 unidad', 10.00, 20, 0, 5, 0, @filas OUTPUT, @prod OUTPUT;
    EXEC dbo.usp_Productos_Actualizar @prod, N'LAB05 producto editado', @prov, @cat, N'1 unidad', 12.50, 25, 0, 5, 0, @filas OUTPUT;
    IF NOT EXISTS (SELECT 1 FROM dbo.Productos WHERE ProductoID=@prod AND PrecioUnidad=12.50 AND Activo=1)
        THROW 51006, N'Falla CRUD producto.', 1;

    EXEC dbo.usp_Pedidos_Insertar NULL, NULL, '20990110', '20990111', NULL, NULL, N'LAB05 destino', N'Lima', N'Perú', @filas OUTPUT, @ped OUTPUT;
    EXEC dbo.usp_Pedidos_Actualizar @ped, NULL, NULL, '20990110', '20990112', NULL, NULL, N'LAB05 editado', N'Lima', N'Perú', @filas OUTPUT;
    IF NOT EXISTS (SELECT 1 FROM dbo.Pedidos WHERE PedidoID=@ped AND Destinatario=N'LAB05 editado' AND Activo=1)
        THROW 51007, N'Falla CRUD pedido.', 1;
    -- Detalle de prueba para verificar INNER JOIN e importe neto.
    INSERT INTO dbo.DetallePedidos (PedidoID,ProductoID,PrecioUnidad,Cantidad,Descuento) VALUES (@ped,@prod,12.50,2,0.10);
    CREATE TABLE #Reporte (PedidoID int,FechaPedido date,Destinatario nvarchar(60),ProductoID int,NombreProducto nvarchar(60),PrecioUnidad decimal(10,2),Cantidad smallint,Descuento decimal(4,2),Importe decimal(18,2));
    INSERT INTO #Reporte EXEC dbo.usp_DetallePedidos_PorFechas '20990110','20990110';
    IF NOT EXISTS (SELECT 1 FROM #Reporte WHERE PedidoID=@ped AND Importe=22.50)
        THROW 51008, N'Falla intervalo inclusivo o cálculo del reporte.', 1;
    TRUNCATE TABLE #Reporte;
    INSERT INTO #Reporte EXEC dbo.usp_DetallePedidos_PorFechas '20990111','20990112';
    IF EXISTS (SELECT 1 FROM #Reporte WHERE PedidoID=@ped) THROW 51009, N'Falla exclusión fuera del intervalo.', 1;

    EXEC dbo.usp_Productos_Eliminar @prod, @filas OUTPUT;
    IF NOT EXISTS (SELECT 1 FROM dbo.Productos WHERE ProductoID=@prod AND Activo=0) THROW 51010, N'Producto debe conservarse inactivo.', 1;
    TRUNCATE TABLE #Reporte;
    INSERT INTO #Reporte EXEC dbo.usp_DetallePedidos_PorFechas '20990110','20990110';
    IF NOT EXISTS (SELECT 1 FROM #Reporte WHERE PedidoID=@ped) THROW 51011, N'Debe conservarse historial del producto inactivo.', 1;
    EXEC dbo.usp_Pedidos_Eliminar @ped, @filas OUTPUT;
    IF NOT EXISTS (SELECT 1 FROM dbo.Pedidos WHERE PedidoID=@ped AND Activo=0) THROW 51012, N'Pedido debe conservarse inactivo.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.DetallePedidos WHERE PedidoID=@ped) THROW 51013, N'La baja del pedido no debe borrar detalles.', 1;
    TRUNCATE TABLE #Reporte;
    INSERT INTO #Reporte EXEC dbo.usp_DetallePedidos_PorFechas '20990110','20990110';
    IF EXISTS (SELECT 1 FROM #Reporte WHERE PedidoID=@ped) THROW 51014, N'El reporte debe excluir pedidos inactivos.', 1;
    EXEC dbo.usp_Categorias_Eliminar @cat, @filas OUTPUT;
    EXEC dbo.usp_Proveedores_Eliminar @prov, @filas OUTPUT;
    IF NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE CategoriaID=@cat AND Activo=0) THROW 51015, N'Categoría debe conservarse inactiva.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.Proveedores WHERE ProveedorID=@prov AND Activo=0) THROW 51016, N'Proveedor debe conservarse inactivo.', 1;
    TRUNCATE TABLE #Proveedores;
    INSERT INTO #Proveedores EXEC dbo.usp_Proveedores_Buscar N'LAB05Contacto', N'LAB05Ciudad';
    IF EXISTS (SELECT 1 FROM #Proveedores WHERE ProveedorID=@prov) THROW 51017, N'La búsqueda debe excluir proveedores inactivos.', 1;
    ROLLBACK TRANSACTION;
    PRINT N'OK: altas, actualizaciones, bajas lógicas, filtros, fechas, importes e historial. Datos temporales revertidos.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
-- Debe fallar con el mensaje de intervalo válido; se prueba fuera de la transacción anterior.
BEGIN TRY
    EXEC dbo.usp_DetallePedidos_PorFechas '20260930','20260901';
    THROW 51018, N'ERROR: se aceptó un intervalo invertido.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 50007 THROW;
    PRINT N'OK: intervalo invertido rechazado.';
END CATCH;
GO
