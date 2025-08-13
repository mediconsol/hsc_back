# HSC1 Backend (Rails API)

병원 관리 시스템 백엔드(API) 애플리케이션입니다. 프런트엔드와 별도 레포로 분리하여 Railway에 독립 배포하는 구성을 전제로 합니다.

## 요구사항

- Ruby 3.x
- PostgreSQL 13+
- Bundler

## 환경 변수

- `RAILS_ENV`: production/development/test
- `DATABASE_URL`: PostgreSQL 접속 URL (예: `postgresql://user:pass@host:5432/dbname`)
- `RAILS_MASTER_KEY`: `config/master.key` 내용 (필수)
- `FRONTEND_URL`: 허용할 프런트엔드 도메인(프로덕션 CORS용)
- 선택: `RAILS_MAX_THREADS`

## 로컬 개발

```bash
bundle install
bin/rails db:prepare
bin/rails s -p 7001
# http://localhost:7001/up
```

## 헬스체크

- `/up` → 200 OK
- `/health/detailed` → DB 등 상태 JSON

## 테스트

```bash
bundle exec rails test
```

## 배포

Railway(Dockerfile 기반) 배포 가이드는 `DEPLOYMENT.md`를 참고하세요.
