defmodule AdminApiWeb.Router do
  use AdminApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug AdminApiWeb.Plugs.RateLimit
  end

  pipeline :auth do
    plug AdminApiWeb.Plugs.Authenticate
  end

  pipeline :admin do
    plug AdminApiWeb.Plugs.Authorize, :admin
  end

  pipeline :user do
    plug AdminApiWeb.Plugs.Authorize, :user
  end

  # Public routes (no authentication required)
  scope "/api/v1", AdminApiWeb do
    pipe_through :api

    # Authentication routes
    post "/auth/login", AuthController, :login
    post "/auth/refresh", AuthController, :refresh
  end

  # Protected routes (authentication required)
  scope "/api/v1", AdminApiWeb do
    pipe_through [:api, :auth]

    # User profile
    get "/auth/me", AuthController, :me
    post "/auth/logout", AuthController, :logout

    # Admin management (admin only)
    scope "/admins" do
      pipe_through :admin

      get "/", AdminController, :index
      post "/", AdminController, :create
      get "/:id", AdminController, :show
      put "/:id", AdminController, :update
      patch "/:id", AdminController, :update
      delete "/:id", AdminController, :delete
      put "/:id/password", AdminController, :update_password
      patch "/:id/password", AdminController, :update_password
    end
  end

  # Health check endpoint
  scope "/api/v1", AdminApiWeb do
    pipe_through :api

    get "/health", HealthController, :check
  end

  # Swagger documentation
  scope "/api" do
    pipe_through :api

    forward "/swagger", PhoenixSwagger.Plug.SwaggerUI,
      otp_app: :admin_api,
      swagger_file: "swagger.json",
      disable_validator: true
  end
end
