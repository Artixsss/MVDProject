using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MvdBackend.Migrations
{
    /// <inheritdoc />
    public partial class AddAiAnalysisFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "AiAnalyzedAt",
                table: "CitizenRequests",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "AiCategory",
                table: "CitizenRequests",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "AiPriority",
                table: "CitizenRequests",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "AiSentiment",
                table: "CitizenRequests",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "AiSuggestedAction",
                table: "CitizenRequests",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "AiSummary",
                table: "CitizenRequests",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "FinalCategory",
                table: "CitizenRequests",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsAiCorrected",
                table: "CitizenRequests",
                type: "boolean",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AiAnalyzedAt",
                table: "CitizenRequests");

            migrationBuilder.DropColumn(
                name: "AiCategory",
                table: "CitizenRequests");

            migrationBuilder.DropColumn(
                name: "AiPriority",
                table: "CitizenRequests");

            migrationBuilder.DropColumn(
                name: "AiSentiment",
                table: "CitizenRequests");

            migrationBuilder.DropColumn(
                name: "AiSuggestedAction",
                table: "CitizenRequests");

            migrationBuilder.DropColumn(
                name: "AiSummary",
                table: "CitizenRequests");

            migrationBuilder.DropColumn(
                name: "FinalCategory",
                table: "CitizenRequests");

            migrationBuilder.DropColumn(
                name: "IsAiCorrected",
                table: "CitizenRequests");
        }
    }
}
