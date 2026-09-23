using System;
using System.Data;
using System.Data.SqlClient;
using System.Threading.Tasks;

namespace Neptuno.Data.Repositories
{
    public sealed class NeptunoRepository : INeptunoRepository
    {
        private readonly string connectionString;

        public NeptunoRepository(string connectionString)
        {
            if (string.IsNullOrWhiteSpace(connectionString))
                throw new ArgumentException("La cadena de conexión es obligatoria.", "connectionString");
            this.connectionString = connectionString;
        }

        // Las consultas se materializan en memoria. La conexión se cierra antes
        // de devolver el DataTable, por lo que la interfaz trabaja desconectada.
        public Task<DataTable> ReadAsync(string procedure, params DbParameterValue[] parameters)
        {
            return Task.Run(delegate
            {
                using (var cn = new SqlConnection(connectionString))
                using (var cmd = CreateCommand(procedure, cn, parameters))
                using (var adapter = new SqlDataAdapter(cmd))
                {
                    var table = new DataTable();
                    cn.Open();
                    adapter.Fill(table);
                    return table;
                }
            });
        }

        // Los catálogos también son una instantánea desconectada en memoria.
        public Task<DataSet> CatalogsAsync()
        {
            return Task.Run(delegate
            {
                using (var cn = new SqlConnection(connectionString))
                using (var cmd = new SqlCommand("dbo.usp_Catalogos_Listar", cn))
                using (var adapter = new SqlDataAdapter(cmd))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    var data = new DataSet();
                    cn.Open();
                    adapter.Fill(data);
                    return data;
                }
            });
        }

        // Las escrituras permanecen conectadas solo durante la operación porque
        // deben validar filas afectadas y, en las altas, recuperar el nuevo ID.
        public async Task<int> WriteAsync(string procedure, bool insert, params DbParameterValue[] parameters)
        {
            using (var cn = new SqlConnection(connectionString))
            using (var cmd = CreateCommand(procedure, cn, parameters))
            {
                var affected = cmd.Parameters.Add("@FilasAfectadas", SqlDbType.Int);
                affected.Direction = ParameterDirection.Output;
                SqlParameter newId = null;
                if (insert)
                {
                    newId = cmd.Parameters.Add("@NuevoID", SqlDbType.Int);
                    newId.Direction = ParameterDirection.Output;
                }

                await cn.OpenAsync().ConfigureAwait(false);
                await cmd.ExecuteNonQueryAsync().ConfigureAwait(false);

                if (affected.Value == DBNull.Value || Convert.ToInt32(affected.Value) != 1)
                    throw new InvalidOperationException("La operación no afectó exactamente un registro.");
                return insert ? Convert.ToInt32(newId.Value) : 0;
            }
        }

        private static SqlCommand CreateCommand(string procedure, SqlConnection connection, DbParameterValue[] parameters)
        {
            var cmd = new SqlCommand(procedure, connection);
            cmd.CommandType = CommandType.StoredProcedure;
            if (parameters == null) return cmd;

            foreach (var value in parameters)
            {
                var parameter = cmd.Parameters.Add(value.Name, value.Type);
                parameter.Value = value.Value;
                if (value.Size > 0) parameter.Size = value.Size;
                if (value.Type == SqlDbType.Decimal)
                {
                    parameter.Precision = value.Precision;
                    parameter.Scale = value.Scale;
                }
            }
            return cmd;
        }
    }
}
