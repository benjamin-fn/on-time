namespace OnTime.Api.Models;

public class Participant
{
    public Guid Id { get; set; }

    public string Name { get; set; } = string.Empty;

    public string Status { get; set; } = "Invited";

    public Guid MeetingId { get; set; }

    public Meeting Meeting { get; set; } = null!;
}