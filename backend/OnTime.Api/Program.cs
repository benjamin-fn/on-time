using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using OnTime.Api.Data;
using OnTime.Api.Models;

var builder = WebApplication.CreateBuilder(args);

// =========================
// DATABASE
// =========================

var connectionString =
    builder.Configuration.GetConnectionString(
        "DefaultConnection"
    );

builder.Services.AddDbContext<AppDbContext>(
    options =>
        options.UseNpgsql(connectionString)
);

builder.Services.AddScoped<
    IPasswordHasher<User>,
    PasswordHasher<User>
>();

// =========================
// JWT
// =========================

var jwtKey =
    builder.Configuration["Jwt:Key"];

if (string.IsNullOrWhiteSpace(jwtKey))
{
    throw new InvalidOperationException(
        "JWT-nyckel saknas. Lägg till Jwt:Key i User Secrets."
    );
}

var jwtIssuer =
    builder.Configuration["Jwt:Issuer"]
    ?? "OnTime.Api";

var jwtAudience =
    builder.Configuration["Jwt:Audience"]
    ?? "OnTime.App";

builder.Services
    .AddAuthentication(
        JwtBearerDefaults.AuthenticationScheme
    )
    .AddJwtBearer(
        options =>
        {
            options.TokenValidationParameters =
                new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidateLifetime = true,
                    ValidateIssuerSigningKey = true,

                    ValidIssuer = jwtIssuer,
                    ValidAudience = jwtAudience,

                    IssuerSigningKey =
                        new SymmetricSecurityKey(
                            Encoding.UTF8.GetBytes(
                                jwtKey
                            )
                        ),

                    ClockSkew = TimeSpan.Zero
                };
        }
    );

builder.Services.AddAuthorization();

// =========================
// FIREBASE
// =========================

var firebaseServiceAccountPath =
    builder.Configuration[
        "Firebase:ServiceAccountPath"
    ];

if (string.IsNullOrWhiteSpace(
    firebaseServiceAccountPath
))
{
    throw new InvalidOperationException(
        "Firebase Service Account-sökväg saknas."
    );
}

FirebaseApp.Create(
    new AppOptions
    {
        Credential =
            GoogleCredential.FromFile(
                firebaseServiceAccountPath
            )
    }
);

// =========================
// APP
// =========================

var app = builder.Build();

app.UseAuthentication();
app.UseAuthorization();

app.MapGet(
    "/",
    () => "On Time API is running!"
);

// =========================
// AUTH
// =========================

app.MapPost(
    "/api/auth/register",
    async (
        RegisterRequest request,
        AppDbContext db,
        IPasswordHasher<User> passwordHasher) =>
    {
        var name =
            request.Name.Trim();

        var email =
            request.Email
                .Trim()
                .ToLowerInvariant();

        if (string.IsNullOrWhiteSpace(name))
        {
            return Results.BadRequest(
                new
                {
                    message =
                        "Namn måste anges."
                }
            );
        }

        if (string.IsNullOrWhiteSpace(email))
        {
            return Results.BadRequest(
                new
                {
                    message =
                        "E-post måste anges."
                }
            );
        }

        if (
            string.IsNullOrWhiteSpace(
                request.Password
            )
            ||
            request.Password.Length < 6
        )
        {
            return Results.BadRequest(
                new
                {
                    message =
                        "Lösenordet måste vara minst 6 tecken."
                }
            );
        }

        var emailExists =
            await db.Users.AnyAsync(
                user =>
                    user.Email == email
            );

        if (emailExists)
        {
            return Results.Conflict(
                new
                {
                    message =
                        "Det finns redan ett konto med den e-postadressen."
                }
            );
        }

        var user =
            new User
            {
                Id = Guid.NewGuid(),
                Name = name,
                Email = email
            };

        user.PasswordHash =
            passwordHasher.HashPassword(
                user,
                request.Password
            );

        db.Users.Add(user);

        await db.SaveChangesAsync();

        var token =
            CreateJwtToken(
                user,
                jwtKey,
                jwtIssuer,
                jwtAudience
            );

        return Results.Created(
            $"/api/users/{user.Id}",
            new AuthResponse(
                user.Id,
                user.Name,
                user.Email,
                token
            )
        );
    }
);

