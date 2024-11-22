defmodule RealtimeChat.Repo.Migrations.AddLastActiveToUserPositions do
  use Ecto.Migration

  def change do
    alter table(:user_positions) do
      add :last_active, :utc_datetime
    end

    execute "UPDATE user_positions SET last_active = DATETIME('now')"
  end
end
