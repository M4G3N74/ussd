defmodule AppWeb.UssdEmulatorController do
  use AppWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, "index.html")
  end
end
