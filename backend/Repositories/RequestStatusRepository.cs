using Microsoft.EntityFrameworkCore;
using MvdBackend.Data;
using MvdBackend.Models;

namespace MvdBackend.Repositories
{
    public class RequestStatusRepository : Repository<RequestStatus>, IRequestStatusRepository
    {
        public RequestStatusRepository(AppDbContext context) : base(context)
        {
        }

        public async Task<RequestStatus> GetWithRequestsAsync(int id)
        {
            return await _context.RequestStatuses
                .Include(rs => rs.Requests)
                .FirstOrDefaultAsync(rs => rs.Id == id);
        }
    }
}
