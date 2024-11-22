# Phoenix Realtime Chat - Learning Guide

이 문서는 Phoenix Realtime Chat 프로젝트를 통해 Phoenix와 Elixir의 주요 기능들을 학습하는 가이드입니다.

## 목차

1. [Phoenix LiveView](#phoenix-liveview)
2. [Phoenix PubSub](#phoenix-pubsub)
3. [Ecto와 데이터베이스](#ecto와-데이터베이스)
4. [라우팅과 엔드포인트](#라우팅과-엔드포인트)

## Phoenix LiveView

Phoenix LiveView는 실시간, 서버 렌더링 사용자 인터페이스를 구현하는 강력한 도구입니다. 이 프로젝트에서는 채팅 인터페이스를 구현하는데 사용되었습니다.

### LiveView의 기본 구조

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
end
```

### 주요 학습 포인트

1. **mount/3 함수**
   - LiveView 컴포넌트가 처음 로드될 때 호출
   - 초기 상태 설정 및 구독 설정
   - socket assigns를 통한 상태 관리

2. **실시간 이벤트 처리**
   ```elixir
   def handle_event("send_message", %{"message" => message}, socket) do
     message_params = %{
       content: message,
       username: socket.assigns.username
     }
     
     {:ok, message} = create_message(message_params)
     broadcast_message(message)
     
     {:noreply, assign(socket, message: "")}
   end
   ```

3. **상태 업데이트와 렌더링**
   ```elixir
   def handle_info({:new_message, message}, socket) do
     messages = [message | socket.assigns.messages]
     {:noreply, assign(socket, messages: messages)}
   end
   ```

## Phoenix PubSub

PubSub는 실시간 메시지 브로드캐스팅을 구현하는 핵심 기능입니다.

### 구독 설정

```elixir
# application.ex
def start(_type, _args) do
  children = [
    {Phoenix.PubSub, name: RealtimeChat.PubSub},
    # ...
  ]
  opts = [strategy: :one_for_one, name: RealtimeChat.Supervisor]
  Supervisor.start_link(children, opts)
end
```

### 메시지 브로드캐스팅

```elixir
defp broadcast_message(message) do
  Phoenix.PubSub.broadcast(
    RealtimeChat.PubSub,
    "chat",
    {:new_message, message}
  )
end
```

### 주요 학습 포인트

1. **PubSub 설정**
   - 애플리케이션 시작 시 PubSub 서버 설정
   - 토픽 기반 메시지 라우팅

2. **실시간 메시지 전파**
   - 브로드캐스트를 통한 메시지 전파
   - 구독자들에게 자동 업데이트

## Ecto와 데이터베이스

Ecto는 데이터베이스 작업을 위한 도구 모음입니다.

### 스키마 정의

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

### 마이그레이션

```elixir
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
```

### 주요 학습 포인트

1. **스키마 설계**
   - Ecto.Schema를 통한 데이터 모델링
   - 타입 지정과 관계 설정

2. **Changeset**
   - 데이터 변경 검증
   - 필드 캐스팅과 유효성 검사

3. **마이그레이션**
   - 데이터베이스 스키마 버전 관리
   - 테이블 생성과 수정

## 라우팅과 엔드포인트

Phoenix의 라우팅 시스템은 웹 요청을 적절한 컨트롤러나 LiveView로 전달합니다.

### 라우터 설정

```elixir
defmodule RealtimeChatWeb.Router do
  use RealtimeChatWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {RealtimeChatWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", RealtimeChatWeb do
    pipe_through :browser
    live "/", ChatLive
  end
end
```

### 주요 학습 포인트

1. **라우터 파이프라인**
   - 요청 처리 파이프라인 구성
   - 미들웨어 플러그 설정

2. **LiveView 라우팅**
   - LiveView 엔드포인트 설정
   - 경로와 컴포넌트 매핑

## 추가 학습 자료

- [Phoenix 공식 문서](https://hexdocs.pm/phoenix/overview.html)
- [Phoenix LiveView 문서](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html)
- [Ecto 문서](https://hexdocs.pm/ecto/Ecto.html)
- [Phoenix PubSub 문서](https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html)
