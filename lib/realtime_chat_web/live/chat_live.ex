defmodule RealtimeChatWeb.ChatLive do
  use RealtimeChatWeb, :live_view
  alias RealtimeChat.Chat.UserPosition
  alias RealtimeChat.Repo
  import Ecto.Query, except: [update: 2, update: 3]

  @impl true
  def mount(_params, session, socket) do
    username = session["username"]

    if connected?(socket) do
      Phoenix.PubSub.subscribe(RealtimeChat.PubSub, "chat")

      # 기존 사용자 위치 가져오기
      existing_positions = from(p in UserPosition, where: p.connected == true)
                         |> Repo.all()

      # 최적의 새 위치 찾기
      {x, y} = UserPosition.find_optimal_position(existing_positions)

      # 새 사용자 위치 저장 또는 업데이트
      user_position = case Repo.get_by(UserPosition, username: username) do
        nil ->
          %UserPosition{username: username, x: x, y: y}
          |> Repo.insert!()
        existing ->
          existing
          |> Ecto.Changeset.change(connected: true, x: x, y: y)
          |> Repo.update!()
      end

      # 다른 사용자들에게 새 사용자 입장을 알림
      Phoenix.PubSub.broadcast(RealtimeChat.PubSub, "chat", {:user_joined, user_position})
    end

    socket = socket
             |> assign(:username, username)
             |> assign(:message, "")
             |> assign(:user_positions, get_connected_users())
             |> assign(:dragging, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("send", %{"message" => message}, socket) do
    username = socket.assigns.username
    user_position = Repo.get_by!(UserPosition, username: username)
    
    # 메시지 추가
    new_message = %{
      content: message,
      timestamp: DateTime.utc_now() |> DateTime.to_string()
    }
    messages = [new_message | user_position.messages]
    
    # 사용자 위치 업데이트
    user_position
    |> Ecto.Changeset.change(messages: messages)
    |> Repo.update!()

    # 브로드캐스트
    Phoenix.PubSub.broadcast(RealtimeChat.PubSub, "chat", {:new_message, username})

    {:noreply, assign(socket, :message, "")}
  end

  @impl true
  def handle_event("start_drag", _, socket) do
    {:noreply, assign(socket, :dragging, true)}
  end

  @impl true
  def handle_event("end_drag", _, socket) do
    {:noreply, assign(socket, :dragging, false)}
  end

  @impl true
  def handle_event("update_position", %{"x" => x, "y" => y}, socket) do
    username = socket.assigns.username

    # 위치 업데이트
    user_position = Repo.get_by!(UserPosition, username: username)
    user_position
    |> Ecto.Changeset.change(x: x, y: y)
    |> Repo.update!()

    # 브로드캐스트
    Phoenix.PubSub.broadcast(RealtimeChat.PubSub, "chat", {:position_updated, username, x, y})

    {:noreply, socket}
  end

  @impl true
  def handle_info({:user_joined, user_position}, socket) do
    {:noreply, Phoenix.Component.update(socket, :user_positions, &[user_position | &1])}
  end

  @impl true
  def handle_info({:new_message, _username}, socket) do
    {:noreply, assign(socket, :user_positions, get_connected_users())}
  end

  @impl true
  def handle_info({:position_updated, username, x, y}, socket) do
    {:noreply, Phoenix.Component.update(socket, :user_positions, fn positions ->
      Enum.map(positions, fn pos ->
        if pos.username == username, do: %{pos | x: x, y: y}, else: pos
      end)
    end)}
  end

  defp get_connected_users do
    from(p in UserPosition, where: p.connected == true)
    |> Repo.all()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed inset-0 flex flex-col bg-gray-100">
      <div class="flex-none h-16 bg-white shadow-sm px-4 flex items-center">
        <p class="text-gray-600">Your username: <%= @username %></p>
      </div>
      
      <div class="flex-1 relative overflow-hidden">
        <div class="absolute inset-0 p-4" 
             id="chat-canvas"
             phx-hook="ChatCanvas">
          <%= for position <- @user_positions do %>
            <div class={"user-chat-box" <> if(position.username == @username, do: " current-user", else: "")} 
                 id={"user-#{position.username}"}
                 style={"left: #{position.x}px; top: #{position.y}px"}
                 data-draggable={"#{position.username == @username}"}
                 phx-hook="Draggable">
              <div class="bg-white rounded-lg shadow-lg p-4 w-48">
                <div class="font-bold text-gray-700 mb-2"><%= position.username %></div>
                <%= if position.messages != [] do %>
                  <div class="current-message text-gray-600">
                    <%= get_in(hd(position.messages), ["content"]) %>
                  </div>
                  <div class="message-history hidden absolute bottom-full left-0 w-full bg-white rounded-lg shadow-lg p-2 mb-2">
                    <%= for message <- Enum.take(position.messages, 5) do %>
                      <div class="text-sm text-gray-600 mb-1">
                        <%= message["content"] %>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <div class="flex-none h-24 bg-white shadow-lg px-4 flex items-center justify-center">
        <form phx-submit="send" class="w-full max-w-2xl flex gap-2">
          <input type="text" name="message" value={@message} 
                 class="flex-1 rounded-lg border border-gray-300 px-4 py-2"
                 placeholder="Type your message..."
                 autocomplete="off"/>
          <button type="submit" class="bg-blue-500 text-white px-6 py-2 rounded-lg hover:bg-blue-600 transition-colors">
            Send
          </button>
        </form>
      </div>
    </div>
    """
  end
end
