using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace MvdBackend.Migrations
{
    /// <inheritdoc />
    public partial class AddDistricts : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "DistrictId",
                table: "CitizenRequests",
                type: "integer",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "Districts",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Districts", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_CitizenRequests_DistrictId",
                table: "CitizenRequests",
                column: "DistrictId");

            migrationBuilder.AddForeignKey(
                name: "FK_CitizenRequests_Districts_DistrictId",
                table: "CitizenRequests",
                column: "DistrictId",
                principalTable: "Districts",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_CitizenRequests_Districts_DistrictId",
                table: "CitizenRequests");

            migrationBuilder.DropTable(
                name: "Districts");

            migrationBuilder.DropIndex(
                name: "IX_CitizenRequests_DistrictId",
                table: "CitizenRequests");

            migrationBuilder.DropColumn(
                name: "DistrictId",
                table: "CitizenRequests");
        }
    }
}
