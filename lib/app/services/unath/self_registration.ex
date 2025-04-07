defmodule App.Service.Ussd.Menus.SelfRegistration do
  @moduledoc false
  alias App.{
    Accounts,
    Service.Ussd.Manager
  }

  def index(_mobile_number, _ussd_request, []) do
    "Welcome to Kwacha \n\n1. Register"
    |> Manager.send_response()
  end

  def index(_mobile_number, _ussd_request, ["1"]) do
    "Enter NRC"
    |> Manager.send_response()
  end

  def index(mobile_number, ussd_request, ["1", id_number]) do
    user = Accounts.get_user_by_mobile_number(mobile_number)
    security_questions = Accounts.list_security_questions_by_status(1)

    cond do
      !is_nil(user) ->
        "User with the id number #{id_number} already exists, enter a different ID number"
        |> Manager.send_response_back(ussd_request)

      Enum.empty?(security_questions) ->
        "Security questions not set yet, please try again later."
        |> Manager.send_response_end()

        Cachex.put(:ussd, mobile_number, security_questions)
        Cachex.expire(:ussd, mobile_number, :timer.minutes(4))

        menu =
          Enum.with_index(security_questions, 1)
          |> Enum.map_join("\n", fn {%{question: name}, idx} -> "#{idx}. #{name}" end)
          |> String.trim()

        ("Choose a security question to answer.\n\n" <> menu <> "\nb. Back")
        |> Manager.send_response()

      true ->
        "Could not process you request at the moment. Please enter a valid #{id_number} Number"
        |> Manager.send_response_back(ussd_request)
    end
  end

  def index(mobile_number, ussd_request, ["1", id_number, question_idx]) do
    try do
      num = String.to_integer(question_idx)
      {:ok, data} = Cachex.get(:ussd, mobile_number)
      Cachex.expire(:ussd, mobile_number, :timer.minutes(4))
      selected = Enum.at(data, num - 1)

      if is_nil(selected) do
        response = "You have selected an invalid option"
        Manager.send_response_end(response)
      else
        Cachex.put(:ussd, mobile_number <> "Question", selected)
        Cachex.expire(:ussd, mobile_number <> "Question", :timer.minutes(4))

        "#{selected.question}\nEnter the answer to above question"
        |> Manager.send_response()
      end
    rescue
      e ->
        IO.inspect(e)
        response = "Invalid entry"
        Manager.send_response_end(response)
    end
  end

  def index(mobile_number, _ussd_request, [
        "1",
        _rim_number,
        _id_type,
        _id_number,
        _question_idx,
        _answer
      ]) do
    Cachex.expire(:ussd, mobile_number <> "Question", :timer.minutes(4))

    "Enter a 4-Digit security pin"
    |> Manager.send_response()
  end

  def index(mobile_number, ussd_request, [
        "1",
        _rim_number,
        _id_type,
        _id_number,
        _question_idx,
        _answer,
        pin
      ]) do
    Cachex.expire(:ussd, mobile_number <> "Question", :timer.minutes(4))

    if Regex.match?(~r/^([0-9]{4})+$/, String.trim(pin)) do
      "Retype the 4-Digit security pin"
      |> Manager.send_response()
    else
      "Incorrect values provided. Please enter a valid 4-digit security pin"
      |> Manager.send_response_back(ussd_request)
    end
  end

  def index(
        mobile_number,
        ussd_request,
        ["1", rim_number, _id_type, id_number, _question_idx, answer, pin, con_pin]
      ) do
    if String.trim(pin) == String.trim(con_pin) do
      {:ok, body} = Cachex.get(:ussd, mobile_number <> "RimInfo")
      {:ok, question} = Cachex.get(:ussd, mobile_number <> "Question")
      Cachex.expire(:ussd, mobile_number <> "Question", :timer.minutes(4))
      firstName = body["RmInfoByRimRs"]["RmInfoByRim"]["RmFirstName"]

      Accounts.create_ussd_user(%{
        "username" => String.pad_leading(mobile_number, 12, "26"),
        "first_name" => firstName,
        "last_name" => body["RmInfoByRimRs"]["RmInfoByRim"]["RmLastName"],
        "other_name" => body["RmInfoByRimRs"]["RmInfoByRim"]["RmMiddleName"],
        "rim_no" => rim_number,
        "security_answer" => Pbkdf2.hash_pwd_salt(String.downcase(String.trim(answer))),
        "user_type" => 2,
        "role_id" => 3,
        "security_question_id" => question.id,
        "rim_type" => body["RmInfoByRimRs"]["RmInfoByRim"]["RmType"],
        "rim_status" => body["RmInfoByRimRs"]["RmInfoByRim"]["RmStatus"],
        "rim_branch" => body["RmInfoByRimRs"]["RmInfoByRim"]["RmBranchName"],
        "rim_id_number" => id_number,
        "user_otp" => NumberF.randomizer(4, :numeric),
        "security_question_fail_count" => 0,
        "mobile_number" => String.pad_leading(mobile_number, 12, "26"),
        "status" => 3,
        "pin" => String.trim(pin),
        "password_fail_count" => 0,
        "password" => "USSD#{pin}",
        "auto_password" => false
      })

      "Dear #{firstName} You have successfully activated your EFC mobile banking. Dail *8899# now."
      |> Manager.send_response_end()
    else
      "Incorrect values provided. Please re-enter a the same security pin"
      |> Manager.send_response_back(ussd_request)
    end
  end

  def index(_mobile_number, _ussd_request, _list) do
    response = "Invalid entry"
    Manager.send_response_end(response)
  end
end
