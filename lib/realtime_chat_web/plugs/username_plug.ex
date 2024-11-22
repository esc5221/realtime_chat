defmodule RealtimeChatWeb.Plugs.UsernamePlug do
  import Plug.Conn
  alias RealtimeChat.Chat.UserPosition
  alias RealtimeChat.Repo

  @adjectives ~w(Happy Clever Swift Bright Brave Wild Calm Cool Smart Fresh
                Gentle Kind Proud Quick Wise Busy Free Bold Eager Fair)
  @nouns ~w(Fox Wolf Bear Lion Tiger Eagle Hawk Owl Deer Rabbit
            Panda Koala Whale Dragon Phoenix Falcon Dolphin Turtle)

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, "user_id")
    
    if user_id do
      case Repo.get_by(UserPosition, user_id: user_id) do
        %UserPosition{username: username} ->
          conn
          |> put_session("username", username)
          |> put_session("user_id", user_id)
        nil ->
          assign_new_user(conn)
      end
    else
      assign_new_user(conn)
    end
  end

  defp assign_new_user(conn) do
    username = generate_username()
    user_id = generate_user_id()
    
    conn
    |> put_session("username", username)
    |> put_session("user_id", user_id)
  end

  defp generate_username do
    adjective = Enum.random(@adjectives)
    noun = Enum.random(@nouns)
    number = :rand.uniform(999)
    "#{adjective}#{noun}#{number}"
  end

  defp generate_user_id do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16(case: :lower)
  end
end
