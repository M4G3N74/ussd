defmodule App.Ussd.UssdRequests do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ussd_requests" do
    field :body, :string
    field :session_id, :string
    field :is_logged_in, :boolean, default: false
    field :mobile_number, :string
    field :session_ended, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(ussd_requests, attrs) do
    ussd_requests
    |> cast(attrs, [:is_logged_in, :mobile_number, :body, :session_id, :session_ended])
    |> validate_required([:is_logged_in, :mobile_number, :body, :session_id])
  end

end
