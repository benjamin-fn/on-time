using Microsoft.EntityFrameworkCore;
using OnTime.Api.Data;
using OnTime.Api.Models;

var builder = WebApplication.CreateBuilder(args);

var connectionString =
    builder.Configuration.GetConnectionString("DefaultConnection");

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(connectionString));

var app = builder.Build();

app.MapGet("/", () => "On Time API is running!");

app.MapGet("/api/meetings", async (AppDbContext db) =>
{
    var meetings = await db.Meetings
        .OrderBy(m => m.Date)
        .ToListAsync();

    return Results.Ok(meetings);
});

app.MapPost("/api/meetings", async (
    CreateMeetingRequest request,
    AppDbContext db) =>
{
    var meeting = new Meeting
    {
        Id = Guid.NewGuid(),
        Title = request.Title,
        Location = request.Location,
        Date = request.Date,
        Stake = request.Stake
    };

    db.Meetings.Add(meeting);
    await db.SaveChangesAsync();

    return Results.Created(
        $"/api/meetings/{meeting.Id}",
        meeting
    );
});

app.Run();

record CreateMeetingRequest(
    string Title,
    string Location,
    DateTime Date,
    string Stake
);