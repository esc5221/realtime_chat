defmodule RealtimeChat.Repo.Migrations.AddUserIdToUserPositions do
  use Ecto.Migration

  def change do
    alter table(:user_positions) do
      add :user_id, :string
    end

    create index(:user_positions, [:user_id])
  end
end
