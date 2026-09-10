using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace OnTime.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddMeetingCreator : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "CreatedByUserId",
                table: "Meetings",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Meetings_CreatedByUserId",
                table: "Meetings",
                column: "CreatedByUserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Meetings_Users_CreatedByUserId",
                table: "Meetings",
                column: "CreatedByUserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Meetings_Users_CreatedByUserId",
                table: "Meetings");

            migrationBuilder.DropIndex(
                name: "IX_Meetings_CreatedByUserId",
                table: "Meetings");

            migrationBuilder.DropColumn(
                name: "CreatedByUserId",
                table: "Meetings");
        }
    }
}
