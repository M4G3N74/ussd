defmodule AppWeb.Router do
  use AppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AppWeb do
    pipe_through :browser

    get "/", UssdEmulatorController, :home
  end

  scope "/", AppWeb do
    pipe_through :api

    match :*, "/ussd", MtnController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", AppWeb do
  #   pipe_through :api
  # end

  # Enable Swoosh mailbox preview in development
  if Application.compile_env(:app, :dev_routes) do

    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
