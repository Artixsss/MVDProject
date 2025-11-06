using MvdBackend.Models;

namespace MvdBackend.Repositories
{
    public interface IRequestStatusRepository : IRepository<RequestStatus>
    {
        Task<RequestStatus> GetWithRequestsAsync(int id);
    }
}
