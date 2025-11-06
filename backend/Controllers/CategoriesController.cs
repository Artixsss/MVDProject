using Microsoft.AspNetCore.Mvc;
using MvdBackend.Models;
using MvdBackend.Repositories;

namespace MvdBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CategoriesController : ControllerBase
    {
        private readonly ICategoryRepository _categoryRepository;

        public CategoriesController(ICategoryRepository categoryRepository)
        {
            _categoryRepository = categoryRepository;
        }

        // GET: api/Categories
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Category>>> GetCategories()
        {
            var categories = await _categoryRepository.GetAllAsync();
            return Ok(categories);
        }

        // GET: api/Categories/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Category>> GetCategory(int id)
        {
            var category = await _categoryRepository.GetByIdAsync(id);

            if (category == null)
            {
                return NotFound();
            }

            return category;
        }

        // GET: api/Categories/with-requests/5
        [HttpGet("with-requests/{id}")]
        public async Task<ActionResult<Category>> GetCategoryWithRequests(int id)
        {
            var category = await _categoryRepository.GetWithRequestsAsync(id);

            if (category == null)
            {
                return NotFound();
            }

            return category;
        }

        // POST: api/Categories
        [HttpPost]
        public async Task<ActionResult<Category>> PostCategory(Category category)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            try
            {
                await _categoryRepository.AddAsync(category);
                await _categoryRepository.SaveAsync();

                return CreatedAtAction("GetCategory", new { id = category.Id }, category);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Ошибка создания категории: {ex.Message}");
            }
        }

        // PUT: api/Categories/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutCategory(int id, Category category)
        {
            if (id != category.Id)
            {
                return BadRequest();
            }

            _categoryRepository.Update(category);
            await _categoryRepository.SaveAsync();

            return NoContent();
        }

        // DELETE: api/Categories/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteCategory(int id)
        {
            var category = await _categoryRepository.GetByIdAsync(id);
            if (category == null)
            {
                return NotFound();
            }

            _categoryRepository.Remove(category);
            await _categoryRepository.SaveAsync();

            return NoContent();
        }
    }
}
