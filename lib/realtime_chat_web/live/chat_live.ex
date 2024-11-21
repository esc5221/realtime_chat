defmodule RealtimeChatWeb.ChatLive do
  use RealtimeChatWeb, :live_view
  alias RealtimeChat.Chat.Message
  alias RealtimeChat.Repo

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(RealtimeChat.PubSub, "chat")
    end

    messages = Repo.all(Message) |> Enum.reverse()
    {:ok, assign(socket, messages: messages, message: "", username: "guest_#{:rand.uniform(1000)}")}
  end

  @impl true
  def handle_event("send", %{"message" => message}, socket) do
    message = %Message{
      content: message,
      username: socket.assigns.username
    }

    {:ok, message} = Repo.insert(message)
    Phoenix.PubSub.broadcast(RealtimeChat.PubSub, "chat", {:new_message, message})

    {:noreply, assign(socket, message: "")}
  end

  @impl true
  def handle_event("update_message", %{"key" => _key, "value" => value}, socket) do
    {:noreply, assign(socket, message: value)}
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    {:noreply, assign(socket, messages: socket.assigns.messages ++ [message])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl p-4">
      <div class="mb-4">
        <h1 class="text-2xl font-bold">Phoenix Chat</h1>
        <p class="text-gray-600">Your username: <%= @username %></p>
      </div>

      <div class="bg-white rounded-lg shadow-md p-4 mb-4 h-96 overflow-y-auto">
        <div class="space-y-4">
          <%= for message <- @messages do %>
            <div class={"flex #{if message.username == @username, do: 'justify-end', else: 'justify-start'}"}>
              <div class={"rounded-lg p-3 max-w-xs #{if message.username == @username, do: 'bg-blue-500 text-white', else: 'bg-gray-100'}"}>
                <p class="text-sm font-semibold"><%= message.username %></p>
                <p><%= message.content %></p>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <form phx-submit="send" class="flex gap-2">
        <input
          type="text"
          name="message"
          id="message-input"
          value={@message}
          placeholder="Type a message..."
          class="flex-1 rounded-lg border border-gray-300 px-4 py-2 focus:outline-none focus:border-blue-500"
          phx-keyup="update_message"
          phx-update="ignore"
          autocomplete="off"
        />
        <button class="bg-blue-500 text-white px-4 py-2 rounded-lg hover:bg-blue-600 focus:outline-none">
          Send
        </button>
      </form>
    </div>
    """
  end
end