app.MapPost(
    "/api/auth/login",
    async (
        LoginRequest request,
        AppDbContext db,
        IPasswordHasher<User> passwordHasher) =>
    {
        var email =
            request.Email
                .Trim()
                .ToLowerInvariant();

        var user =
            await db.Users.FirstOrDefaultAsync(
                user =>
                    user.Email == email
            );

        if (user == null)
        {
            return Results.Unauthorized();
        }

        var result =
            passwordHasher
                .VerifyHashedPassword(
                    user,
                    user.PasswordHash,
                    request.Password
                );

        if (
            result ==
            PasswordVerificationResult.Failed
        )
        {
            return Results.Unauthorized();
        }

        var token =
            CreateJwtToken(
                user,
                jwtKey,
                jwtIssuer,
                jwtAudience
            );

        return Results.Ok(
            new AuthResponse(
                user.Id,
                user.Name,
                user.Email,
                token
            )
        );
    }
);

// =========================
// DEVICE TOKEN
// =========================

app.MapPut(
    "/api/users/device-token",
    async (
        DeviceTokenRequest request,
        ClaimsPrincipal principal,
        AppDbContext db) =>
    {
        var userId =
            GetUserId(principal);

        if (userId == null)
        {
            return Results.Unauthorized();
        }

        var fcmToken =
            request.FcmToken.Trim();

        if (string.IsNullOrWhiteSpace(
            fcmToken
        ))
        {
            return Results.BadRequest(
                new
                {
                    message =
                        "FCM-token måste anges."
                }
            );
        }

        var user =
            await db.Users
                .FirstOrDefaultAsync(
                    user =>
                        user.Id ==
                        userId.Value
                );

        if (user == null)
        {
            return Results.NotFound();
        }

        user.FcmToken = fcmToken;

        await db.SaveChangesAsync();

        return Results.Ok(
            new
            {
                message =
                    "Enhet registrerad för pushnotiser."
            }
        );
    }
)
.RequireAuthorization();

// =========================
// MEETINGS
// =========================

// Visar både:
// - träffar användaren själv har skapat
// - träffar användaren har accepterat
//
// IsCreator berättar för Flutter om användaren
// är skaparen av just den träffen.

app.MapGet(
    "/api/meetings",
    async (
        ClaimsPrincipal principal,
        AppDbContext db) =>
    {
        var userId =
            GetUserId(principal);

        if (userId == null)
        {
            return Results.Unauthorized();
        }

        var meetings =
            await db.Meetings
                .Where(
                    meeting =>
                        meeting.CreatedByUserId ==
                            userId
                        ||
                        meeting.Participants.Any(
                            participant =>
                                participant.UserId ==
                                    userId
                                &&
                                participant.Status ==
                                    "Accepted"
                        )
                )
                .OrderBy(
                    meeting =>
                        meeting.Date
                )
                .Select(
                    meeting =>
                        new MeetingResponse(
                            meeting.Id,
                            meeting.Title,
                            meeting.Location,
                            meeting.Date,
                            meeting.Stake,
                            meeting.CreatedByUserId ==
                                userId
                        )
                )
                .ToListAsync();

        return Results.Ok(meetings);
    }
)
.RequireAuthorization();

// Skapa träff

app.MapPost(
    "/api/meetings",
    async (
        CreateMeetingRequest request,
        ClaimsPrincipal principal,
        AppDbContext db) =>
    {
        var userId =
            GetUserId(principal);

        if (userId == null)
        {
            return Results.Unauthorized();
        }

        if (string.IsNullOrWhiteSpace(
            request.Title
        ))
        {
            return Results.BadRequest(
                new
                {
                    message =
                        "Titel måste anges."
                }
            );
        }

        if (string.IsNullOrWhiteSpace(
            request.Location
        ))
        {
            return Results.BadRequest(
                new
                {
                    message =
                        "Plats måste anges."
                }
            );
        }

        if (string.IsNullOrWhiteSpace(
            request.Stake
        ))
        {
            return Results.BadRequest(
                new
                {
                    message =
                        "Insats måste anges."
                }
            );
        }

        var meeting =
            new Meeting
            {
                Id = Guid.NewGuid(),
                Title =
                    request.Title.Trim(),
                Location =
                    request.Location.Trim(),
                Date =
                    request.Date,
                Stake =
                    request.Stake.Trim(),
                CreatedByUserId =
                    userId.Value
            };

        db.Meetings.Add(meeting);

        await db.SaveChangesAsync();

        return Results.Created(
            $"/api/meetings/{meeting.Id}",
            new MeetingResponse(
                meeting.Id,
                meeting.Title,
                meeting.Location,
                meeting.Date,
                meeting.Stake,
                true
            )
        );
    }
)
.RequireAuthorization();

// =========================
// PARTICIPANTS
// =========================

// Skaparen eller en accepterad deltagare
// får se deltagarlistan.

