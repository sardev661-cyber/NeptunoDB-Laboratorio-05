# NeptunoDB Laboratorio 05

Aplicación de escritorio WPF y ADO.NET para el mantenimiento de productos, categorías, proveedores y pedidos. Las operaciones de baja son lógicas: cada tabla tiene `Activo BIT NOT NULL DEFAULT 1`, y sus procedimientos `Eliminar` actualizan el campo a `0`.

## Requisitos

- Windows con .NET Framework 4.8.
- SQL Server 2016 SP1 o posterior y permisos para crear `NeptunoDB`, tablas y procedimientos.
- Visual Studio con soporte para proyectos .NET Framework, o el compilador de .NET Framework incluido en Windows.

## Instalar la base

Ejecutar una vez, en este orden, desde SQL Server Management Studio:

1. `Database/01_NeptunoDB.sql`: crea la base y los datos de ejemplo. La copia corrige caracteres acentuados dañados en el archivo suministrado.
2. `Database/02_Laboratorio05.sql`: agrega `Activo` y crea los procedimientos. Puede ejecutarse de nuevo para actualizar los procedimientos.
3. `Database/03_Pruebas.sql`: verifica altas, ediciones, bajas lógicas, búsqueda y reporte. Revierta los datos de prueba mediante `ROLLBACK`; los valores de identidad pueden avanzar.

El script `01_NeptunoDB.sql` no es idempotente. Si la base ya existe con sus tablas, no lo ejecutes de nuevo.

## Compilar y ejecutar

Abre `NeptunoLab05.sln` en Visual Studio, o ejecuta `Compilar.ps1` con PowerShell. El script de compilación produce `Aplicacion/Neptuno.Wpf.exe`. Inicia la aplicación y ajusta la cadena de conexión que aparece arriba para usar la misma instancia de SQL Server que configuraste en SSMS. Pulsa **Conectar** antes de trabajar.

Ejemplos de servidor en la cadena de conexión:

```text
Data Source=.;Initial Catalog=NeptunoDB;Integrated Security=True;Encrypt=False;TrustServerCertificate=True
Data Source=.\SQLEXPRESS2017;Initial Catalog=NeptunoDB;Integrated Security=True;Encrypt=False;TrustServerCertificate=True
```

La instancia y el modo de autenticación dependen del equipo. Para autenticación SQL Server, introduce una cadena de conexión apropiada en la aplicación. No almacenes credenciales en el repositorio.

## Funciones

| Vista | Función |
| --- | --- |
| Productos, Categorías, Proveedores, Pedidos | Listar registros activos; insertar, actualizar y dar de baja de forma lógica. |
| Buscar proveedores | Filtrar por nombre del contacto y ciudad; solo registros activos. |
| Reporte por fechas | Listar detalles de pedidos mediante `INNER JOIN`, en un intervalo inclusivo, excluyendo pedidos inactivos. |

Todas las escrituras pasan por `DataAccess.Write`, que usa `SqlCommand` con parámetros tipados, `CommandType.StoredProcedure` y `ExecuteNonQuery`. Los procedimientos devuelven `@FilasAfectadas OUTPUT`; no se usa el retorno de `ExecuteNonQuery` como conteo porque trabajan con `SET NOCOUNT ON`. Las consultas usan `SqlDataAdapter` y `DataTable`.

La baja de categorías y proveedores se impide si todavía tienen productos activos vinculados. Primero reasigna o da de baja esos productos. Los detalles históricos permanecen guardados al dar de baja un pedido o producto.

## Evidencias

Las capturas de la carpeta local `Capturas` se generaron en **vista previa** y no demuestran conexión a SQL Server. Por eso no se incluyen en el repositorio público. Para la entrega académica, toma capturas propias después de pulsar **Conectar** y realizar operaciones reales.

## Estado de validación

- La solución WPF compila sin errores con el compilador de .NET Framework.
- Los tres archivos SQL pasaron la revisión sintáctica con el parser de SQL Server.
- El usuario informó que `03_Pruebas.sql` mostró los mensajes `OK` en su instancia local.
- La interacción de la aplicación WPF con esa instancia y las capturas reales quedan para la comprobación local del usuario.
