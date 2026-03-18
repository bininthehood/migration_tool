# Shell 레이아웃 페이지 마이그레이션 패턴

## 판별 기준

`main.jsp`처럼 body가 비어있고 `<%@include file="header.jsp" %>` + `<script src="main.js">` 구조인 JSP.
콘텐츠 없이 헤더 + GNB + 탭 + 콘텐츠 슬롯만 있는 경우 → **반드시 이 패턴 적용**.
스텁(`<p>메인 화면입니다.</p>`) 절대 금지.

## Step 0 선행 필수: JSP 파일 체인 완전 추적

구현 전에 아래를 모두 읽고 기능 인벤토리를 완성한다:

```
main.jsp
 └─ <%@include file="common/header.jsp" %>
     └─ <script src="header.js">   → GNB 로드, 팝업, 비밀번호 변경, 세션 타이머
     └─ <script src="session_manager.js"> → 세션 타이머, 자동연장
 └─ <script src="main.js">        → 탭 시스템, POPUP_YN 분기
```

추출 항목:
- 모든 `gfn_ajax` / `$.ajax` 호출 + **파라미터 전부** (`siteCode`, `levelCode` 누락 금지)
- DOM 요소 목록 (`#popUserInfo`, `#userSesRunTime`, `#btnUserInfo` 등)
- UI 분기 로직 (`POPUP_YN === 'Y'` → `window.open` vs 탭 처리)

## App.js 라우트 구조

```
/main/*  → MainPage(shell) + <Outlet>
  /main/dashboard/monitoring   ← 일반 콘텐츠 (child route)
  /main/listen/listen          ← 일반 콘텐츠 (child route)

/dashboard/monitoring_bak     ← 팝업 (top-level route, /main 밖)
/approve/document/format_00   ← 팝업 (top-level route, /main 밖)
```

Child route: `path="category/name"` (앞에 `/` 없음)

## React 구현 템플릿

