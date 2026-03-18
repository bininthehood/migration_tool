# Session 패턴 — 레거시 Spring MVC 공통

## Session Guard 규칙 (전체 화면 적용)

- **작성 전에 실제 Spring 컨트롤러를 확인할 것.** `sessionInfo` 엔드포인트는 프로젝트마다 다름.
- 이 프로젝트(ArcFlow_Webv1.2): `sessionChecker` (`resultCode=0`) = 세션 확인 엔드포인트
- `sessionInfo`, `sessionAlive`는 모든 프로젝트에 존재하지 않음 — 컨트롤러에서 직접 확인
- sessionStorage 저장 위치: 로그인 시점(LoginPage)에서 한 번 — 이후 각 화면에서 재조회 금지
- `src/main/frontend/src/routing/routeNormalizer.js`로 redirect/URL 정규화 집중

## Session Contract API Chain (이 프로젝트)

```
POST /user/v1/policyCheck    → resultCode=0  (로그인 + 서버 세션 생성)
POST /user/v1/sessionChecker → resultCode=0  (세션 유효성 확인)
GET  /user/v1/logout         → ModelAndView redirect (JSON 아님 — fetch redirect:'manual' 필수)
```

## siteCode / levelCode 문제 (사내 레거시 공통)

### 문제 원인

JSP는 서버 HTTP 세션을 EL(`${siteCode}`)로 직접 읽어 JS 전역 변수에 주입:
```jsp
var gv_sessionData = {
  siteCode  : "${siteCode}",   // 서버 세션 → JS 자동 전달
  levelCode : "${levelCode}",  // 서버 세션 → JS 자동 전달
  userId    : "${userId}",
  userName  : "${userName}",
}
```

MyBatis 권한 쿼리는 이 값들을 POST body 파라미터로 필수 요구:
```sql
WHERE A.SITE_CD = #{siteCode}  -- POST body에서 읽음
  AND B.LV_CD  = #{levelCode}  -- POST body에서 읽음 (서버 자동 주입 안 됨)
```

`/selectList` 컨트롤러 자동 주입 키 vs SQL 파라미터명 불일치:

| 서버 자동 주입 키 | SQL `#{}` 파라미터 | 클라이언트 전송 필요 여부 |
|---|---|---|
| `siteCode` (auto) | `#{siteCode}` | 선택 (덮어써도 무관) |
| `execLevelCode` (auto) | `#{levelCode}` | **필수 — 이름 불일치로 자동 주입 안 됨** |
| `execId` (auto) | `#{execId}` | 불필요 |

→ React가 `levelCode` 없이 호출하면 권한 쿼리가 빈 결과(`resultMap: []`) 반환

### 진단

GNB 메뉴 API를 `userId`만으로 호출 → `resultMap: []` 반환 → 이 문제
확인: 매퍼 XML `#{levelCode}` 검색 → `CommonController.selectList()` 자동 주입 키 목록 확인

### 해결 패턴 (백엔드 수정 없이)

**Step 1 — LoginPage.jsx: 로그인 직후 사용자 상세 정보 조회 후 sessionStorage 저장**

```js
sessionStorage.setItem('sessionUserId', userId);

// 권한 API용 데이터 즉시 조회 (매퍼명은 프로젝트별 확인)
// 찾는 법: Grep mapper/**/*.xml → id 패턴이 "User" 포함, userId 필터 쿼리
try {
  const userInfo = await apiPostForm('/selectList', {
    mapperName: 'user.selectUserList',  // 이 프로젝트 확인 완료
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
} catch (e) { /* 무시 — 세션은 유효 */ }

navigate('/main', { replace: true });
```

**Step 2 — 권한 기반 API 호출 시 sessionStorage에서 읽어 전달**

```js
apiPostForm('/selectList', {
  mapperName: 'menu.selectMainMenuListByPerm',
  userId:    sessionStorage.getItem('sessionUserId') || '',
  siteCode:  sessionStorage.getItem('siteCode')      || '',
  levelCode: sessionStorage.getItem('levelCode')     || '',
});
```

### 적용 대상 API 유형

- GNB 상단 메뉴 / 서브메뉴 조회
- 화면별 권한 조회 (`writeYn`, `modifyYn`, `downloadYn`)
- 사이트 코드 기반 데이터 필터링 쿼리

## Logout — ModelAndView Redirect 처리

```js
await fetch(`${getContextPath()}/user/v1/logout`, {
  method: 'GET',
  credentials: 'include',
  redirect: 'manual',  // redirect 따라가지 않음, .json() 호출 금지
});
sessionStorage.removeItem('sessionUserId');
navigate('/login', { replace: true });
```
