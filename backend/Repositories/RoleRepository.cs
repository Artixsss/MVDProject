using MvdBackend.Data;
using MvdBackend.Models;
using Microsoft.EntityFrameworkCore;

namespace MvdBackend.Repositories
{
    public class RoleRepository : Repository<Role>, IRoleRepository
    {
        public RoleRepository(AppDbContext context) : base(context) { }

        public async Task<Role?> GetByNameAsync(string name)
        {
            return await _context.Roles
                .FirstOrDefaultAsync(r => r.Name == name);
        }
    }
}
