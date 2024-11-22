defmodule RealtimeChat.Repo.Migrations.AddCurrentMessageToUserPositions do
  use Ecto.Migration

  def change do
    alter table(:user_positions) do
      add :current_message, :string, default: ""
    end
  end
end
