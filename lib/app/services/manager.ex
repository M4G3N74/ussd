defmodule App.Service.Ussd.Manager do
  @moduledoc false
  alias App.{
    Accounts,
    Ussd
  }

  alias App.Service.Ussd.Menus.{
    AccountOtpVerification,
    MainMenu,
    LoginAndRecovery,
    SelfRegistration
  }

  def index({ussd_request, input}, mobile_number, session_id) do
    query_list = input_list(input)
    user = Accounts.get_user_by_mobile_number(mobile_number)

    cond do
      is_nil(user) ->
        SelfRegistration.index(mobile_number, ussd_request, query_list)

      user.status == 3 -> AccountOtpVerification.index(mobile_number, user, ussd_request, query_list)

      !ussd_request.is_logged_in && user.status == 1 -> LoginAndRecovery.index(mobile_number, user, ussd_request, query_list)

      !ussd_request.is_logged_in || user.status == 4 ->
        "Your Account Was Locked. Contact EFC Staff To Assist You With Reactivating Your Account."
        |> send_response_end()

      true ->
        MainMenu.index(mobile_number, ussd_request, user, query_list)
    end
  end

  def create_query_string(input, mobile_number, session_id) do
    Ussd.get_ussd_request_by_mobile_number_and_session_id(mobile_number, session_id)
    |> case do
         nil ->
           {:ok, ussd_request} = Ussd.create_ussd_requests(%{"mobile_number" => mobile_number, "body" => "8899", "session_id" => session_id})
           {ussd_request, ussd_request.body}

         ussd_request ->
           text =
             "#{String.trim_trailing(ussd_request.body, " ")}*#{String.trim_leading(input, "*")}"
             |> String.replace("*B*", "*b*")
             |> String.replace("*B", "*b")
             |> String.replace("**", "*")

           {:ok, ussd_request} = Ussd.update_ussd_requests(ussd_request, %{"body" => text})
           {ussd_request, text}
       end
  end

  def proceed_with_query_string_creation({ussd_request, tempText}) do
    cond do
      String.ends_with?(tempText, "*00") ->
        Ussd.update_ussd_requests(ussd_request, %{"body" => "8899"})
        {ussd_request, "8899"}

      String.ends_with?(tempText, "*b") ->
        query_string =
          String.split(tempText, "*")
          |> Enum.drop(-2)
          |> Enum.join("*")

        Ussd.update_ussd_requests(ussd_request, %{"body" => query_string})
        {ussd_request, query_string}

      true -> {ussd_request, tempText}
    end
  end

  def get_ussd_provider(mobile_number) do
    String.slice(mobile_number, 0..4)
    |> case do
         string when string in ["26097", "2607"] -> "AIRTEL"

         string when string in ["26096", "2606"] -> "MTN"

         string when string in ["26095", "2605"] -> "ZAMTEL"

         _ -> "UNKNOWN"
       end
  end

  def end_session(ussd_request, response) do
    Ussd.update_ussd_requests(ussd_request, %{
      "session_ended" => true
    })
    send_response_end(response)
  end

  def send_response_back(response, ussd_request) do
    query_string =
      String.split(ussd_request.body, "*")
      |> Enum.drop(-1)
      |> Enum.join("*")

    Ussd.update_ussd_requests(ussd_request, %{"body" => query_string})
    send_response(response)
  end

  def send_response(response) do
    %{"body" => response, "type" => 2}
  end

  def send_response_end(response) do
    %{"body" => response, "type" => 1}
  end

  def input_list(input) do
    String.split(input, "*")
    |> Enum.drop(1)
  end
end
