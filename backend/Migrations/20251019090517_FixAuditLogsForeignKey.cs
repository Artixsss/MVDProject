using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MvdBackend.Migrations
{
    /// <inheritdoc />
    public partial class FixAuditLogsForeignKey : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AuditLogs_CitizenRequests_CitizenRequestId",
                table: "AuditLogs");

            migrationBuilder.AddForeignKey(
                name: "FK_AuditLogs_CitizenRequests_CitizenRequestId",
                table: "AuditLogs",
                column: "CitizenRequestId",
                principalTable: "CitizenRequests",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AuditLogs_CitizenRequests_CitizenRequestId",
                table: "AuditLogs");

            migrationBuilder.AddForeignKey(
                name: "FK_AuditLogs_CitizenRequests_CitizenRequestId",
                table: "AuditLogs",
                column: "CitizenRequestId",
                principalTable: "CitizenRequests",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }
    }
}
