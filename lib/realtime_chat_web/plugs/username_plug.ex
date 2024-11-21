defmodule RealtimeChatWeb.Plugs.UsernamePlug do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    if get_session(conn, "username") do
      conn
    else
      username = "guest_#{:rand.uniform(1000)}"
      put_session(conn, "username", username)
    end
  end
end