app.MapGet(
    "/api/meetings/{meetingId:guid}/participants",
    async (
        Guid meetingId,
        ClaimsPrincipal principal,
        AppDbContext db) =>
    {
        var userId =
            GetUserId(principal);

        if (userId == null)
        {
            return Results.Unauthorized();
        }

        var canViewMeeting =
            await db.Meetings.AnyAsync(
                meeting =>
                    meeting.Id ==
                        meetingId
                    &&
                    (
                        meeting.CreatedByUserId ==
                            userId
                        ||
                        meeting.Participants.Any(
                            participant =>
                                participant.UserId ==
                                    userId
                                &&
                                participant.Status ==
                                    "Accepted"
                        )
                    )
            );

        if (!canViewMeeting)
        {
            return Results.NotFound();
        }

        var participants =
            await db.Participants
                .Where(
                    participant =>
                        participant.MeetingId ==
                            meetingId
                )
                .OrderBy(
                    participant =>
                        participant.Name
                )
                .Select(
                    participant =>
                        new ParticipantResponse(
                            participant.Id,
                            participant.Name,
                            participant.Status,
                            participant.MeetingId
                        )
                )
                .ToListAsync();

        return Results.Ok(participants);
    }
)
.RequireAuthorization();

// =========================
// SEND INVITATION
// =========================

// Endast skaparen får bjuda in.

app.MapPost(
    "/api/meetings/{meetingId:guid}/participants",
    async (
        Guid meetingId,
        InviteParticipantRequest request,
        ClaimsPrincipal principal,
        AppDbContext db) =>
    {
        var currentUserId =
            GetUserId(principal);

        if (currentUserId == null)
        {
            return Results.Unauthorized();
        }

        var meeting =
            await db.Meetings
                .FirstOrDefaultAsync(
                    meeting =>
                        meeting.Id ==
                            meetingId
                        &&
                        meeting.CreatedByUserId ==
                            currentUserId
                );

        if (meeting == null)
        {
            return Results.NotFound();
        }

        var email =
            request.Email
                .Trim()
                .ToLowerInvariant();

        if (string.IsNullOrWhiteSpace(
            email
        ))
        {
            return Results.BadRequest(
                new
                {
                    message =
                        "E-post måste anges."
                }
            );
        }

        var invitedUser =
            await db.Users
                .FirstOrDefaultAsync(
                    user =>
                        user.Email ==
                            email
                );

        if (invitedUser == null)
        {
            return Results.NotFound(
                new
                {
                    message =
                        "Ingen användare hittades med den e-postadressen."
                }
            );
        }

        if (
            invitedUser.Id ==
            currentUserId.Value
        )
        {
            return Results.BadRequest(
                new
                {
                    message =
                        "Du kan inte bjuda in dig själv."
                }
            );
        }

        var alreadyInvited =
            await db.Participants.AnyAsync(
                participant =>
                    participant.MeetingId ==
                        meetingId
                    &&
                    participant.UserId ==
                        invitedUser.Id
            );

        if (alreadyInvited)
        {
            return Results.Conflict(
                new
                {
                    message =
                        "Användaren är redan inbjuden."
                }
            );
        }

        var participant =
            new Participant
            {
                Id = Guid.NewGuid(),
                Name =
                    invitedUser.Name,
                Status =
                    "Invited",
                MeetingId =
                    meetingId,
                UserId =
                    invitedUser.Id
            };

        db.Participants.Add(
            participant
        );

        await db.SaveChangesAsync();

    // =========================
    // PUSH NOTIFICATION
    // =========================

    Console.WriteLine(
        $"PUSH DEBUG: invitedUser={invitedUser.Email}, " +
        $"harToken={!string.IsNullOrWhiteSpace(invitedUser.FcmToken)}"
    );

    if (!string.IsNullOrWhiteSpace(
        invitedUser.FcmToken
    ))
    {
            var creator =
                await db.Users
                    .FirstOrDefaultAsync(
                        user =>
                            user.Id ==
                            currentUserId.Value
                    );

            var creatorName =
                creator?.Name ??
                "Någon";

            var message =
                new Message
                {
                    Token =
                        invitedUser.FcmToken,

                    Notification =
                        new Notification
                        {
                            Title =
                                "Ny inbjudan 🔔",

                            Body =
                                $"{creatorName} har bjudit in dig till {meeting.Title}"
                        },

                    Android =
                        new AndroidConfig
                        {
                            Notification =
                                new AndroidNotification
                                {
                                    ChannelId =
                                        "on_time_high_importance"
                                }
                        }
                };

            await FirebaseMessaging
                .DefaultInstance
                .SendAsync(message);
        }

        return Results.Created(
            $"/api/meetings/{meetingId}/participants/{participant.Id}",
            new ParticipantResponse(
                participant.Id,
                participant.Name,
                participant.Status,
                participant.MeetingId
            )
        );
    }
)
.RequireAuthorization();

// =========================
// MY INVITATIONS
// =========================

