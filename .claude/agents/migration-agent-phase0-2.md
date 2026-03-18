# Migration Agent — Phase 0 / 1 / 2 구현 상세

---

## PHASE 0 — CRA Entry Points

**`public/index.html`**:
```html
<!DOCTYPE html>
<html lang="ko">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>ArcFlow</title>
  </head>
  <body>
    <noscript>JavaScript가 필요합니다.</noscript>
    <div id="root"></div>
  </body>
</html>
```

**`src/index.js`**:
```js
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';

function getBasename() {
  const path = window.location.pathname;
  const uiIdx = path.indexOf('/ui');
  return uiIdx !== -1 ? path.substring(0, uiIdx) + '/ui' : '/ui';
}

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <App basename={getBasename()} />
  </React.StrictMode>
);
```

---

## PHASE 1 — Project Analysis (JSP Inventory → TASK_BOARD 자동 생성)

"Identify legacy JSP UI structure" 태스크 완료 후:

1. Glob: `{project_root}/src/main/webapp/WEB-INF/jsp/**/*.jsp` (또는 `/views/**/*.jsp`)
2. 각 JSP에서 추출:
   - JSP 경로 (relative to `WEB-INF/jsp/`)
   - React 컴포넌트명 (PascalCase + `Page.jsx`)
   - React 라우트 (`/ui/{category}/{name}`)
3. **TASK_BOARD.md Phase 3 섹션**을 자동 생성 태스크로 교체:

```
[ ] `{jsp_relative_path}` → `src/pages/{category}/{ComponentName}.jsx` (`/ui/{route}`)
```

**규칙:**
- 파일 1개 = `[ ]` 1줄
- 팝업/다운로드 JSP → `(팝업 — 별도 처리)` suffix
- `inc_*.jsp`, `common*.jsp`, `/common/` 하위 → 제외 (fragment, 화면 아님)
- 정렬: login → main → dashboard → listen → logs → manage → recorder → system → approve → view
- 완료 후 `phase3_screens_total` 업데이트 (TASK_BOARD + LATEST_STATE.md)

---

## PHASE 2 — React Foundations

이미 존재하는 파일은 덮어쓰지 않음.

### Dev Proxy (`src/setupProxy.js`)

CRA `"proxy"` 필드는 경로 재작성 불가 → `setupProxy.js` 사용. `package.json`에 `"proxy"` 있으면 제거.

```js
const { createProxyMiddleware } = require('http-proxy-middleware');
module.exports = function (app) {
  app.use('/{contextPath}', createProxyMiddleware({
    target: 'http://localhost:8080',
    changeOrigin: true,
  }));
};
```

`.env.development`:
```
REACT_APP_CONTEXT_PATH=/{contextPath}
```

### CSS 이관 (`public/resources/`)

webpack이 `src/` CSS의 `url(../../images/...)` 경로를 모듈로 해석 → Module not found 에러.
CSS/이미지는 `public/`에 복사하고 `public/index.html`에서 `<link>`로 로드.

```bash
WEBAPP="{project_root}/src/main/webapp/resources"
PUBLIC="{project_root}/src/main/frontend/public/resources"
find "$WEBAPP/css" -name "*.css" | while read src; do
  rel="${src#$WEBAPP/}"; dst="$PUBLIC/$rel"
  mkdir -p "$(dirname "$dst")" && cp "$src" "$dst"
done
cp -r "$WEBAPP/images" "$PUBLIC/images"
```

`public/index.html` `<head>`에 추가:
```html
<link rel="stylesheet" href="%PUBLIC_URL%/resources/css/common/normalize.css" />
<link rel="stylesheet" href="%PUBLIC_URL%/resources/css/common/common.css" />
```

### `src/api/client.js`

```js
export function getContextPath() {
  const path = window.location.pathname;
  const uiIdx = path.indexOf('/ui');
  if (uiIdx > 0) return path.substring(0, uiIdx);
  return process.env.REACT_APP_CONTEXT_PATH || '';
}

export async function apiPost(endpoint, data) {
  const res = await fetch(`${getContextPath()}${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    credentials: 'include',
    body: JSON.stringify(data),
  });
  if (!res.ok) throw new Error(`HTTP ${res.status}: ${endpoint}`);
  return res.json();
}

// Spring paramSet 호환 — 대부분의 Spring 컨트롤러에 사용
export async function apiPostForm(endpoint, data) {
  const res = await fetch(`${getContextPath()}${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    credentials: 'include',
    body: new URLSearchParams(data).toString(),
  });
  if (!res.ok) throw new Error(`HTTP ${res.status}: ${endpoint}`);
  return res.json();
}

export async function apiGet(endpoint) {
  const res = await fetch(`${getContextPath()}${endpoint}`, {
    method: 'GET',
    credentials: 'include',
  });
  if (!res.ok) throw new Error(`HTTP ${res.status}: ${endpoint}`);
  return res.json();
}
```

### `src/auth/sessionGuard.js`

> ⚠ 작성 전에 실제 Spring 컨트롤러 확인 필수. `sessionInfo`는 프로젝트마다 다름.
> 이 프로젝트: `/user/v1/sessionChecker` (resultCode=0 = 유효)

```js
import { apiPostForm } from '../api/client';

export async function checkSession() {
  try {
    const result = await apiPostForm('/user/v1/sessionChecker', {});
    if (result.resultCode !== 0) return { valid: false };
    return { valid: true };
  } catch {
    return { valid: false };
  }
}
```

### `src/App.js` 라우트 구조 (이 프로젝트 확정)

```
/login, /index           → 공개 (MainPage 셸 없음)
/main/*                  → 인증 필요, MainPage 셸 + <Outlet>
  /main/dashboard/monitoring
  /main/listen/listen    ... 등 모든 콘텐츠 페이지
/dashboard/monitoring_bak → 팝업 (독립 top-level route)
/approve/document/*       → 팝업
/view/download*           → 팝업
```

**Route 추가 규칙:**
- 일반 콘텐츠 → `<Route path="/main">` **내부** child (`path="category/name"`, 앞에 `/` 없음)
- 팝업/독립 → `/main` **밖** 최상위 Route
- App.js 전체 재작성 금지 — `<Route>` 라인 추가만

### LoginPage — siteCode/levelCode 세션 데이터 저장

사내 레거시 공통 문제: 로그인 후 `selectList` 권한 API가 `levelCode` 파라미터를 필수로 요구.
LoginPage에서 로그인 직후 사용자 상세 정보를 조회해 sessionStorage에 저장해야 함.
자세한 내용: `.claude/patterns/session-data.md`

```js
// 로그인 성공(resultCode=0) 직후
sessionStorage.setItem('sessionUserId', userId);
try {
  const userInfo = await apiPostForm('/selectList', {
    mapperName: 'user.selectUserList',  // 프로젝트별 매퍼명 확인
    userId,
  });
  if (userInfo?.resultMap?.[0]) {
    const u = userInfo.resultMap[0];
    sessionStorage.setItem('siteCode',  u.SITE_CD || '');
    sessionStorage.setItem('levelCode', u.LV_CD   || '');
    sessionStorage.setItem('userName',  u.USR_NM  || '');
    sessionStorage.setItem('groupCode', u.GRP_CD  || '');
    sessionStorage.setItem('groupName', u.GRP_NM  || '');
  }
} catch (e) {}
navigate('/main', { replace: true });
```
