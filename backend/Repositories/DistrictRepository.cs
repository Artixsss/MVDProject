using Microsoft.EntityFrameworkCore;
using MvdBackend.Data;
using MvdBackend.Models;

namespace MvdBackend.Repositories
{
    public class DistrictRepository : Repository<District>, IDistrictRepository
    {
        public DistrictRepository(AppDbContext context) : base(context)
        {
        }

        public async Task<District?> GetByNameAsync(string name)
        {
            return await _context.Districts
                .FirstOrDefaultAsync(d => d.Name == name);
        }

        public async Task<IEnumerable<District>> GetDistrictsWithRequestsAsync()
        {
            return await _context.Districts
                .Include(d => d.CitizenRequests)
                .ToListAsync();
        }
    }
}
