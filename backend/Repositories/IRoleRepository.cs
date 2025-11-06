using MvdBackend.Models;

namespace MvdBackend.Repositories
{
    public interface IRoleRepository : IRepository<Role>
    {
        Task<Role?> GetByNameAsync(string name);
    }
}
