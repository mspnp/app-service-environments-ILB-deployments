// ------------------------------------------------------------
//  Copyright (c) Microsoft Corporation.  All rights reserved.
//  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
// ------------------------------------------------------------

using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using VotingData.Models;

namespace VotingData.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class VoteDataController : ControllerBase
    {
        private readonly ILogger<VoteDataController> logger;
        private readonly VotingDBContext context;

        public VoteDataController(VotingDBContext context, ILogger<VoteDataController> logger)
        {
            this.logger = logger;
            this.context = context;
        }

        [HttpGet]
        public async Task<ActionResult<IList<Counts>>> Get()
        {
            try
            {
                return await context.Counts.ToListAsync();
            }
            catch (Exception ex) when (ex is SqlException)
            {
                logger.LogError(ex, "Sql Exception");
                return BadRequest("Bad Request");
            }
        }

        [HttpPut("{name}")]
        public async Task<IActionResult> Put(string name)
        {
            try
            {
                var candidate = await context.Counts.FirstOrDefaultAsync(c => c.Candidate == name);
                if (candidate == null)
                {
                    await context.Counts.AddAsync(new Counts
                    {
                        Candidate = name,
                        Count = 1
                    });
                }
                else
                {
                    candidate.Count++;
                    context.Entry(candidate).State = EntityState.Modified;
                }

                await context.SaveChangesAsync();
                return NoContent();
            }
            catch (Exception ex) when (ex is SqlException ||
                                       ex is DbUpdateException ||
                                       ex is DbUpdateConcurrencyException)
            {
                logger.LogError(ex, "Sql Exception Saving to Database");
                return BadRequest("Bad Request");
            }
        }

        [HttpDelete("{name}")]
        public async Task<IActionResult> Delete(string name)
        {
            try
            {
                var candidate = await context.Counts.FirstOrDefaultAsync(c => c.Candidate == name);

                if (candidate != null)
                {
                    context.Counts.Remove(candidate);
                    await context.SaveChangesAsync();
                }

                return Ok();
            }
            catch (Exception ex) when (ex is SqlException ||
                                    ex is DbUpdateException ||
                                    ex is DbUpdateConcurrencyException)
            {
                logger.LogError(ex, "Sql Exception Deleting from Database");
                return BadRequest("Bad Request");
            }
        }
    }
}
