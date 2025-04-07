defmodule App.Service.Ussd.Menus.MainMenu do
  @moduledoc false
  alias App.{Service.Ussd.Manager, Ussd}
  alias App.Service.Ussd.Menus.Auth.{
    MemberData,
  }


  defp welcome_menu() do
    """
    Welcome to Kwacha Pensons
    1. View Member bio data
    0. Logout
    """
    |> Manager.send_response()
  end

  # welcome_menu
  def index(_mobile_number, ussd_request, _user, ["0"]) do
    {:ok, _ussd_request} = Ussd.update_ussd_requests(ussd_request, %{"body" => "8899", "is_logged_in" => false})
    "Thank you for using Kwacha Pensions"
    |> Manager.send_response_end()
  end

  def index(_mobile_number, _ussd_request, _user, []),
      do: welcome_menu()

  def index(mobile_number, ussd_request, user, ["1" | rest]),
      do: MemberData.index(mobile_number, ussd_request, user, rest)

  def index(_mobile_number, ussd_request, _user, _) do
    "You have selected an invalid option, please select a valid option."
    |> Manager.send_response_back(ussd_request)
  end

end
