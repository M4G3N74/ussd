defmodule AppWeb.MtnController do
  use AppWeb, :controller
  alias App.Service.Ussd.Manager

  def index(conn, params) do
    start_input =
      String.replace(params["input"], "*", "")
      |> String.replace("#", "")

    mobile_number = params["msisdn"]
    session_id = params["sessionId"]

    (if String.equivalent?(start_input, "778") || String.equivalent?(start_input, "8899"), do: "8899", else: start_input)
    |> Manager.create_query_string(mobile_number, session_id)
    |> Manager.proceed_with_query_string_creation()
    |> Manager.index(mobile_number, session_id)
    |> send_response(conn)
  end

  defp send_response(response, conn) do
    conn
    |> put_status(:ok)
    |> put_resp_header("Freeflow", (if response["type"] == 2, do: "FC", else: "FB"))
    |> send_resp(:ok, response["body"])
  end
end