app.MapGet(
    "/api/invitations",
    async (
        ClaimsPrincipal principal,
        AppDbContext db) =>
    {
        var userId =
            GetUserId(principal);

        if (userId == null)
        {
            return Results.Unauthorized();
        }

        var invitations =
            await db.Participants
                .Where(
                    participant =>
                        participant.UserId ==
                            userId
                )
                .OrderBy(
                    participant =>
                        participant.Meeting.Date
                )
                .Select(
                    participant =>
                        new InvitationResponse(
                            participant.Id,
                            participant.Status,
                            participant.Meeting.Id,
                            participant.Meeting.Title,
                            participant.Meeting.Location,
                            participant.Meeting.Date,
                            participant.Meeting.Stake,
                            participant.Meeting
                                    .CreatedByUser !=
                                null
                                ? participant
                                    .Meeting
                                    .CreatedByUser!
                                    .Name
                                : "Okänd"
                        )
                )
                .ToListAsync();

        return Results.Ok(invitations);
    }
)
.RequireAuthorization();

// =========================
// ACCEPT / DECLINE
// =========================

// Bara den inbjudna användaren själv
// får svara på inbjudan.

app.MapPut(
    "/api/participants/{participantId:guid}/status",
    async (
        Guid participantId,
        UpdateParticipantStatusRequest request,
        ClaimsPrincipal principal,
        AppDbContext db) =>
    {
        var userId =
            GetUserId(principal);

        if (userId == null)
        {
            return Results.Unauthorized();
        }

        var participant =
            await db.Participants
                .FirstOrDefaultAsync(
                    participant =>
                        participant.Id ==
                            participantId
                        &&
                        participant.UserId ==
                            userId
                );

        if (participant == null)
        {
            return Results.NotFound();
        }

        var allowedStatuses =
            new[]
            {
                "Accepted",
                "Declined"
            };

        if (!allowedStatuses.Contains(
            request.Status
        ))
        {
            return Results.BadRequest(
                new
                {
                    message =
                        "Status måste vara Accepted eller Declined."
                }
            );
        }

        participant.Status =
            request.Status;

        await db.SaveChangesAsync();

        return Results.Ok(
            new ParticipantResponse(
                participant.Id,
                participant.Name,
                participant.Status,
                participant.MeetingId
            )
        );
    }
)
.RequireAuthorization();

// =========================
// START
// =========================

app.Run();

// =========================
// HELPERS
// =========================

static Guid? GetUserId(
    ClaimsPrincipal principal
)
{
    var userIdValue =
        principal.FindFirstValue(
            JwtRegisteredClaimNames.Sub
        );

    if (string.IsNullOrWhiteSpace(
        userIdValue
    ))
    {
        userIdValue =
            principal.FindFirstValue(
                ClaimTypes.NameIdentifier
            );
    }

    if (!Guid.TryParse(
        userIdValue,
        out var userId
    ))
    {
        return null;
    }

    return userId;
}

static string CreateJwtToken(
    User user,
    string jwtKey,
    string issuer,
    string audience
)
{
    var claims =
        new[]
        {
            new Claim(
                JwtRegisteredClaimNames.Sub,
                user.Id.ToString()
            ),

            new Claim(
                JwtRegisteredClaimNames.Email,
                user.Email
            ),

            new Claim(
                "name",
                user.Name
            )
        };

    var key =
        new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(
                jwtKey
            )
        );

    var credentials =
        new SigningCredentials(
            key,
            SecurityAlgorithms.HmacSha256
        );

    var token =
        new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires:
                DateTime.UtcNow.AddDays(7),
            signingCredentials:
                credentials
        );

    return new JwtSecurityTokenHandler()
        .WriteToken(token);
}

// =========================
// REQUEST / RESPONSE
// =========================

record RegisterRequest(
    string Name,
    string Email,
    string Password
);

record LoginRequest(
    string Email,
    string Password
);

record AuthResponse(
    Guid Id,
    string Name,
    string Email,
    string Token
);

record CreateMeetingRequest(
    string Title,
    string Location,
    DateTime Date,
    string Stake
);

record MeetingResponse(
    Guid Id,
    string Title,
    string Location,
    DateTime Date,
    string Stake,
    bool IsCreator
);

record InviteParticipantRequest(
    string Email
);

record ParticipantResponse(
    Guid Id,
    string Name,
    string Status,
    Guid MeetingId
);

record UpdateParticipantStatusRequest(
    string Status
);

record InvitationResponse(
    Guid ParticipantId,
    string Status,
    Guid MeetingId,
    string Title,
    string Location,
    DateTime Date,
    string Stake,
    string CreatedByName
);

record DeviceTokenRequest(
    string FcmToken
);