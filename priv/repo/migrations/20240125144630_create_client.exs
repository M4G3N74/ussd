defmodule App.Repo.Migrations.CreateClients do
  use Ecto.Migration

  def change do
    create table(:clients) do
      add :mobile_number, :string
      add :nrc, :string
      add :status, :integer
      add :security_question_fail_count, :integer
      add :security_answer, :string

      timestamps()
    end

    unique_index(:clients, :mobile_number)
  end
end
