defmodule App.Service.Ussd.Menus.LoginAndRecovery.Login do
  @moduledoc false
  alias App.{
    Accounts,
    Service.Ussd.Manager,
    Service.Ussd.Menus.MainMenu1,
    Ussd,
    Util.CustomTime
  }

  def index(_mobile_number, _user, _ussd_request, []) do
    response = "Welcome to EFC Mobile Banking\n\nPlease enter your 4 digit Pin"
    Manager.send_response(response)
  end

  def index(mobile_number, user, ussd_request, [pin]) do
    if String.equivalent?(user.pin, String.trim(pin)) do
      {:ok, ussd_request} = Ussd.update_ussd_requests(ussd_request, %{"body" => "8899", "is_logged_in" => true})
      Accounts.update_user(user, %{"last_login_date" => CustomTime.local_datetime(), "status" => 1, "password_fail_count" => 0})
      MainMenu1.index(mobile_number, ussd_request, user, Manager.input_list(ussd_request.body))
    else
      count = calculate_failed_attempts_password_fail_count(user)
      Accounts.update_user(user, count)
      "Invalid pin enter (#{count["password_fail_count"]}/3), please enter correct pin"
      |> Manager.send_response_back(ussd_request)
    end
  end

  def index(_mobile_number, _user, ussd_request, _rest), do: Manager.send_response_back("Invalid option", ussd_request)

  def calculate_failed_attempts_password_fail_count(account) do
    cond do
      !is_nil(account.password_fail_count) && account.password_fail_count == 2 ->
        %{"password_fail_count" => account.password_fail_count + 1, "status" => 4}

      is_nil(account.password_fail_count) ->
        %{"password_fail_count" => 1}

      true -> %{"password_fail_count" => account.password_fail_count + 1}
    end
  end
end
