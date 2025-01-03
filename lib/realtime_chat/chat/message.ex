defmodule RealtimeChat.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :content, :string
    field :username, :string

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :username])
    |> validate_required([:content, :username])
  end
end
