defmodule AdminApiWeb.AuthController do
  use AdminApiWeb, :controller

  alias AdminApiWeb.AdminContext
  alias AdminApi.Guardian

  @doc """
  Authenticates a user and returns JWT tokens.
  """
  def login(conn, %{"login" => login, "password" => password}) do
    case AdminContext.authenticate_admin(login, password) do
      {:ok, admin} ->
        # Update last login timestamp
        AdminContext.update_admin_last_login(admin)

        # Create tokens
        {:ok, token, _claims} = Guardian.create_token(admin)
        {:ok, refresh_token, _claims} = Guardian.create_refresh_token(admin)

        conn
        |> put_status(:ok)
        |> json(%{
          token: token,
          refresh_token: refresh_token,
          admin: %{
            id: admin.id,
            email: admin.email,
            username: admin.username,
            role: admin.role
          }
        })

      {:error, :not_found} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid credentials"})

      {:error, :invalid_password} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid credentials"})
    end
  end

  def login(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Login and password are required"})
  end

  @doc """
  Refreshes a JWT token using a refresh token.
  """
  def refresh(conn, %{"refresh_token" => refresh_token}) do
    case Guardian.refresh_token(refresh_token) do
      {:ok, token, claims} ->
        conn
        |> put_status(:ok)
        |> json(%{
          token: token,
          expires_at: claims["exp"]
        })

      {:error, _reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid refresh token"})
    end
  end

  def refresh(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Refresh token is required"})
  end

  @doc """
  Logs out a user by revoking their token.
  """
  def logout(conn, _params) do
    token = get_token(conn)

    case token do
      nil ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "No token provided"})

      token ->
        Guardian.revoke_token(token)

        conn
        |> put_status(:ok)
        |> json(%{message: "Successfully logged out"})
    end
  end

  @doc """
  Returns the current admin's profile.
  """
  def me(conn, _params) do
    admin = conn.assigns.current_admin

    conn
    |> put_status(:ok)
    |> json(%{
      id: admin.id,
      email: admin.email,
      username: admin.username,
      role: admin.role,
      is_active: admin.active,
      last_login_at: admin.last_login_at
    })
  end

  defp get_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> token
      _ -> nil
    end
  end
end
