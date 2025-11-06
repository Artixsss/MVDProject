using MvdBackend.Models;

namespace MvdBackend.Repositories
{
    public interface IUserRepository : IRepository<User>
    {
        Task<User?> GetByUsernameAsync(string username);
        Task<User?> GetWithDetailsAsync(int id);
        Task<bool> UsernameExistsAsync(string username);
    }
}
