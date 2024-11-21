defmodule RealtimeChat.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :content, :string
      add :username, :string

      timestamps()
    end

    create index(:messages, [:inserted_at])
  end
end
