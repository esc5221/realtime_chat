# 🚀 Phoenix Realtime Chat

실시간 채팅 애플리케이션 - Phoenix LiveView / PubSub

## 배포 링크
https://kiwi-enormous-elephant.ngrok-free.app/

## 기능
- 실시간 메시지 전송 및 수신, 컴포넌트 위치 동기화
- 다중 사용자 지원
- WebSocket 기반 실시간 통신
- LiveView를 활용한 반응형 UI

## 기술 스택
- Elixir
- Phoenix Framework
- Phoenix LiveView - 실시간 UI 업데이트
- Phoenix PubSub - 실시간 메시지 브로드캐스팅
- Ecto - 데이터베이스 상호작용

## 프로젝트 구조
```
lib
├── realtime_chat
│   ├── application.ex
│   ├── chat
│   │   ├── message.ex          # 메시지 스키마
│   │   └── user_position.ex    # 사용자 위치 관리
│   ├── mailer.ex
│   └── repo.ex                 # 데이터베이스 설정
├── realtime_chat.ex
└── realtime_chat_web
    ├── components             # UI 컴포넌트
    ├── live
    │   └── chat_live.ex      # 채팅 LiveView
    ├── plugs
    │   └── username_plug.ex  # 사용자 이름 관리
    └── router.ex             # 라우팅 설정
```

## 실행 방법

1. 저장소 클론:
```bash
git clone [repository-url]
cd realtime_chat
```

2. 의존성 설치 및 실행:
```bash
mix deps.get
mix ecto.setup
mix phx.server
```
