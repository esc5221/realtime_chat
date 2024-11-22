defmodule RealtimeChatWeb.ChatLive do
  use RealtimeChatWeb, :live_view
  alias RealtimeChat.Chat.UserPosition
  alias RealtimeChat.Repo
  import Ecto.Query, except: [update: 2, update: 3]

  @impl true
  def mount(_params, %{"username" => username, "user_id" => user_id}, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(RealtimeChat.PubSub, "chat")

      # Schedule periodic cleanup
      if connected?(socket), do: Process.send_after(self(), :cleanup_inactive_users, :timer.seconds(30))

      # 기존 사용자 목록 가져오기
      user_positions = 
        UserPosition.get_active_users()
        |> Repo.all()
        |> Enum.uniq_by(& &1.user_id)

      # 새 사용자의 position 생성 또는 업데이트
      user_position =
        case Repo.get_by(UserPosition, user_id: user_id) do
          nil ->
            %UserPosition{
              username: username,
              user_id: user_id,
              x: 600,
              y: 400,
              connected: true,
              messages: [],
              last_active: DateTime.utc_now() |> DateTime.truncate(:second)
            }
            |> Repo.insert!()

          existing ->
            existing
            |> UserPosition.update_last_active()
            |> Ecto.Changeset.change(connected: true)
            |> Repo.update!()
        end

      # 다른 클라이언트들에게 알림
      Phoenix.PubSub.broadcast(RealtimeChat.PubSub, "chat", {:user_joined, user_position})

      {:ok,
       socket
       |> assign(:user_positions, Enum.uniq_by([user_position | user_positions], & &1.user_id))
       |> assign(:username, username)
       |> assign(:user_id, user_id)
       |> assign(:message, "")
       |> assign(:show_username_modal, false)
       |> assign(:dragging, false)}
    else
      {:ok,
       socket
       |> assign(:username, username)
       |> assign(:user_id, user_id)
       |> assign(:message, "")
       |> assign(:show_username_modal, false)
       |> assign(:dragging, false)
       |> assign(:user_positions, [])}
    end
  end

  @impl true
  def handle_event("send", %{"message" => message}, socket) do
    username = socket.assigns.username
    user_position = Repo.get_by!(UserPosition, user_id: socket.assigns.user_id)

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
  def handle_event("typing", %{"value" => message}, socket) do
    username = socket.assigns.username
    user_position = Repo.get_by!(UserPosition, user_id: socket.assigns.user_id)

    # 현재 메시지 업데이트 (임시)
    user_position
    |> Ecto.Changeset.change(current_message: message)
    |> Repo.update!()

    # 브로드캐스트
    Phoenix.PubSub.broadcast(RealtimeChat.PubSub, "chat", {:typing, username, message})

    {:noreply, assign(socket, :message, message)}
  end

  @impl true
  def handle_event("keydown", %{"key" => "Enter", "value" => message}, socket) when message != "" do
    username = socket.assigns.username
    user_position = Repo.get_by!(UserPosition, user_id: socket.assigns.user_id)

    # 메시지를 히스토리에 추가
    new_message = %{
      "content" => message,
      "timestamp" => DateTime.utc_now() |> DateTime.to_string()
    }
    messages = [new_message | user_position.messages]

    # 사용자 위치 업데이트
    user_position
    |> Ecto.Changeset.change(messages: messages, current_message: "")
    |> Repo.update!()

    # 브로드캐스트
    Phoenix.PubSub.broadcast(RealtimeChat.PubSub, "chat", {:new_message, username})

    {:noreply, assign(socket, :message, "")}
  end

  def handle_event("keydown", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("save_message", %{"message" => message}, socket) do
    username = socket.assigns.username
    user_position = Repo.get_by!(UserPosition, user_id: socket.assigns.user_id)

    # 메시지를 히스토리에 추가
    new_message = %{
      content: message,
      timestamp: DateTime.utc_now() |> DateTime.to_string()
    }
    messages = [new_message | user_position.messages]

    # 사용자 위치 업데이트
    user_position
    |> Ecto.Changeset.change(messages: messages, current_message: "")
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
    user_id = socket.assigns.user_id

    # 위치 업데이트
    user_position = Repo.get_by!(UserPosition, user_id: user_id)

    {:ok, updated_position} =
      user_position
      |> UserPosition.update_last_active()
      |> Ecto.Changeset.change(%{x: x, y: y})
      |> Repo.update()

    # 브로드캐스트
    Phoenix.PubSub.broadcast(RealtimeChat.PubSub, "chat", {:position_updated, user_id, x, y})

    {:noreply,
      socket
      |> assign(:user_positions, 
        socket.assigns.user_positions
        |> Enum.uniq_by(& &1.user_id)  # 중복 제거
        |> Enum.map(fn pos ->
          if pos.user_id == user_id, do: updated_position, else: pos
        end)
      )}
  end

  @impl true
  def handle_event("toggle_username_modal", _, socket) do
    {:noreply, assign(socket, :show_username_modal, !socket.assigns.show_username_modal)}
  end

  @impl true
  def handle_event("change_username", %{"username" => new_username}, socket) do
    user_id = socket.assigns.user_id
    old_username = socket.assigns.username
    user_position = Repo.get_by!(UserPosition, user_id: user_id)

    case Repo.get_by(UserPosition, username: new_username) do
      nil ->
        # Update the username in user_position
        {:ok, updated_position} =
          user_position
          |> Ecto.Changeset.change(username: new_username)
          |> Repo.update()

        # Update local state first
        socket =
          socket
          |> assign(:username, new_username)
          |> assign(:show_username_modal, false)
          |> assign(:user_positions, Enum.map(socket.assigns.user_positions, fn pos ->
            if pos.user_id == user_id, do: updated_position, else: pos
          end))

        # Broadcast the change to other clients
        Phoenix.PubSub.broadcast(RealtimeChat.PubSub, "chat", {:username_changed, old_username, new_username})

        {:noreply, socket}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Username already taken")
         |> assign(:show_username_modal, true)}
    end
  end

  @impl true
  def handle_info({:username_changed, old_username, new_username}, socket) do
    # Update user_positions list with new username
    updated_positions = Enum.map(socket.assigns.user_positions, fn pos ->
      if pos.username == old_username do
        %{pos | username: new_username}
      else
        pos
      end
    end)

    {:noreply, assign(socket, :user_positions, updated_positions)}
  end

  @impl true
  def handle_info({:user_joined, user_position}, socket) do
    updated_positions =
      socket.assigns.user_positions
      |> Enum.reject(& &1.user_id == user_position.user_id)  # 기존 position 제거
      |> Enum.concat([user_position])  # 새 position 추가
      |> Enum.uniq_by(& &1.user_id)  # 안전을 위한 중복 제거

    {:noreply, assign(socket, :user_positions, updated_positions)}
  end

  @impl true
  def handle_info({:new_message, _username}, socket) do
    {:noreply, assign(socket, :user_positions, UserPosition.get_active_users() |> Repo.all() |> Enum.uniq_by(& &1.user_id))}
  end

  @impl true
  def handle_info({:typing, username, message}, socket) do
    {:noreply, Phoenix.Component.update(socket, :user_positions, fn positions ->
      Enum.map(positions, fn pos ->
        if pos.username == username, do: %{pos | current_message: message}, else: pos
      end)
    end)}
  end

  @impl true
  def handle_info({:position_updated, user_id, x, y}, socket) do
    {:noreply, 
      socket
      |> assign(:user_positions, 
        socket.assigns.user_positions
        |> Enum.uniq_by(& &1.user_id)  # 중복 제거
        |> Enum.map(fn pos ->
          if pos.user_id == user_id, do: %{pos | x: x, y: y}, else: pos
        end)
      )}
  end

  @impl true
  def handle_info(:cleanup_inactive_users, socket) do
    # Schedule next cleanup
    if connected?(socket), do: Process.send_after(self(), :cleanup_inactive_users, :timer.seconds(30))

    # Get only active users
    active_users = 
      UserPosition.get_active_users()
      |> Repo.all()
      |> Enum.uniq_by(& &1.user_id)

    {:noreply, assign(socket, :user_positions, active_users)}
  end

  defp get_connected_users do
    from(p in UserPosition, where: p.connected == true)
    |> Repo.all()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed inset-0 flex flex-col bg-gray-100">
      <div class="flex-none h-16 bg-white shadow-sm px-4 flex items-center justify-between">
        <div class="flex items-center space-x-2">
          <div class="text-gray-600">Your username:</div>
          <button class="px-3 py-1 bg-purple-100 hover:bg-purple-200 text-purple-700 rounded-full transition-colors duration-200 flex items-center space-x-1"
                  phx-click="toggle_username_modal">
            <span class="font-semibold"><%= @username %></span>
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
            </svg>
          </button>
        </div>
        <div class="text-sm text-gray-500">Click and drag your chat box to move it</div>
      </div>

      <%= if @show_username_modal do %>
        <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div class="bg-white rounded-lg shadow-xl p-6 w-96">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Change Username</h3>
            <form phx-submit="change_username" class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700">New Username</label>
                <input type="text" name="username" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-purple-500 focus:ring-purple-500"
                       value={@username}
                       required
                       autocomplete="off"/>
              </div>
              <%= if Phoenix.Flash.get(@flash, :error) do %>
                <p class="text-sm text-red-600"><%= Phoenix.Flash.get(@flash, :error) %></p>
              <% end %>
              <div class="flex justify-end space-x-3">
                <button type="button"
                        class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-md"
                        phx-click="toggle_username_modal">
                  Cancel
                </button>
                <button type="submit"
                        class="px-4 py-2 text-sm font-medium text-white bg-purple-600 hover:bg-purple-700 rounded-md">
                  Save
                </button>
              </div>
            </form>
          </div>
        </div>
      <% end %>

      <div class="flex-1 relative overflow-hidden">
        <div class="absolute inset-0 p-4 canvas-container"
             id="chat-canvas"
             phx-hook="ChatCanvas">
          <%= for position <- @user_positions do %>
            <div class={"user-chat-box fixed select-none" <> if(position.username == @username, do: " current-user cursor-grab", else: "")} 
                 id={"chat-#{position.user_id}"}
                 style={"transform: translate3d(#{position.x}px, #{position.y}px, 0); opacity: #{UserPosition.get_opacity(position)}"}
                 data-draggable={if position.user_id == @user_id, do: "true", else: "false"}
                 phx-hook="Draggable">
              <div class="bg-white rounded-lg shadow-lg p-4 w-48">
                <div class="font-bold text-gray-700 mb-2"><%= position.username %></div>
                <div class="current-message text-gray-600 min-h-[1.5rem]">
                  <%= position.current_message %>
                </div>
                <%= if position.messages != [] do %>
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
        <div class="w-full max-w-2xl">
          <input type="text"
                 value={@message}
                 phx-keyup="typing"
                 phx-keydown="keydown"
                 class="w-full rounded-lg border border-gray-300 px-4 py-2"
                 placeholder="Type your message..."
                 autocomplete="off"/>
        </div>
      </div>
    </div>
    """
  end
end
