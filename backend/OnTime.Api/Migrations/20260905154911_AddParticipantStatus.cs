using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace OnTime.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddParticipantStatus : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Status",
                table: "Participants",
                type: "text",
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Status",
                table: "Participants");
        }
    }
}
