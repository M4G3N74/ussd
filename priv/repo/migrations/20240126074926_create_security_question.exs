defmodule App.Repo.Migrations.CreateSecurityQuestion do
  use Ecto.Migration

  def change do
    create table(:security_question) do
      add :question, :string
      add :status, :integer, default: 1

      timestamps()
    end
  end
end
