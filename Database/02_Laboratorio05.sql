-- Laboratorio 05. Ejecutar después de 01_NeptunoDB.sql. SQL Server 2016 SP1 o superior.
USE NeptunoDB;
GO

IF COL_LENGTH(N'dbo.Categorias', N'Activo') IS NULL
    ALTER TABLE dbo.Categorias ADD Activo bit NOT NULL CONSTRAINT DF_Categorias_Activo DEFAULT(1) WITH VALUES;
GO

IF COL_LENGTH(N'dbo.Proveedores', N'Activo') IS NULL
    ALTER TABLE dbo.Proveedores ADD Activo bit NOT NULL CONSTRAINT DF_Proveedores_Activo DEFAULT(1) WITH VALUES;
GO

IF COL_LENGTH(N'dbo.Productos', N'Activo') IS NULL
    ALTER TABLE dbo.Productos ADD Activo bit NOT NULL CONSTRAINT DF_Productos_Activo DEFAULT(1) WITH VALUES;
GO

IF COL_LENGTH(N'dbo.Pedidos', N'Activo') IS NULL
    ALTER TABLE dbo.Pedidos ADD Activo bit NOT NULL CONSTRAINT DF_Pedidos_Activo DEFAULT(1) WITH VALUES;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Categorias_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CategoriaID, NombreCategoria, Descripcion, Activo FROM dbo.Categorias WHERE Activo = 1 ORDER BY CategoriaID;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Categorias_Insertar
    @NombreCategoria nvarchar(30),
    @Descripcion nvarchar(200),
    @FilasAfectadas int OUTPUT,
    @NuevoID int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @FilasAfectadas = 0;
    IF @NombreCategoria IS NULL OR LEN(LTRIM(RTRIM(@NombreCategoria))) = 0 THROW 50001, N'NombreCategoria es obligatorio.', 1;
    INSERT INTO dbo.Categorias (NombreCategoria, Descripcion)
    VALUES (@NombreCategoria, @Descripcion);
    SET @FilasAfectadas = @@ROWCOUNT;
    SET @NuevoID = CONVERT(int, SCOPE_IDENTITY());
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Categorias_Actualizar
    @CategoriaID int,
    @NombreCategoria nvarchar(30),
    @Descripcion nvarchar(200),
    @FilasAfectadas int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @FilasAfectadas = 0;
    IF @NombreCategoria IS NULL OR LEN(LTRIM(RTRIM(@NombreCategoria))) = 0 THROW 50001, N'NombreCategoria es obligatorio.', 1;
    UPDATE dbo.Categorias SET
        NombreCategoria = @NombreCategoria,
        Descripcion = @Descripcion
    WHERE CategoriaID = @CategoriaID AND Activo = 1;
    SET @FilasAfectadas = @@ROWCOUNT;
    IF @FilasAfectadas = 0 THROW 50005, N'El registro no existe o ya está inactivo.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Categorias_Eliminar
    @CategoriaID int,
    @FilasAfectadas int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @FilasAfectadas = 0;
    IF EXISTS (SELECT 1 FROM dbo.Productos WHERE CategoriaID = @CategoriaID AND Activo = 1)
        THROW 50006, N'Hay productos activos vinculados. Reasígnelos o déselos de baja primero.', 1;
    UPDATE dbo.Categorias SET Activo = 0 WHERE CategoriaID = @CategoriaID AND Activo = 1;
    SET @FilasAfectadas = @@ROWCOUNT;
    IF @FilasAfectadas = 0 THROW 50005, N'El registro no existe o ya está inactivo.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Proveedores_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProveedorID, CompaniaNombre, NombreContacto, CargoContacto, Direccion, Ciudad, CodigoPostal, Pais, Telefono, Fax, Activo FROM dbo.Proveedores WHERE Activo = 1 ORDER BY ProveedorID;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Proveedores_Insertar
    @CompaniaNombre nvarchar(60),
    @NombreContacto nvarchar(40),
    @CargoContacto nvarchar(40),
    @Direccion nvarchar(80),
    @Ciudad nvarchar(30),
    @CodigoPostal nvarchar(10),
    @Pais nvarchar(30),
    @Telefono nvarchar(24),
    @Fax nvarchar(24),
    @FilasAfectadas int OUTPUT,
    @NuevoID int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @FilasAfectadas = 0;
    IF @CompaniaNombre IS NULL OR LEN(LTRIM(RTRIM(@CompaniaNombre))) = 0 THROW 50001, N'CompaniaNombre es obligatorio.', 1;
    INSERT INTO dbo.Proveedores (CompaniaNombre, NombreContacto, CargoContacto, Direccion, Ciudad, CodigoPostal, Pais, Telefono, Fax)
    VALUES (@CompaniaNombre, @NombreContacto, @CargoContacto, @Direccion, @Ciudad, @CodigoPostal, @Pais, @Telefono, @Fax);
    SET @FilasAfectadas = @@ROWCOUNT;
    SET @NuevoID = CONVERT(int, SCOPE_IDENTITY());
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Proveedores_Actualizar
    @ProveedorID int,
    @CompaniaNombre nvarchar(60),
    @NombreContacto nvarchar(40),
    @CargoContacto nvarchar(40),
    @Direccion nvarchar(80),
    @Ciudad nvarchar(30),
    @CodigoPostal nvarchar(10),
    @Pais nvarchar(30),
    @Telefono nvarchar(24),
    @Fax nvarchar(24),
    @FilasAfectadas int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @FilasAfectadas = 0;
    IF @CompaniaNombre IS NULL OR LEN(LTRIM(RTRIM(@CompaniaNombre))) = 0 THROW 50001, N'CompaniaNombre es obligatorio.', 1;
    UPDATE dbo.Proveedores SET
        CompaniaNombre = @CompaniaNombre,
        NombreContacto = @NombreContacto,
        CargoContacto = @CargoContacto,
        Direccion = @Direccion,
        Ciudad = @Ciudad,
        CodigoPostal = @CodigoPostal,
        Pais = @Pais,
        Telefono = @Telefono,
        Fax = @Fax
    WHERE ProveedorID = @ProveedorID AND Activo = 1;
    SET @FilasAfectadas = @@ROWCOUNT;
    IF @FilasAfectadas = 0 THROW 50005, N'El registro no existe o ya está inactivo.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Proveedores_Eliminar
    @ProveedorID int,
    @FilasAfectadas int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @FilasAfectadas = 0;
    IF EXISTS (SELECT 1 FROM dbo.Productos WHERE ProveedorID = @ProveedorID AND Activo = 1)
        THROW 50006, N'Hay productos activos vinculados. Reasígnelos o déselos de baja primero.', 1;
    UPDATE dbo.Proveedores SET Activo = 0 WHERE ProveedorID = @ProveedorID AND Activo = 1;
    SET @FilasAfectadas = @@ROWCOUNT;
    IF @FilasAfectadas = 0 THROW 50005, N'El registro no existe o ya está inactivo.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Productos_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductoID, NombreProducto, ProveedorID, CategoriaID, CantidadPorUnidad, PrecioUnidad, UnidadesEnExistencia, UnidadesEnPedido, NivelDeReorden, Descontinuado, Activo FROM dbo.Productos WHERE Activo = 1 ORDER BY ProductoID;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Productos_Insertar
    @NombreProducto nvarchar(60),
    @ProveedorID int,
    @CategoriaID int,
    @CantidadPorUnidad nvarchar(30),
    @PrecioUnidad decimal(10,2),
    @UnidadesEnExistencia smallint,
    @UnidadesEnPedido smallint,
    @NivelDeReorden smallint,
    @Descontinuado bit,
    @FilasAfectadas int OUTPUT,
    @NuevoID int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @FilasAfectadas = 0;
    IF @NombreProducto IS NULL OR LEN(LTRIM(RTRIM(@NombreProducto))) = 0 THROW 50001, N'NombreProducto es obligatorio.', 1;
    IF @PrecioUnidad IS NULL THROW 50001, N'PrecioUnidad es obligatorio.', 1;
    IF @PrecioUnidad < 0 THROW 50002, N'PrecioUnidad no puede ser negativo.', 1;
    IF @UnidadesEnExistencia IS NULL THROW 50001, N'UnidadesEnExistencia es obligatorio.', 1;
    IF @UnidadesEnExistencia < 0 THROW 50002, N'UnidadesEnExistencia no puede ser negativo.', 1;
    IF @UnidadesEnPedido IS NULL THROW 50001, N'UnidadesEnPedido es obligatorio.', 1;
    IF @UnidadesEnPedido < 0 THROW 50002, N'UnidadesEnPedido no puede ser negativo.', 1;
    IF @NivelDeReorden IS NULL THROW 50001, N'NivelDeReorden es obligatorio.', 1;
    IF @NivelDeReorden < 0 THROW 50002, N'NivelDeReorden no puede ser negativo.', 1;
    IF @Descontinuado IS NULL THROW 50001, N'Descontinuado es obligatorio.', 1;
    IF @ProveedorID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Proveedores WHERE ProveedorID = @ProveedorID AND Activo = 1)
        THROW 50003, N'El proveedor debe existir y estar activo.', 1;
    IF @CategoriaID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE CategoriaID = @CategoriaID AND Activo = 1)
        THROW 50003, N'El categoria debe existir y estar activo.', 1;
    INSERT INTO dbo.Productos (NombreProducto, ProveedorID, CategoriaID, CantidadPorUnidad, PrecioUnidad, UnidadesEnExistencia, UnidadesEnPedido, NivelDeReorden, Descontinuado)
    VALUES (@NombreProducto, @ProveedorID, @CategoriaID, @CantidadPorUnidad, @PrecioUnidad, @UnidadesEnExistencia, @UnidadesEnPedido, @NivelDeReorden, @Descontinuado);
    SET @FilasAfectadas = @@ROWCOUNT;
    SET @NuevoID = CONVERT(int, SCOPE_IDENTITY());
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Productos_Actualizar
    @ProductoID int,
    @NombreProducto nvarchar(60),
    @ProveedorID int,
    @CategoriaID int,
    @CantidadPorUnidad nvarchar(30),
    @PrecioUnidad decimal(10,2),
    @UnidadesEnExistencia smallint,
    @UnidadesEnPedido smallint,
    @NivelDeReorden smallint,
    @Descontinuado bit,
    @FilasAfectadas int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @FilasAfectadas = 0;
    IF @NombreProducto IS NULL OR LEN(LTRIM(RTRIM(@NombreProducto))) = 0 THROW 50001, N'NombreProducto es obligatorio.', 1;
    IF @PrecioUnidad IS NULL THROW 50001, N'PrecioUnidad es obligatorio.', 1;
    IF @PrecioUnidad < 0 THROW 50002, N'PrecioUnidad no puede ser negativo.', 1;
    IF @UnidadesEnExistencia IS NULL THROW 50001, N'UnidadesEnExistencia es obligatorio.', 1;
    IF @UnidadesEnExistencia < 0 THROW 50002, N'UnidadesEnExistencia no puede ser negativo.', 1;
    IF @UnidadesEnPedido IS NULL THROW 50001, N'UnidadesEnPedido es obligatorio.', 1;
    IF @UnidadesEnPedido < 0 THROW 50002, N'UnidadesEnPedido no puede ser negativo.', 1;
    IF @NivelDeReorden IS NULL THROW 50001, N'NivelDeReorden es obligatorio.', 1;
    IF @NivelDeReorden < 0 THROW 50002, N'NivelDeReorden no puede ser negativo.', 1;
    IF @Descontinuado IS NULL THROW 50001, N'Descontinuado es obligatorio.', 1;
    IF @ProveedorID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Proveedores WHERE ProveedorID = @ProveedorID AND Activo = 1)
        THROW 50003, N'El proveedor debe existir y estar activo.', 1;
    IF @CategoriaID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE CategoriaID = @CategoriaID AND Activo = 1)
        THROW 50003, N'El categoria debe existir y estar activo.', 1;
    UPDATE dbo.Productos SET
        NombreProducto = @NombreProducto,
        ProveedorID = @ProveedorID,
        CategoriaID = @CategoriaID,
        CantidadPorUnidad = @CantidadPorUnidad,
        PrecioUnidad = @PrecioUnidad,
        UnidadesEnExistencia = @UnidadesEnExistencia,
        UnidadesEnPedido = @UnidadesEnPedido,
        NivelDeReorden = @NivelDeReorden,
        Descontinuado = @Descontinuado
    WHERE ProductoID = @ProductoID AND Activo = 1;
    SET @FilasAfectadas = @@ROWCOUNT;
    IF @FilasAfectadas = 0 THROW 50005, N'El registro no existe o ya está inactivo.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Productos_Eliminar
    @ProductoID int,
    @FilasAfectadas int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @FilasAfectadas = 0;
    UPDATE dbo.Productos SET Activo = 0 WHERE ProductoID = @ProductoID AND Activo = 1;
    SET @FilasAfectadas = @@ROWCOUNT;
    IF @FilasAfectadas = 0 THROW 50005, N'El registro no existe o ya está inactivo.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Pedidos_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PedidoID, ClienteID, EmpleadoID, FechaPedido, FechaRequerida, FechaEnvio, TransportistaID, Destinatario, CiudadDestino, PaisDestino, Activo FROM dbo.Pedidos WHERE Activo = 1 ORDER BY PedidoID;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Pedidos_Insertar
    @ClienteID int,
    @EmpleadoID int,
    @FechaPedido date,
    @FechaRequerida date,
    @FechaEnvio date,
    @TransportistaID int,
    @Destinatario nvarchar(60),
    @CiudadDestino nvarchar(30),
    @PaisDestino nvarchar(30),
    @FilasAfectadas int OUTPUT,
    @NuevoID int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @FilasAfectadas = 0;
    IF @FechaPedido IS NULL THROW 50001, N'FechaPedido es obligatorio.', 1;
    IF @FechaRequerida < @FechaPedido THROW 50004, N'FechaRequerida no puede preceder a FechaPedido.', 1;
    IF @FechaEnvio < @FechaPedido THROW 50004, N'FechaEnvio no puede preceder a FechaPedido.', 1;
    INSERT INTO dbo.Pedidos (ClienteID, EmpleadoID, FechaPedido, FechaRequerida, FechaEnvio, TransportistaID, Destinatario, CiudadDestino, PaisDestino)
    VALUES (@ClienteID, @EmpleadoID, @FechaPedido, @FechaRequerida, @FechaEnvio, @TransportistaID, @Destinatario, @CiudadDestino, @PaisDestino);
    SET @FilasAfectadas = @@ROWCOUNT;
    SET @NuevoID = CONVERT(int, SCOPE_IDENTITY());
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Pedidos_Actualizar
    @PedidoID int,
    @ClienteID int,
    @EmpleadoID int,
    @FechaPedido date,
    @FechaRequerida date,
    @FechaEnvio date,
    @TransportistaID int,
    @Destinatario nvarchar(60),
    @CiudadDestino nvarchar(30),
    @PaisDestino nvarchar(30),
    @FilasAfectadas int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @FilasAfectadas = 0;
    IF @FechaPedido IS NULL THROW 50001, N'FechaPedido es obligatorio.', 1;
    IF @FechaRequerida < @FechaPedido THROW 50004, N'FechaRequerida no puede preceder a FechaPedido.', 1;
    IF @FechaEnvio < @FechaPedido THROW 50004, N'FechaEnvio no puede preceder a FechaPedido.', 1;
    UPDATE dbo.Pedidos SET
        ClienteID = @ClienteID,
        EmpleadoID = @EmpleadoID,
        FechaPedido = @FechaPedido,
        FechaRequerida = @FechaRequerida,
        FechaEnvio = @FechaEnvio,
        TransportistaID = @TransportistaID,
        Destinatario = @Destinatario,
        CiudadDestino = @CiudadDestino,
        PaisDestino = @PaisDestino
    WHERE PedidoID = @PedidoID AND Activo = 1;
    SET @FilasAfectadas = @@ROWCOUNT;
    IF @FilasAfectadas = 0 THROW 50005, N'El registro no existe o ya está inactivo.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Pedidos_Eliminar
    @PedidoID int,
    @FilasAfectadas int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @FilasAfectadas = 0;
    UPDATE dbo.Pedidos SET Activo = 0 WHERE PedidoID = @PedidoID AND Activo = 1;
    SET @FilasAfectadas = @@ROWCOUNT;
    IF @FilasAfectadas = 0 THROW 50005, N'El registro no existe o ya está inactivo.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Proveedores_Buscar
    @NombreContacto nvarchar(40) = NULL,
    @Ciudad nvarchar(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @NombreContacto = NULLIF(LTRIM(RTRIM(@NombreContacto)), N'');
    SET @Ciudad = NULLIF(LTRIM(RTRIM(@Ciudad)), N'');
    SELECT ProveedorID, CompaniaNombre, NombreContacto, CargoContacto,
           Direccion, Ciudad, CodigoPostal, Pais, Telefono, Fax, Activo
    FROM dbo.Proveedores
    WHERE Activo = 1
      AND (@NombreContacto IS NULL OR CHARINDEX(@NombreContacto, NombreContacto) > 0)
      AND (@Ciudad IS NULL OR CHARINDEX(@Ciudad, Ciudad) > 0)
    ORDER BY CompaniaNombre;
END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_DetallePedidos_PorFechas
    @Desde date,
    @Hasta date
AS
BEGIN
    SET NOCOUNT ON;
    IF @Desde IS NULL OR @Hasta IS NULL OR @Desde > @Hasta
        THROW 50007, N'Indique un intervalo de fechas válido.', 1;
    SELECT p.PedidoID, p.FechaPedido, p.Destinatario,
           d.ProductoID, pr.NombreProducto, d.PrecioUnidad,
           d.Cantidad, d.Descuento,
           CAST(d.PrecioUnidad * d.Cantidad * (1 - d.Descuento)
                AS decimal(18,2)) AS Importe
    FROM dbo.DetallePedidos AS d
    INNER JOIN dbo.Pedidos AS p ON p.PedidoID = d.PedidoID
    INNER JOIN dbo.Productos AS pr ON pr.ProductoID = d.ProductoID
    WHERE p.Activo = 1 AND p.FechaPedido >= @Desde AND p.FechaPedido <= @Hasta
    ORDER BY p.FechaPedido, p.PedidoID, d.ProductoID;
    -- Se conserva el historial de productos dados de baja en pedidos activos.
END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_Catalogos_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CategoriaID AS ID, NombreCategoria AS Nombre FROM dbo.Categorias WHERE Activo=1 ORDER BY NombreCategoria;
    SELECT ProveedorID AS ID, CompaniaNombre AS Nombre FROM dbo.Proveedores WHERE Activo=1 ORDER BY CompaniaNombre;
    SELECT ClienteID AS ID, Empresa AS Nombre FROM dbo.Clientes ORDER BY Empresa;
    SELECT EmpleadoID AS ID, Nombre + N' ' + Apellidos AS Nombre FROM dbo.Empleados ORDER BY Nombre;
    SELECT TransportistaID AS ID, CompaniaNombre AS Nombre FROM dbo.Transportistas ORDER BY CompaniaNombre;
END;
GO
