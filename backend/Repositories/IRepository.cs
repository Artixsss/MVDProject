using System.Linq.Expressions;

namespace MvdBackend.Repositories
{
    public interface IRepository<T> where T : class
    {
        Task<T> GetByIdAsync(int id);
        Task<IEnumerable<T>> GetAllAsync();
        Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate);
        Task AddAsync(T entity);
        void Update(T entity);
        Task UpdateAsync(T entity);
        void Remove(T entity);
        Task SaveAsync();
    }
}
