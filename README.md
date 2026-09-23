# Neptuno Laboratorio 05 y Semana 06

Aplicación WPF sobre .NET Framework 4.8 para administrar productos, categorías, proveedores y pedidos de NeptunoDB. Las eliminaciones son bajas lógicas mediante el campo `Activo`.

## Arquitectura

La solución contiene dos proyectos:

- `Neptuno.Wpf`: interfaz, validaciones visuales y configuración de inicio.
- `Neptuno.Data`: modelos de dominio, parámetros de repositorio y acceso a SQL Server.

La dependencia tiene una sola dirección:

```text
Neptuno.Wpf -> Neptuno.Data -> SQL Server
```

La biblioteca de datos no referencia WPF ni contiene un `App.config`. El proyecto de inicio lee la cadena `Neptuno` desde `Neptuno.Wpf/App.config` y la entrega al constructor de `NeptunoRepository`.

## Criterio del modo desconectado

Se usa el modo desconectado para listados, catálogos, búsqueda de proveedores y reporte por fechas. El Repository abre una conexión, ejecuta el procedimiento, llena un `DataTable` o `DataSet` en memoria y cierra la conexión antes de devolver el resultado. Los controles WPF trabajan después con esa instantánea sin mantener una conexión abierta.

Las inserciones, actualizaciones y bajas lógicas se mantienen como operaciones conectadas de corta duración mediante `ExecuteNonQueryAsync`. Este criterio permite validar inmediatamente `@FilasAfectadas` y recuperar `@NuevoID`, además de respetar el requisito de usar `ExecuteNonQuery` para las escrituras.

Las cargas se exponen como tareas y se esperan con `async/await` desde los eventos de WPF hasta el Repository. No se utilizan `.Result` ni `.Wait()`, por lo que la ventana permanece disponible mientras SQL Server responde.

## Base de datos

Ejecutar los scripts en este orden:

1. `Database/01_NeptunoDB.sql`
2. `Database/02_Laboratorio05.sql`
3. `Database/03_Pruebas.sql`

El tercer script prueba altas, modificaciones, bajas lógicas, búsqueda, reporte por fechas e historial. Sus cambios de prueba se revierten mediante `ROLLBACK`.

## Compilación

Ejecutar desde PowerShell:

```powershell
./Compilar.ps1
```

El script compila primero `Aplicacion/Neptuno.Data.dll` y después `Aplicacion/Neptuno.Wpf.exe` con la referencia correspondiente.

## Vista previa y capturas

La interfaz puede revisarse sin ejecutar SQL Server:

```powershell
./Aplicacion/Neptuno.Wpf.exe --vista-previa
```

Para generar una captura de cada módulo:

```powershell
./Aplicacion/Neptuno.Wpf.exe --capturas ./Capturas
```

La vista previa utiliza datos locales y no demuestra una conexión real con SQL Server.

## Observaciones y conclusiones

La separación evita que la interfaz conozca detalles de `SqlConnection`, `SqlCommand` o `SqlDataAdapter`. Cada operación crea y libera su propia conexión, lo que evita conexiones compartidas entre tareas. Las lecturas quedan disponibles en memoria después de cerrar SQL Server y las escrituras conservan la validación inmediata requerida por los procedimientos almacenados.

La cadena de conexión permanece en el ejecutable WPF porque .NET Framework carga en tiempo de ejecución el archivo de configuración del proyecto de inicio. Colocarla únicamente en la biblioteca impediría que `ConfigurationManager` la encuentre mediante el nombre esperado.
