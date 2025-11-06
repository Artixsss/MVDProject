using MvdBackend.Models;

namespace MvdBackend.Repositories
{
    public interface IRequestTypeRepository : IRepository<RequestType>
    {
        Task<RequestType> GetWithRequestsAsync(int id);
    }
}
