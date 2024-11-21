# Phoenix Realtime Chat

실시간 채팅 기능을 구현한 Phoenix 웹 애플리케이션입니다. Phoenix의 LiveView와 PubSub 기능을 활용하여 실시간 메시지 전송과 수신을 구현했습니다.

## 기술 스택

- Elixir
- Phoenix Framework
- Phoenix LiveView
- SQLite3
- Tailwind CSS

## 프로젝트 구조

```
realtime_chat/
├── lib/
│   ├── realtime_chat/
│   │   ├── chat/
│   │   │   └── message.ex          # 메시지 스키마
│   │   ├── application.ex
│   │   └── repo.ex                 # 데이터베이스 설정
│   └── realtime_chat_web/
│       ├── live/
│       │   └── chat_live.ex        # 채팅 LiveView
│       ├── router.ex               # 라우팅 설정
│       └── ...
├── priv/
│   └── repo/
│       └── migrations/
│           └── *_create_messages.exs # 메시지 테이블 마이그레이션
└── ...
```

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
```bash
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
```bash
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

5. Message 스키마 생성 (lib/realtime_chat/chat/message.ex):
```elixir
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
```

6. LiveView 컴포넌트 생성 (lib/realtime_chat_web/live/chat_live.ex):
```elixir
defmodule RealtimeChatWeb.ChatLive do
  use RealtimeChatWeb, :live_view
  alias RealtimeChat.Chat.Message
  alias RealtimeChat.Repo

  def mount(_params, _session, socket) do
    username = "guest_" <> random_string(8)
    messages = Repo.all(Message)
    
    if connected?(socket) do
      Phoenix.PubSub.subscribe(RealtimeChat.PubSub, "chat")
    end

    {:ok, assign(socket, 
      messages: messages,
      username: username,
      message: ""
    )}
  end

  # 메시지 전송 및 브로드캐스트 처리 로직 추가
end
```

7. 라우터 설정 (lib/realtime_chat_web/router.ex):
```elixir
scope "/", RealtimeChatWeb do
  pipe_through :browser
  live "/", ChatLive
end
```

8. 프론트엔드 애셋 설치 및 서버 실행:
```bash
mix assets.setup
mix phx.server
```

이렇게 하면 기본적인 실시간 채팅 기능이 구현된 Phoenix 애플리케이션이 완성됩니다.

## 설치 및 실행 방법

1. 프로젝트 생성 및 의존성 설치:

```bash
# Phoenix 프로젝트 생성
mix phx.new realtime_chat --live

# 프로젝트 디렉토리로 이동
cd realtime_chat

# PostgreSQL을 SQLite로 변경하기 위해 mix.exs 의존성 수정
# {:postgrex, ">= 0.0.0"} 제거
# {:ecto_sqlite3, "~> 0.12"} 추가

# 의존성 설치
mix deps.get
```

2. 데이터베이스 설정:

```bash
# config/dev.exs와 config/test.exs 수정
# PostgreSQL 설정을 SQLite 설정으로 변경

# 데이터베이스 생성
mix ecto.create

# 메시지 테이블 마이그레이션 생성
mix ecto.gen.migration create_messages

# 마이그레이션 실행
mix ecto.migrate
```

3. 애셋 설치 및 서버 실행:

```bash
# 프론트엔드 애셋 설치
mix assets.setup

# 서버 실행
mix phx.server
```

## 주요 기능

1. 실시간 메시지 전송/수신
   - Phoenix PubSub를 사용한 실시간 메시지 브로드캐스팅
   - LiveView를 통한 즉각적인 UI 업데이트

2. 자동 사용자 이름 생성
   - 접속 시 무작위 게스트 이름 할당
   - 메시지와 함께 사용자 이름 표시

3. 메시지 영속성
   - SQLite 데이터베이스에 모든 메시지 저장
   - 페이지 로드 시 이전 메시지 표시

4. 반응형 UI
   - Tailwind CSS를 사용한 모던한 디자인
   - 모바일 친화적인 레이아웃

## 사용 방법

1. http://localhost:4000 접속
2. 자동으로 할당된 게스트 이름으로 채팅 참여
3. 메시지 입력 후 Send 버튼 클릭 또는 Enter 키 입력

## 개발 예정 기능

- [ ] 사용자 인증
- [ ] 다중 채팅방
- [ ] 메시지 히스토리 페이지네이션
- [ ] 사용자 온라인 상태 표시
- [ ] 파일 첨부 기능
