defmodule App.Service.Ussd.Menus.LoginAndRecovery.ForgotPassword do
  @moduledoc false
  alias App.{
    Accounts,
    Notification,
    Service.Ussd.Manager,
  }

  def index(_mobile_number, user, _ussd_request, []) do
    question = Accounts.get_security_questions!(user.security_question_id)
    response = "Provide the answer to your security question:\n#{question.question}"
    Manager.send_response(response)
  end

  def index(_mobile_number, user, ussd_request, [answer]) do
    if answer == user.security_answer do
      response = "Please Enter Your New Pin."
      Manager.send_response(response)
    else
      count = calculate_failed_attempts_security_question_fail_count(user)
      Accounts.update_user(user, count)
      "Invalid answer enter (#{count["security_question_fail_count"]}/3), please enter correct pin"
      |> Manager.send_response_back(ussd_request)
    end
  end
  def index(_mobile_number, _user, ussd_request, [_answer, pin]) do
    if Regex.match?(~r/^([0-9]{4})+$/, String.trim(pin)) do
      response = "Please Confirm Your New Pin."
      Manager.send_response(response)
    else
      "Incorrect values provided. Please enter a valid 4-digit security pin"
      |> Manager.send_response_back(ussd_request)
    end
  end

  def index(mobile_number, user, ussd_request, [answer, pin, con_pin]) do
    if String.trim(pin) == String.trim(con_pin) do
      Accounts.update_user(user, %{"pin" => pin, "security_question_fail_count" => 0})
      Notification.create_messages(%{
        "message" => "Dear #{user.first_name}, Your Mobile Banking account pin was changed. Please log in using your new pin.",
        "recipient" => mobile_number
      })
      response = "Your PIN was successfully changed.\nThank you for using EFC Mobile Banking"
      Manager.send_response_end(response)
    else
      "Pin mismatch! The pins you have provided did not match, please enter correct pin"
      |> Manager.send_response_back(ussd_request)
    end
  end

  def index(_mobile_number, _user, _ussd_request, _) do
    response = "Invalid entry"
    Manager.send_response_end(response)
  end

  def calculate_failed_attempts_security_question_fail_count(account) do
    cond do
      !is_nil(account.security_question_fail_count) && account.security_question_fail_count == 2 ->
        %{"security_question_fail_count" => account.security_question_fail_count + 1, "status" => 4}

      is_nil(account.security_question_fail_count) ->
        %{"security_question_fail_count" => 1}

      true -> %{"security_question_fail_count" => account.security_question_fail_count + 1}
    end
  end
end
