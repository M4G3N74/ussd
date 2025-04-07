defmodule App.Service.Ussd.Menus.Auth.MemberData do
  @moduledoc false
  alias App.{
    Service.Ussd.Manager,
  }

  # handleAccountsDetails
  def index(_mobile_number, _ussd_request, _user, []) do
    """
    Welcome to this section
    """
    |> Manager.send_response_end()
  end
end
