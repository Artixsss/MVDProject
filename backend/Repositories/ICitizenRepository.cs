using MvdBackend.Models;

namespace MvdBackend.Repositories
{
    public interface ICitizenRepository : IRepository<Citizen>
    {
        Task<Citizen> GetWithRequestsAsync(int id);
        Task<IEnumerable<Citizen>> GetCitizensByLastNameAsync(string lastName);
    }
}
