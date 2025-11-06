using Microsoft.EntityFrameworkCore;
using MvdBackend.Data;
using MvdBackend.Models;

namespace MvdBackend.Repositories
{
    public class CategoryRepository : Repository<Category>, ICategoryRepository
    {
        public CategoryRepository(AppDbContext context) : base(context)
        {
        }

        public async Task<Category> GetWithRequestsAsync(int id)
        {
            return await _context.Categories
                .Include(c => c.CitizenRequests)
                .FirstOrDefaultAsync(c => c.Id == id);
        }
    }
}
