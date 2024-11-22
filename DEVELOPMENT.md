# Phoenix Realtime Chat 개발 과정

## 프로젝트 개발 과정

1. Elixir와 Phoenix 설치:
```bash
# Homebrew를 통해 Elixir 설치
brew install elixir

# Phoenix 프레임워크 설치
mix local.hex
mix archive.install hex phx_new
```

2. Phoenix 프로젝트 생성:
```bash
# LiveView 옵션을 포함하여 새 프로젝트 생성
mix phx.new realtime_chat --live
cd realtime_chat
```

3. PostgreSQL에서 SQLite로 데이터베이스 전환:
```elixir
# mix.exs 파일 수정
# {:postgrex, ">= 0.0.0"} 제거하고 {:ecto_sqlite3, "~> 0.12"} 추가

# config/dev.exs 수정
config :realtime_chat, RealtimeChat.Repo,
  database: Path.expand("../realtime_chat_dev.db", Path.dirname(__ENV__.file)),
  pool_size: 5,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

# config/test.exs도 비슷하게 수정
```

4. 메시지 스키마 및 데이터베이스 설정:
```elixir
# 메시지 테이블을 위한 마이그레이션 생성
mix ecto.gen.migration create_messages

# priv/repo/migrations/*_create_messages.exs 파일에 다음 내용 추가:
defmodule RealtimeChat.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :content, :string
      add :username, :string

      timestamps()
    end
  end
end

# 마이그레이션 실행
mix ecto.create
mix ecto.migrate
```

5. Message 스키마 생성 (lib/realtime_chat/chat/message.ex)
