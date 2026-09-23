using System;

namespace Neptuno.Data.Models
{
    public sealed class Field
    {
        public string Name, Label, Kind;
        public int Size;
        public bool Required;

        public Field(string name, string label, string kind, int size, bool required)
        {
            Name = name; Label = label; Kind = kind; Size = size; Required = required;
        }
    }

    public sealed class Entity
    {
        public Type ModelType;
        public string Name, Key;
        public Field[] Fields;

        public Entity(Type modelType, string name, string key, params Field[] fields)
        {
            ModelType = modelType; Name = name; Key = key; Fields = fields;
        }
    }

    public sealed class Producto
    {
        public int ProductoID { get; set; }
        public string NombreProducto { get; set; }
        public int? ProveedorID { get; set; }
        public int? CategoriaID { get; set; }
        public string CantidadPorUnidad { get; set; }
        public decimal PrecioUnidad { get; set; }
        public short UnidadesEnExistencia { get; set; }
        public short UnidadesEnPedido { get; set; }
        public short NivelDeReorden { get; set; }
        public bool Descontinuado { get; set; }
        public bool Activo { get; set; }
    }

    public sealed class Categoria
    {
        public int CategoriaID { get; set; }
        public string NombreCategoria { get; set; }
        public string Descripcion { get; set; }
        public bool Activo { get; set; }
    }

    public sealed class Proveedor
    {
        public int ProveedorID { get; set; }
        public string CompaniaNombre { get; set; }
        public string NombreContacto { get; set; }
        public string CargoContacto { get; set; }
        public string Direccion { get; set; }
        public string Ciudad { get; set; }
        public string CodigoPostal { get; set; }
        public string Pais { get; set; }
        public string Telefono { get; set; }
        public string Fax { get; set; }
        public bool Activo { get; set; }
    }

    public sealed class Pedido
    {
        public int PedidoID { get; set; }
        public int? ClienteID { get; set; }
        public int? EmpleadoID { get; set; }
        public DateTime FechaPedido { get; set; }
        public DateTime? FechaRequerida { get; set; }
        public DateTime? FechaEnvio { get; set; }
        public int? TransportistaID { get; set; }
        public string Destinatario { get; set; }
        public string CiudadDestino { get; set; }
        public string PaisDestino { get; set; }
        public bool Activo { get; set; }
    }
}
