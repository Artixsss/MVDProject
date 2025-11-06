using MvdBackend.Models;

namespace MvdBackend.Repositories
{
    public interface ICategoryRepository : IRepository<Category>
    {
        Task<Category> GetWithRequestsAsync(int id);
    }
}
