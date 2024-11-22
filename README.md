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

## 주요 기능

1. 실시간 메시지 전송
   - Phoenix PubSub을 활용한 실시간 메시지 브로드캐스팅
   - 사용자 이름과 메시지 내용 전송

2. 실시간 UI 업데이트
   - Phoenix LiveView를 통한 실시간 DOM 업데이트
   - 새 메시지 즉시 표시

3. 메시지 영속성
   - SQLite 데이터베이스에 모든 메시지 저장
   - 페이지 로드 시 이전 메시지 표시

4. 반응형 UI
   - Tailwind CSS를 활용한 모던한 디자인
   - 모바일 친화적인 레이아웃

## 설치 및 실행 방법

1. 저장소 클론:
```bash
git clone [repository-url]
cd realtime_chat
```

2. 의존성 설치:
```bash
mix deps.get
```

3. 데이터베이스 설정:
```bash
mix ecto.setup
```

4. 서버 실행:
```bash
mix phx.server
```

5. 브라우저에서 `http://localhost:4000` 접속

## 개발 문서

프로젝트의 개발 과정과 상세한 구현 내용은 [DEVELOPMENT.md](DEVELOPMENT.md)를 참조하세요.
