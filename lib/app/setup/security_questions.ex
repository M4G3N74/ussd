defmodule App.SetUp.SecurityQuestions do
  @moduledoc false
  alias App.{Repo, Accounts.SecurityQuestions}

  def init() do
    [
      %{question: "What is your pets name?", status: 1},
      %{question: "What is your city of birth?", status: 1},
      %{question: "What is your mothers name?", status: 1},
    ]
    |> Enum.map(fn data ->
      Repo.insert!(%SecurityQuestions{
        question: data[:question],
        status: data[:status]
      })
    end)
  end
end
