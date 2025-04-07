defmodule App.Accounts.SecurityQuestions do
  use Ecto.Schema
  import Ecto.Changeset

  schema "security_question" do
    field :status, :integer
    field :question, :string

    timestamps()
  end

  @doc false
  def changeset(security_questions, attrs) do
    security_questions
    |> cast(attrs, [:question, :status])
  end
end
