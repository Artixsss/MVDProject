using Microsoft.AspNetCore.Mvc;
using MvdBackend.Models;
using MvdBackend.Repositories;

namespace MvdBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RequestStatusesController : ControllerBase
    {
        private readonly IRequestStatusRepository _requestStatusRepository;

        public RequestStatusesController(IRequestStatusRepository requestStatusRepository)
        {
            _requestStatusRepository = requestStatusRepository;
        }

        // GET: api/RequestStatuses
        [HttpGet]
        public async Task<ActionResult<IEnumerable<RequestStatus>>> GetRequestStatuses()
        {
            var requestStatuses = await _requestStatusRepository.GetAllAsync();
            return Ok(requestStatuses);
        }

        // GET: api/RequestStatuses/5
        [HttpGet("{id}")]
        public async Task<ActionResult<RequestStatus>> GetRequestStatus(int id)
        {
            var requestStatus = await _requestStatusRepository.GetByIdAsync(id);

            if (requestStatus == null)
            {
                return NotFound();
            }

            return requestStatus;
        }

        // GET: api/RequestStatuses/with-requests/5
        [HttpGet("with-requests/{id}")]
        public async Task<ActionResult<RequestStatus>> GetRequestStatusWithRequests(int id)
        {
            var requestStatus = await _requestStatusRepository.GetWithRequestsAsync(id);

            if (requestStatus == null)
            {
                return NotFound();
            }

            return requestStatus;
        }

        // POST: api/RequestStatuses
        [HttpPost]
        public async Task<ActionResult<RequestStatus>> PostRequestStatus(RequestStatus requestStatus)
        {
            await _requestStatusRepository.AddAsync(requestStatus);
            await _requestStatusRepository.SaveAsync();

            return CreatedAtAction("GetRequestStatus", new { id = requestStatus.Id }, requestStatus);
        }

        // PUT: api/RequestStatuses/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutRequestStatus(int id, RequestStatus requestStatus)
        {
            if (id != requestStatus.Id)
            {
                return BadRequest();
            }

            _requestStatusRepository.Update(requestStatus);
            await _requestStatusRepository.SaveAsync();

            return NoContent();
        }

        // DELETE: api/RequestStatuses/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteRequestStatus(int id)
        {
            var requestStatus = await _requestStatusRepository.GetByIdAsync(id);
            if (requestStatus == null)
            {
                return NotFound();
            }

            _requestStatusRepository.Remove(requestStatus);
            await _requestStatusRepository.SaveAsync();

            return NoContent();
        }
    }
}