```jsx
import React, { useState, useEffect, useCallback, useRef } from 'react';
import { Outlet, useNavigate, useLocation } from 'react-router-dom';
import { checkSession } from '../auth/sessionGuard';
import { apiPostForm, getContextPath } from '../api/client';

function MainPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const [loading, setLoading] = useState(true);
  const [userId, setUserId] = useState('');
  const [userName, setUserName] = useState('');
  const [gnbMenus, setGnbMenus] = useState([]);
  const [activeSubMenu, setActiveSubMenu] = useState(null); // { parentCode, items[] }
  const [tabs, setTabs] = useState([]);
  const [headerFolded, setHeaderFolded] = useState(false);
  const subMenuTimerRef = useRef(null); // hover leave 200ms debounce

  useEffect(() => {
    checkSession().then(({ valid }) => {
      if (!valid) { navigate('/login', { replace: true }); return; }
      const uid   = sessionStorage.getItem('sessionUserId') || '';
      const uname = sessionStorage.getItem('userName')      || '';
      setUserId(uid);
      setUserName(uname);
      // GNB 메뉴 로드 — siteCode/levelCode 필수 (session-data.md 참조)
      apiPostForm('/selectList', {
        mapperName: 'menu.selectMainMenuListByPerm',
        userId:    uid,
        siteCode:  sessionStorage.getItem('siteCode')  || '',
        levelCode: sessionStorage.getItem('levelCode') || '',
      }).then(r => { if (r?.resultMap) setGnbMenus(r.resultMap); }).catch(() => {});
      setLoading(false);
    });
  }, [navigate]); // eslint-disable-line

  // 서브메뉴 hover 로드 (debounce)
  const loadSubMenu = useCallback(async (parentCode) => {
    if (activeSubMenu?.parentCode === parentCode) return;
    try {
      const result = await apiPostForm('/selectList', {
        mapperName: 'menu.selectSubMenuListByPerm',
        userId,
        parentCode,
        siteCode:  sessionStorage.getItem('siteCode')  || '',
        levelCode: sessionStorage.getItem('levelCode') || '',
      });
      setActiveSubMenu({ parentCode, items: result?.resultMap || [] });
    } catch (e) {
      setActiveSubMenu({ parentCode, items: [] });
    }
  }, [activeSubMenu, userId]);

  // MENU_URL → React route 변환: "/rays/dashboard/monitoring" → "dashboard/monitoring"
  const openTab = useCallback((code, name, menuUrl) => {
    const ctx = getContextPath();
    let route = menuUrl || '';
    if (ctx && route.startsWith(ctx)) route = route.slice(ctx.length);
    route = route.replace(/^\//, '');
    setTabs(prev => prev.find(t => t.code === code) ? prev : [...prev, { code, name, route }]);
    navigate(`/main/${route}`);
    setActiveSubMenu(null);
  }, [navigate]);

  const closeTab = useCallback((code, e) => {
    e.stopPropagation();
    setTabs(prev => {
      const idx = prev.findIndex(t => t.code === code);
      const next = prev.filter(t => t.code !== code);
      if (next.length && location.pathname === `/main/${prev[idx]?.route}`)
        navigate(`/main/${next[Math.max(0, idx - 1)].route}`);
      else if (!next.length) navigate('/main');
      return next;
    });
  }, [navigate, location.pathname]);

  if (loading) return <div className="page_wrap"><p>Loading...</p></div>;
  const ctx = getContextPath();

  return (
    <div>
      <div className={`headerWrap header_wrap${headerFolded ? ' no_show' : ''}`}>
        <div className="main_top">
          {/* 로고 */}
          <div id="topLogo" className="top_logo">
            <img src={`${ctx}/trunk/design/comm_header_logo.png`}
                 onError={e => { e.target.onerror = null; e.target.src = `${ctx}/resources/images/common/site/comm_logo_white.png`; }}
                 alt="logo" />
          </div>
          {/* 사용자 정보 + 로그아웃 */}
          <ul id="topTollkit" className="top_toolkit">
            <li id="btnUserInfo" className="top_btn_user" title={`${userName}(${userId})`}></li>
            <li id="btnLogout"  className="top_btn_logout" title="Logout"
                onClick={async () => {
                  try { await fetch(`${ctx}/user/v1/logout`, { method:'GET', credentials:'include', redirect:'manual' }); } catch(e) {}
                  sessionStorage.removeItem('sessionUserId');
                  navigate('/login', { replace: true });
                }} style={{ cursor: 'pointer' }}></li>
          </ul>
          {/* GNB */}
          <div className="top_gnb">
            <ul className="main_menu_wrap" id="topMenu">
              {gnbMenus.map(menu => (
                <li key={menu.MENU_P_CD} className="mainMenu main_menu"
                    onMouseEnter={() => { clearTimeout(subMenuTimerRef.current); loadSubMenu(menu.MENU_P_CD); }}
                    onMouseLeave={() => { subMenuTimerRef.current = setTimeout(() => setActiveSubMenu(null), 200); }}>
                  <div className="main_menu_item">
                    <div className="menu_icon">
                      <img src={`${ctx}/resources/images/package/menu/${menu.MENU_P_CD}.png`}
                           onError={e => { e.target.onerror = null; e.target.src = `${ctx}/resources/images/package/menu/0.png`; }}
                           alt={menu.MENU_NM} />
                    </div>
                    <p>{menu.MENU_NM}</p>
                  </div>
                  {activeSubMenu?.parentCode === menu.MENU_P_CD && activeSubMenu.items.length > 0 && (
                    <ul className="sub_menu_wrap"
                        onMouseEnter={() => clearTimeout(subMenuTimerRef.current)}
                        onMouseLeave={() => { subMenuTimerRef.current = setTimeout(() => setActiveSubMenu(null), 200); }}>
                      {activeSubMenu.items.map(sub => (
                        <li key={sub.MENU_CD} className="subMenu"
                            onClick={() => {
                              // POPUP_YN === 'Y': 새 창으로 열기 (탭 추가 안 함)
                              if (sub.POPUP_YN === 'Y') {
                                const w = sub.POPUP_WIDTH || 1366;
                                window.open(`${ctx}${sub.MENU_URL}`, sub.MENU_CD,
                                  `width=${w},height=700,scrollbars=yes,resizable=yes`);
                                setActiveSubMenu(null);
                              } else {
                                openTab(sub.MENU_CD, sub.MENU_NM, sub.MENU_URL);
                              }
                            }}
                            style={{ cursor: 'pointer' }}>
                          {sub.MENU_NM}
                        </li>
                      ))}
                    </ul>
                  )}
                </li>
              ))}
            </ul>
          </div>
        </div>
      </div>

      {/* 헤더 접기 버튼 */}
      <div className={`btnToggle btn_toggle${headerFolded ? ' fold' : ''}`}
           onClick={() => setHeaderFolded(f => !f)} />

      {/* 탭 + 콘텐츠 */}
      <div className="page_wrap">
        <ul id="pageTab" className="page_tab">
          {tabs.map(tab => (
            <li key={tab.code} id={tab.code}
                className={`tabObj${location.pathname === `/main/${tab.route}` ? ' active' : ''}`}
                onClick={() => navigate(`/main/${tab.route}`)}>
              <p className="title">{tab.name}</p>
              <i className="reload reloadTab" onClick={e => { e.stopPropagation(); navigate(0); }} />
              <i className="close closeTab"  onClick={e => closeTab(tab.code, e)} />
            </li>
          ))}
          {tabs.length > 0 && (
            <li id="closeTabAll" className="page_tab_close_all"
                onClick={() => { setTabs([]); navigate('/main'); }} />
          )}
        </ul>
        <div id="pageBody" className="page_body">
          <Outlet />
        </div>
      </div>
    </div>
  );
}
export default MainPage;
```

## 핵심 포인트

| 항목 | 내용 |
|------|------|
| `<Outlet />` | React Router 네스티드 라우트 슬롯 — `/main/*` child route가 여기 렌더링 |
| `subMenuTimerRef` | hover leave 200ms debounce — 없으면 서브메뉴가 즉시 사라짐 |
| `siteCode`/`levelCode` | sessionStorage에서 읽어 GNB/서브메뉴 API에 전달 필수 (session-data.md 참조) |
| `POPUP_YN === 'Y'` | `window.open` 처리 — 탭에 추가하지 않음 |
| MENU_URL 변환 | 레거시 URL에서 contextPath 제거 → React route 추출 |
| 탭 닫기 이동 | `Math.max(0, idx - 1)` 인덱스 보정 |
