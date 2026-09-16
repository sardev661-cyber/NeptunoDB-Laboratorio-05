using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;

namespace NeptunoLab05
{
    public sealed class DataAccess
    {
        private readonly string connectionString;
        public DataAccess(string connectionString) { this.connectionString = connectionString; }
        public DataTable Read(string procedure, params SqlParameter[] parameters)
        {
            using (var cn = new SqlConnection(connectionString))
            using (var cmd = new SqlCommand(procedure, cn))
            using (var adapter = new SqlDataAdapter(cmd))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddRange(parameters);
                var table = new DataTable();
                cn.Open(); adapter.Fill(table); return table;
            }
        }
        public DataSet Catalogs()
        {
            using (var cn = new SqlConnection(connectionString))
            using (var cmd = new SqlCommand("dbo.usp_Catalogos_Listar", cn))
            using (var adapter = new SqlDataAdapter(cmd))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                var ds = new DataSet(); cn.Open(); adapter.Fill(ds); return ds;
            }
        }
        // TODAS las altas, ediciones y bajas de los cuatro módulos llegan aquí.
        public int Write(string procedure, bool insert, params SqlParameter[] parameters)
        {
            using (var cn = new SqlConnection(connectionString))
            using (var cmd = new SqlCommand(procedure, cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddRange(parameters);
                var affected = cmd.Parameters.Add("@FilasAfectadas", SqlDbType.Int);
                affected.Direction = ParameterDirection.Output;
                SqlParameter newId = null;
                if (insert)
                {
                    newId = cmd.Parameters.Add("@NuevoID", SqlDbType.Int);
                    newId.Direction = ParameterDirection.Output;
                }
                cn.Open();
                cmd.ExecuteNonQuery();
                // Con SET NOCOUNT ON no se interpreta el retorno (-1) como un error.
                if (Convert.ToInt32(affected.Value) != 1)
                    throw new InvalidOperationException("La operación no afectó exactamente un registro.");
                return insert ? Convert.ToInt32(newId.Value) : 0;
            }
        }
        public static SqlParameter Text(string name, int size, string value)
        { return new SqlParameter(name, SqlDbType.NVarChar, size) { Value = string.IsNullOrWhiteSpace(value) ? (object)DBNull.Value : value.Trim() }; }
        public static SqlParameter Date(string name, DateTime value)
        { return new SqlParameter(name, SqlDbType.Date) { Value = value.Date }; }
    }
}
