defmodule App.Account.Client do
  use Ecto.Schema
  import Ecto.Changeset

  schema "clients" do
    field :mobile_number, :string
    field :nrc, :string
    field(:security_answer, :string)

    field(:security_question_fail_count, :integer)
    belongs_to(:security_question, App.Accounts.SecurityQuestions)

    timestamps()
  end

  @doc false
  def changeset(clients, attrs) do
    clients
    |> cast(attrs, [:mobile_number, :nrc, :security_question_id, :security_answer, :security_question_fail_count])
    |> validate_required([:mobile_number, :nrc])
  end

end
