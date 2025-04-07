defmodule App.Service.Ussd.Menus.LoginAndRecovery do
  @moduledoc false
  alias App.{
    Service.Ussd.Manager,
    Service.Ussd.Menus.LoginAndRecovery.Login,
    Service.Ussd.Menus.LoginAndRecovery.ForgotPassword,
  }

  def index(_mobile_number, _user, _ussd_request, []) do
    response = "Welcome to EFC Mobile Banking\n\n1. Login\n2. Forgot your pin"
    Manager.send_response(response)
  end

  def index(mobile_number, user, ussd_request, ["1" | rest]),
      do: Login.index(mobile_number, user, ussd_request, rest)

  def index(mobile_number, user, ussd_request, ["2" | rest]),
      do: ForgotPassword.index(mobile_number, user, ussd_request, rest)

  def index(_mobile_number, _user, _ussd_request, _rest) do
    response = "Invalid entry"
    Manager.send_response_end(response)
  end

end
