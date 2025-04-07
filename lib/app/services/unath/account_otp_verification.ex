defmodule App.Service.Ussd.Menus.AccountOtpVerification do
  @moduledoc false
  alias App.{
    Accounts,
    Service.Ussd.Manager,
    Ussd,
    Service.Ussd.Menus.LoginAndRecovery
  }

  def index(_mobile_number, _user, _ussd_request, []) do
    "Please Enter the OTP that was sent to your mobile number"
    |> Manager.send_response()
  end

  def index(mobile_number, user, ussd_request, [opt]) do
    match = Regex.match?(~r/\A.{4}\z/, opt)
    cond do
      opt == user.user_otp && match ->
        security_questions = Accounts.list_security_questions_by_status(1)

        Cachex.put(:ussd, mobile_number, security_questions)
        Cachex.expire(:ussd, mobile_number, :timer.minutes(4))

        menu =
          Enum.with_index(security_questions, 1)
          |> Enum.map_join("\n", fn {%{question: name}, idx} -> "#{idx}. #{name}" end)
          |> String.trim()

        "Choose a security question to answer.\n\n" <> menu <> "\nb. Back"
        |> Manager.send_response()

      match ->
        "Invalid OTP. make sure you enter 4 digits."
        |> Manager.send_response_back(ussd_request)

      true ->
        "Invalid OTP. make sure you enter the correct OTP."
        |> Manager.send_response_back(ussd_request)
    end
  end

  def index(mobile_number, user, ussd_request, [opt, question_idx]) do
    try do
      num = String.to_integer(question_idx)
      {:ok, questions_list} = Cachex.get(:ussd, mobile_number)
      Cachex.expire(:ussd, mobile_number, :timer.minutes(4))
      selected = Enum.at(questions_list, num - 1)
      if is_nil(selected) do
        "You have selected an invalid option"
        |> Manager.send_response_end()
      else
        Cachex.put(:ussd, mobile_number <> "Question", selected)
        Cachex.expire(:ussd, mobile_number <> "Question", :timer.minutes(4))
        "#{selected.question}\nEnter the answer to above question"
        |> Manager.send_response()
      end
    rescue
      e ->
        IO.inspect e
        response = "Invalid entry"
        Manager.send_response_end(response)
    end
  end

  def index(mobile_number, _user, _ussd_request, [opt, question_idx, answer]) do
    Cachex.expire(:ussd, mobile_number <> "Question", :timer.minutes(4))
    "Enter a 4-Digit security pin"
    |> Manager.send_response()

  end

  def index(mobile_number, _user, ussd_request, [opt, question_idx, answer, pin]) do
    Cachex.expire(:ussd, mobile_number <> "Question", :timer.minutes(4))
   # if Regex.match?(~r/^([0-9]{4})+$/, String.trim(pin)) do
    if String.match?(pin, ~r/^[0-9]+$/) and String.length(pin) == 4 do
      "Retype the 4-Digit security pin"
      |> Manager.send_response()
    else
      "Incorrect values provided. Please enter a valid 4-digit security pin"
      |> Manager.send_response_back(ussd_request)
    end

  end

  def index(mobile_number, user, ussd_request, [opt, question_idx, answer, pin, confirm_pin]) do
    IO.inspect pin, label: "iiiiiiiiiiiiiiiiiiiiii"
    IO.inspect confirm_pin, label: "iiiiiiiiiiiiiiiiconfirm_piniiiiii"
    #if String.trim(pin) == String.trim(confirm_pin) do
   # if String.match?(pin, ~r/^[0-9]+$/)  == String.match?(confirm_pin, ~r/^[0-9]+$/) do
      if pin ==  confirm_pin do
      {:ok, body} = Cachex.get(:ussd, mobile_number <> "RimInfo")
      {:ok, question} = Cachex.get(:ussd, mobile_number <> "Question")
      Cachex.expire(:ussd, mobile_number <> "Question", :timer.minutes(4))
      firstName = body["RmInfoByRimRs"]["RmInfoByRim"]["RmFirstName"]
        user = Accounts.update_user(user, %{
          "status" => 1,
          "pin" => String.trim(pin),
          "security_answer" => answer,
          "security_question_fail_count" => 0,
          "security_question_id" => question.id,
        })
       "Dear #{firstName} You have successfully activated your EFC mobile banking. Dail *8899# now."
      |> Manager.send_response_end()
    else
      "Incorrect values provided. Please re-enter a the same security pin"
      |> Manager.send_response_back(ussd_request)
    end
        {:ok, ussd_request} = Ussd.update_ussd_requests(ussd_request, %{"body" => "8899"})
        LoginAndRecovery.index(mobile_number, user, ussd_request, Manager.input_list(ussd_request.body))
    end

  def index(_mobile_number, _ussd_request, _list) do
    "Invalid entry"
     |> Manager.send_response_end()
  end

end
