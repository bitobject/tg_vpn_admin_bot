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

alias Core.Accounts

# Create admin if it doesn't exist
case Accounts.ensure_admin_exists(%{
  email: "admin@example.com",
  username: "admin",
  password: "admin123",
  password_confirmation: "admin123"
}) do
  {:ok, admin} ->
    IO.puts("Admin created: #{admin.email}")
  {:error, :admin_already_exists} ->
    IO.puts("Admin already exists")
  {:error, changeset} ->
    IO.puts("Failed to create admin: #{inspect(changeset.errors)}")
end
