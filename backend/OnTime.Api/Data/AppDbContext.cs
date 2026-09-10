using Microsoft.EntityFrameworkCore;
using OnTime.Api.Models;

namespace OnTime.Api.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(
        DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    public DbSet<Meeting> Meetings => Set<Meeting>();

    public DbSet<Participant> Participants =>
        Set<Participant>();

    public DbSet<User> Users => Set<User>();

    protected override void OnModelCreating(
        ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>()
            .HasIndex(user => user.Email)
            .IsUnique();

        modelBuilder.Entity<Meeting>()
            .HasOne(meeting => meeting.CreatedByUser)
            .WithMany()
            .HasForeignKey(
                meeting => meeting.CreatedByUserId
            )
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Participant>()
            .HasOne(participant => participant.User)
            .WithMany()
            .HasForeignKey(
                participant => participant.UserId
            )
            .OnDelete(DeleteBehavior.Restrict);
    }
}