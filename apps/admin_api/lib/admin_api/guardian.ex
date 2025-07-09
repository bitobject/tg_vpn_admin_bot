defmodule AdminApi.Guardian do
  use Guardian, otp_app: :admin_api

  alias AdminApiWeb.AdminContext

  def subject_for_token(%{id: id}, _claims) do
    sub = to_string(id)
    {:ok, sub}
  end

  def subject_for_token(_, _) do
    {:error, :reason_for_error}
  end

  def resource_from_claims(%{"sub" => id}) do
    admin = AdminContext.get_admin!(id)
    {:ok, admin}
  rescue
    Ecto.NoResultsError -> {:error, :resource_not_found}
  end

  def resource_from_claims(_claims) do
    {:error, :reason_for_error}
  end

  @doc """
  Creates a token for an admin.
  """
  def create_token(admin) do
    encode_and_sign(admin, %{}, ttl: {1, :day})
  end

  @doc """
  Creates a refresh token for an admin.
  """
  def create_refresh_token(admin) do
    encode_and_sign(admin, %{}, ttl: {30, :days}, token_type: "refresh")
  end

  @doc """
  Refreshes a token using a refresh token.
  """
  def refresh_token(refresh_token) do
    case refresh(refresh_token, ttl: {1, :day}) do
      {:ok, _old_stuff, {new_token, new_claims}} ->
        {:ok, new_token, new_claims}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Revokes a token.
  """
  def revoke_token(token) do
    revoke(token)
  end
end
