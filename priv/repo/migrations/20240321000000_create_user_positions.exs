defmodule RealtimeChat.Repo.Migrations.CreateUserPositions do
  use Ecto.Migration

  def change do
    create table(:user_positions) do
      add :username, :string, null: false
      add :x, :integer, null: false
      add :y, :integer, null: false
      add :messages, {:array, :map}, default: []
      add :connected, :boolean, default: true

      timestamps()
    end

    create unique_index(:user_positions, [:username])
  end
end
