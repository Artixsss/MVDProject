using MvdBackend.Models;

namespace MvdBackend.Repositories
{
    public interface IDistrictRepository : IRepository<District>
    {
        Task<District?> GetByNameAsync(string name);
        Task<IEnumerable<District>> GetDistrictsWithRequestsAsync();
    }
}
