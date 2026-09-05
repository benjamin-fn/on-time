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

// Hämta alla träffar
app.MapGet("/api/meetings", async (AppDbContext db) =>
{
    var meetings = await db.Meetings
        .OrderBy(m => m.Date)
        .ToListAsync();

    return Results.Ok(meetings);
});

// Skapa en ny träff
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

// Hämta deltagare för en träff
app.MapGet("/api/meetings/{meetingId:guid}/participants", async (
    Guid meetingId,
    AppDbContext db) =>
{
    var meetingExists = await db.Meetings
        .AnyAsync(m => m.Id == meetingId);

    if (!meetingExists)
    {
        return Results.NotFound();
    }

    var participants = await db.Participants
        .Where(p => p.MeetingId == meetingId)
        .OrderBy(p => p.Name)
        .ToListAsync();

    return Results.Ok(participants);
});

// Lägg till deltagare i en träff
app.MapPost("/api/meetings/{meetingId:guid}/participants", async (
    Guid meetingId,
    CreateParticipantRequest request,
    AppDbContext db) =>
{
    var meetingExists = await db.Meetings
        .AnyAsync(m => m.Id == meetingId);

    if (!meetingExists)
    {
        return Results.NotFound();
    }

    var participant = new Participant
    {
        Id = Guid.NewGuid(),
        Name = request.Name,
        Status = "Invited",
        MeetingId = meetingId
    };

    db.Participants.Add(participant);
    await db.SaveChangesAsync();

    return Results.Created(
        $"/api/meetings/{meetingId}/participants/{participant.Id}",
        participant
    );
});

// Ändra deltagarens status
app.MapPut("/api/participants/{participantId:guid}/status", async (
    Guid participantId,
    UpdateParticipantStatusRequest request,
    AppDbContext db) =>
{
    var participant = await db.Participants
        .FirstOrDefaultAsync(p => p.Id == participantId);

    if (participant == null)
    {
        return Results.NotFound();
    }

    var allowedStatuses = new[]
    {
        "Invited",
        "Accepted",
        "Declined"
    };

    if (!allowedStatuses.Contains(request.Status))
    {
        return Results.BadRequest(
            new
            {
                message = "Ogiltig deltagarstatus."
            }
        );
    }

    participant.Status = request.Status;

    await db.SaveChangesAsync();

    return Results.Ok(participant);
});

app.Run();

record CreateMeetingRequest(
    string Title,
    string Location,
    DateTime Date,
    string Stake
);

record CreateParticipantRequest(
    string Name
);

record UpdateParticipantStatusRequest(
    string Status
);