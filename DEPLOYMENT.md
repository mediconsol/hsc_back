# Backend Deployment (Railway + Docker)

## 개요

이 문서는 Backend(API) 단일 레포를 Railway에 Dockerfile 기반으로 배포하는 절차를 설명합니다.

## 사전 준비

- GitHub 저장소 연결
- Railway 계정 및 프로젝트
- PostgreSQL 서비스 추가 (Railway Managed PostgreSQL)

## 환경 변수 (Railway → Variables)

```bash
RAILS_ENV=production
DATABASE_URL=${{Postgres.DATABASE_URL}}
RAILS_MASTER_KEY=<config/master.key 내용>
FRONTEND_URL=https://<frontend-domain>
RAILS_MAX_THREADS=10
```

## 서비스 설정

- Root Directory: `/`
- Build: Dockerfile 자동 인식
- Start: Dockerfile CMD (ENTRYPOINT에서 DB 준비 실행)

## 헬스체크

- `https://<backend-domain>/up` → 200 OK
- `https://<backend-domain>/health/detailed` → 상태 JSON

## 문제 해결

- DB 연결 실패: `DATABASE_URL` 확인, Postgres 서비스 상태 확인
- CORS 오류: `FRONTEND_URL` 도메인 재확인
- 마이그레이션 실패: Railway Logs에서 `db:migrate` 실패 원인 확인
