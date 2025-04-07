defmodule App.Repo.Migrations.CreateUssdRequests do
  use Ecto.Migration

  def change do
    create table(:ussd_requests) do
      add :is_logged_in, :boolean, default: false, null: false
      add :mobile_number, :string
      add :body, :string
      add :session_id, :string
      add :session_ended, :boolean, default: false, null: false

      timestamps()
    end

    index(:ussd_requests, :mobile_number)
  end
end
