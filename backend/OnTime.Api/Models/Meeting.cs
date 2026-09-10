namespace OnTime.Api.Models;

public class Meeting
{
    public Guid Id { get; set; }

    public string Title { get; set; } = string.Empty;

    public string Location { get; set; } = string.Empty;

    public DateTime Date { get; set; }

    public string Stake { get; set; } = string.Empty;

    public Guid? CreatedByUserId { get; set; }

    public User? CreatedByUser { get; set; }

    public List<Participant> Participants { get; set; } = [];
}