defmodule AdminApiWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use AdminApiWeb, :controller
      use AdminApiWeb, :html

  The definitions below will be executed for every view,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional functions and use
  those in the quoted expressions.
  """

  def static_paths, do: []

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: AdminApiWeb.Layouts]

      import Plug.Conn
      import AdminApiWeb.Gettext

      unquote(verified_routes())
    end
  end

  # LiveView and HTML helpers removed for API-only application

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: AdminApiWeb.Endpoint,
        router: AdminApiWeb.Router,
        statics: []
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
