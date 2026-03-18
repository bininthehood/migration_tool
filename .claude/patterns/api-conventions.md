# React API 패턴 — Spring MVC 연동

## Spring API 호출 형식

Spring `paramSet(request)`는 `application/x-www-form-urlencoded`를 읽음. JSON body 불가.

```js
// Spring 컨트롤러 엔드포인트 → 항상 apiPostForm 사용
await apiPostForm('/user/v1/policyCheck', { userId, userPwd, userLang: 'ko' });
await apiPostForm('/selectList', { mapperName: '...', userId });

// 진짜 REST 엔드포인트(JSON body 수신)에만 apiPost 사용
await apiPost('/api/v1/some-endpoint', { key: value });
```

## getContextPath() 구현

```js
export function getContextPath() {
  const path = window.location.pathname;
  const uiIdx = path.indexOf('/ui');
  if (uiIdx > 0) return path.substring(0, uiIdx);  // Tomcat: /rays/ui/login → /rays
  return process.env.REACT_APP_CONTEXT_PATH || '';  // Dev :3000 fallback
}
```

`.env.development`:
```
REACT_APP_CONTEXT_PATH=/rays
```

## Dev Proxy (setupProxy.js)

CRA `"proxy"` 필드는 경로 재작성 불가 — `src/setupProxy.js` 사용:

```js
const { createProxyMiddleware } = require('http-proxy-middleware');
module.exports = function (app) {
  app.use('/{contextPath}', createProxyMiddleware({
    target: 'http://localhost:8080',
    changeOrigin: true,
  }));
};
```

`package.json`에 `"proxy"` 필드가 있으면 **반드시 제거** (setupProxy.js와 충돌).

## CSS / Static Assets

CRA webpack은 `src/` 안 CSS의 `url(../../images/...)` 경로를 모듈로 해석 → `Module not found` 에러 발생.

**해결:**
- 레거시 CSS → `public/resources/css/` 복사
- 레거시 이미지 → `public/resources/images/` 복사
- `public/index.html`에서 `<link href="%PUBLIC_URL%/resources/css/...">` 로드
- `App.js`에 CSS import 금지 — `public/index.html`에서만 로드

```bash
# Phase 2 CSS/이미지 복사 스크립트
WEBAPP="{project_root}/src/main/webapp/resources"
PUBLIC="{project_root}/src/main/frontend/public/resources"
find "$WEBAPP/css" -name "*.css" | while read src; do
  rel="${src#$WEBAPP/}"; dst="$PUBLIC/$rel"
  mkdir -p "$(dirname "$dst")" && cp "$src" "$dst"
done
cp -r "$WEBAPP/images" "$PUBLIC/images"
```

**주의**: 레거시 CSS 복사 후 `datagrid.css`가 **없으면 생성**해야 합니다 (레거시에 없는 신규 파일):

```bash
DATAGRID_CSS="$PUBLIC/css/common/datagrid.css"
if [ ! -f "$DATAGRID_CSS" ]; then
  # DataGrid 컴포넌트(TanStack Table v8) 전용 스타일 — DataTables CSS 대체
  # 참조: src/main/frontend/public/resources/css/common/datagrid.css (ArcFlow_Webv1.2 기준)
  echo "⚠ datagrid.css 없음 — jquery-to-react 스킬 Step 3 참조하여 생성 필요"
fi
```

`public/index.html`에 반드시 포함되어야 할 공통 CSS 링크 순서:
```html
<link rel="stylesheet" href="%PUBLIC_URL%/resources/css/common/normalize.css" />
<link rel="stylesheet" href="%PUBLIC_URL%/resources/css/common/common.css" />
<link rel="stylesheet" href="%PUBLIC_URL%/resources/css/common/common_ui.css" />
<link rel="stylesheet" href="%PUBLIC_URL%/resources/css/common/header.css" />
<!-- DataGrid 컴포넌트 (DataTables 대체 — jquery-to-react 스킬로 생성) -->
<link rel="stylesheet" href="%PUBLIC_URL%/resources/css/common/datagrid.css" />
```
