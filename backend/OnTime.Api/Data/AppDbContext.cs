using Microsoft.EntityFrameworkCore;
using OnTime.Api.Models;

namespace OnTime.Api.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    public DbSet<Meeting> Meetings => Set<Meeting>();

    public DbSet<Participant> Participants => Set<Participant>();
}