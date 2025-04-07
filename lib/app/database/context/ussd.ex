defmodule App.Ussd do
  @moduledoc """
  The Ussd context.
  """

  import Ecto.Query, warn: false
  alias App.Repo

  alias App.Ussd.UssdRequests

  @doc """
  Returns the list of ussd_requests.

  ## Examples

      iex> list_ussd_requests()
      [%UssdRequests{}, ...]

  """
  def list_ussd_requests do
    Repo.all(UssdRequests)
  end

  @doc """
  Gets a single ussd_requests.

  Raises `Ecto.NoResultsError` if the Ussd requests does not exist.

  ## Examples

      iex> get_ussd_requests!(123)
      %UssdRequests{}

      iex> get_ussd_requests!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ussd_requests!(id), do: Repo.get!(UssdRequests, id)

  def get_ussd_request_by_mobile_number_and_session_id(mobile_number, session_id) do
    UssdRequests
    |> where([a], a.mobile_number == ^mobile_number and a.session_id == ^session_id)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Creates a ussd_requests.

  ## Examples

      iex> create_ussd_requests(%{field: value})
      {:ok, %UssdRequests{}}

      iex> create_ussd_requests(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ussd_requests(attrs \\ %{}) do
    %UssdRequests{}
    |> UssdRequests.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a ussd_requests.

  ## Examples

      iex> update_ussd_requests(ussd_requests, %{field: new_value})
      {:ok, %UssdRequests{}}

      iex> update_ussd_requests(ussd_requests, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """


  def   update_ussd_requests(%UssdRequests{} = ussd_requests, attrs) do
    ussd_requests
    |> UssdRequests.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a ussd_requests.

  ## Examples

      iex> delete_ussd_requests(ussd_requests)
      {:ok, %UssdRequests{}}

      iex> delete_ussd_requests(ussd_requests)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ussd_requests(%UssdRequests{} = ussd_requests) do
    Repo.delete(ussd_requests)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ussd_requests changes.

  ## Examples

      iex> change_ussd_requests(ussd_requests)
      %Ecto.Changeset{data: %UssdRequests{}}

  """
  def change_ussd_requests(%UssdRequests{} = ussd_requests, attrs \\ %{}) do
    UssdRequests.changeset(ussd_requests, attrs)
  end
end
