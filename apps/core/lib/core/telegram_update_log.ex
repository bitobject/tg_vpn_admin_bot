defmodule Core.TelegramUpdateLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "telegram_update_logs" do
    field :user_id, :integer
    field :update, :map
    timestamps()
  end

  @doc false
  def changeset(log, attrs) do
    log
    |> cast(attrs, [:user_id, :update])
    |> validate_required([:update])
  end
end
