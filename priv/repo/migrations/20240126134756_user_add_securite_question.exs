defmodule App.Repo.Migrations.UserAddSecurityQuestion do
  use Ecto.Migration

  def change do
    alter table(:clients) do
      add :security_question_id, references(:security_question, on_delete: :nothing)
    end
  end
end
