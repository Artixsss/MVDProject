using Microsoft.EntityFrameworkCore;
using MvdBackend.Data;
using MvdBackend.Models;

namespace MvdBackend.Repositories
{
    public class CitizenRepository : Repository<Citizen>, ICitizenRepository
    {
        public CitizenRepository(AppDbContext context) : base(context)
        {
        }

        public async Task<Citizen> GetWithRequestsAsync(int id)
        {
            return await _context.Citizens
                .Include(c => c.Requests)
                .FirstOrDefaultAsync(c => c.Id == id);
        }

        public async Task<IEnumerable<Citizen>> GetCitizensByLastNameAsync(string lastName)
        {
            return await _context.Citizens
                .Where(c => c.LastName.Contains(lastName))
                .ToListAsync();
        }
    }
}
