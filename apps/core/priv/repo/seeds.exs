# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Core.Repo.insert!(%Core.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias AdminApiWeb.AdminContext

# Create admin if it doesn't exist
# case AdminContext.ensure_admin_exists(%{
#   email: "admin@example.com",
#   username: "admin",
#   password: "admin123",
#   password_confirmation: "admin123"
# }) do
#   {:ok, admin} ->
#     IO.puts("Admin created: #{admin.email}")
#   {:error, :admin_already_exists} ->
#     IO.puts("Admin already exists")
#   {:error, changeset} ->
#     IO.puts("Failed to create admin: #{inspect(changeset.errors)}")
# end

# Seed Tariffs
alias Core.Context
alias Core.Repo
alias Core.Schemas.Tariff

tariffs = [
  %{
    name: "3 месяца",
    description: "Доступ на 3 месяца",
    price: 600,
    currency: "RUB",
    duration_days: 90
  },
  %{
    name: "6 месяцев",
    description: "Доступ на 6 месяцев",
    price: 1500,
    currency: "RUB",
    duration_days: 180
  },
  %{
    name: "1 год",
    description: "Доступ на 1 год",
    price: 2000,
    currency: "RUB",
    duration_days: 365
  }
]

Enum.each(tariffs, fn tariff_attrs ->
  if is_nil(Repo.get_by(Tariff, name: tariff_attrs.name)) do
    case Context.create_tariff(tariff_attrs) do
      {:ok, tariff} -> IO.puts("Created tariff: #{tariff.name}")
      {:error, changeset} -> IO.puts("Error creating tariff #{tariff_attrs.name}: #{inspect(changeset)}")
    end
  else
    IO.puts("Tariff '#{tariff_attrs.name}' already exists. Skipping.")
  end
end)
