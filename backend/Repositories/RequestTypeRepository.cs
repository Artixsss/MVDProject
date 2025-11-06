using Microsoft.EntityFrameworkCore;
using MvdBackend.Data;
using MvdBackend.Models;

namespace MvdBackend.Repositories
{
    public class RequestTypeRepository : Repository<RequestType>, IRequestTypeRepository
    {
        public RequestTypeRepository(AppDbContext context) : base(context)
        {
        }

        public async Task<RequestType> GetWithRequestsAsync(int id)
        {
            return await _context.RequestTypes
                .Include(rt => rt.Requests)
                .FirstOrDefaultAsync(rt => rt.Id == id);
        }
    }
}
