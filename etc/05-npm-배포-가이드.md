# 05. npm 배포 가이드

## 사전 준비 (완료된 항목)

| 항목 | 상태 |
|------|------|
| npmjs.com 계정 | ✅ |
| 2FA | ✅ |
| recovery codes 보관 | ✅ (`secret/` — git 제외) |
| 패키지 이름 가용성 | ✅ `personal-agent-harness` (404 = 미사용) |

## 비용

| 방식 | 비용 |
|------|------|
| **public** `personal-agent-harness` | **$0** |
| private npm | $7/월 (Pro) |

출처: [npm Products](https://www.npmjs.com/products)

## 중요: WSL vs Windows npm

일부 WSL 환경에서는 `npm`이 Linux npm이 아니라 **Windows Node/npm** 경로(`/mnt/c/Program Files/nodejs/npm`)를 가리킬 수 있다.

그 경우 Windows npm이 `\\wsl$\...` 경로의 `package.json`을 읽지 못해 `ENOENT`가 날 수 있다.

먼저 현재 npm 경로를 확인한다.

```bash
command -v npm
node --version
npm --version
```

`/usr/local/bin/npm`, `$HOME/.nvm/.../npm`처럼 Linux 경로면 그대로 진행한다. `/mnt/c/Program Files/nodejs/npm`처럼 Windows 경로면 WSL Ubuntu 터미널에서 Linux npm을 설치해 사용한다.

```bash
# WSL에 Node 없으면 — Node 24 LTS 권장 (2026-06 기준 Active LTS)
# apt의 npm은 Node 버전이 낮을 수 있어 nvm/fnm 사용을 권장
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
# 터미널 재시작 후
nvm install 24
node --version   # v24.x
npm --version
```

## publish 절차

```bash
cd ~/gw-personal/Personal-Agent-Harness

# 0) Linux npm 확인
command -v npm
node --version
npm --version

# 1) 로그인 확인
npm whoami
# 실패 시: npm login (OTP)

# 2) tarball 검증
npm pack
tar -tzf personal-agent-harness-0.3.1.tgz | head -20
# standards/, bin/pah 포함
# docs/internal/development.md 미포함 확인

# 3) 배포
npm publish
# 2FA OTP 입력

# 4) registry 확인
npm view personal-agent-harness version
# → 0.3.1
```

## 사용 (publish 후)

### 일회성 (권장)

```bash
cd /path/to/my-project
npx personal-agent-harness init .
npx personal-agent-harness@latest update .
npx personal-agent-harness verify .
npx personal-agent-harness status .
```

### 글로벌 설치

```bash
npm install -g personal-agent-harness
pah init /path/to/my-project
pah update /path/to/my-project
```

### 버전 고정

```bash
npx personal-agent-harness@0.3.1 init .
```

## 패키지에 포함되는 파일

`package.json` `files` 필드 기준:

- `bin/pah`, `bin/pah-entry`
- `bootstrap.sh`, `setup.sh`, `update.sh`
- `VERSION`, `config/`, `standards/`, `templates/`

## 보안

- `secret/npm_recovery_codes.txt` — **절대 커밋 금지**
- `.gitignore`에 `secret/` 등록됨
- npm publish token은 환경변수/CI secret으로만 사용

## 문제 해결

| 오류 | 원인 | 해결 |
|------|------|------|
| `ENEEDAUTH` | 미로그인 | `npm login` |
| `402 Payment Required` | scoped private | `--access public` 또는 unscoped 사용 |
| `ENOENT package.json` | Windows npm + WSL 경로 | WSL 터미널에서 publish |
| OTP 실패 | 시계 오차 / 만료 코드 | 인증 앱 새 코드 |

## 이후 버전 업데이트

1. `VERSION` + `package.json` version bump (동기화)
2. `bash tests/test_pah.sh`
3. `npm publish`
4. 사용자: `npx personal-agent-harness@latest update .`
