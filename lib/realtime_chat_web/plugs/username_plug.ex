defmodule RealtimeChatWeb.Plugs.UsernamePlug do
  import Plug.Conn

  @adjectives ~w(Happy Clever Swift Bright Brave Wild Calm Cool Smart Fresh
                Gentle Kind Proud Quick Wise Busy Free Bold Eager Fair)
  @nouns ~w(Fox Wolf Bear Lion Tiger Eagle Hawk Owl Deer Rabbit
            Panda Koala Whale Dragon Phoenix Falcon Dolphin Turtle)

  def init(opts), do: opts

  def call(conn, _opts) do
    if get_session(conn, "username") do
      conn
    else
      username = generate_username()
      put_session(conn, "username", username)
    end
  end

  defp generate_username do
    adjective = Enum.random(@adjectives)
    noun = Enum.random(@nouns)
    number = :rand.uniform(999)
    "#{adjective}#{noun}#{number}"
  end
end
