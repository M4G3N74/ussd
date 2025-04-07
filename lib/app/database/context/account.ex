defmodule App.Accounts do
  @moduledoc """
  The Ussd context.
  """

  import Ecto.Query, warn: false
  alias App.Repo
  alias App.Account.Client
  alias App.Accounts.SecurityQuestions

  def get_user_by_mobile_number(mobile_number) do
    Client
    |> where([a], a.mobile_number == ^mobile_number)
    |> limit(1)
    |> Repo.one()
  end

  def list_security_questions_by_status(status) do
    SecurityQuestions
    |> where([a], a.status == ^status)
    |> Repo.all()
  end

end
