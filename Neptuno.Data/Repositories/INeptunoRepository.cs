using System.Data;
using System.Threading.Tasks;

namespace Neptuno.Data.Repositories
{
    public interface INeptunoRepository
    {
        Task<DataTable> ReadAsync(string procedure, params DbParameterValue[] parameters);
        Task<DataSet> CatalogsAsync();
        Task<int> WriteAsync(string procedure, bool insert, params DbParameterValue[] parameters);
    }
}
