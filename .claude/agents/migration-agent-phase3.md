# Migration Agent — Phase 3 구현 상세

---

## PHASE 3 — Screen Migration (JSP → React)

### Step 0 — 기능 인벤토리 (구현 전 필수, 건너뜀 금지)

**JSP 파일 체인을 끝까지 추적하고 기능 목록을 완성한 뒤 코드를 작성한다.**

#### 0-1. JSP 읽기 + 포함 파일 추출

```
<%@include file="..." %>   → 포함 JSP 목록
<script src="...">         → 연결 JS 파일 경로
${변수명}                  → 서버사이드 변수
```
각 포함 JSP를 재귀적으로 읽어 동일하게 추출.

#### 0-2. 연결 JS 파일 전체 읽기

각 JS 파일에서 추출:
- **모든 API 호출**: `gfn_ajax`, `$.ajax`, `fetch`의 URL + **파라미터 전부** (`siteCode`, `levelCode` 등 하나도 빠뜨리지 않음)
- **UI 분기 로직**: `POPUP_YN`, `TARGET_TYPE` 등 조건 분기
- **DOM 요소**: id/class (`#popUserInfo`, `#userSesRunTime` 등)
- **이벤트 핸들러**: 버튼/hover/submit 동작

#### 0-3. 구현 전 체크리스트 작성

```
[ ] GNB 메뉴 로드 (파라미터: mapperName, siteCode, levelCode, userId)
[ ] 서브메뉴 hover + POPUP_YN 분기
[ ] 세션 타이머 (#userSesRunTime)
[ ] 사용자 정보 팝업 (#popUserInfo) + 비밀번호 변경
[ ] 탭 최대 개수 제한 (P_TAB_MAX 조회)
... JS에서 발견한 모든 기능
```
이 목록을 모두 구현한 뒤에만 `[x]` 표시.

---

### Step 1 — JSP 화면 유형 구분

구현 전 반드시 판별:

| 유형 | 특징 | 구현 패턴 |
|------|------|---------|
| **콘텐츠 페이지** | 단일 기능 (목록/폼/상세) | 패턴 A |
| **팝업 페이지** | 독립 창으로 열림 | 패턴 A + App.js top-level Route |
| **셸 레이아웃** | body 비어있음, header.jsp + main.js 포함 | 패턴 B (`.claude/patterns/shell-layout.md`) |

---

### 패턴 A — 일반 콘텐츠 페이지

`src/pages/{category}/{ComponentName}.jsx`:

```jsx
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { apiPostForm, getContextPath } from '../../api/client';
import { checkSession } from '../../auth/sessionGuard';

/**
 * {화면명} 컴포넌트
 * JSP 원본: src/main/webapp/WEB-INF/jsp/{path}.jsp
 */
function ComponentName() {
  const navigate = useNavigate();
  useEffect(() => {
    checkSession().then(({ valid }) => {
      if (!valid) navigate('/login', { replace: true });
    });
  }, [navigate]);

  return <div>{/* 화면 내용 */}</div>;
}
export default ComponentName;
```

---

### 패턴 B — 셸 레이아웃 페이지

전체 구현 템플릿: `.claude/patterns/shell-layout.md` 참조

핵심 포인트:
- `<Outlet />` — React Router child route 슬롯
- `siteCode`/`levelCode` sessionStorage에서 읽어 GNB API 전달 필수
- `POPUP_YN === 'Y'` → `window.open` (탭 추가 안 함)
- `subMenuTimerRef` — hover leave 200ms debounce
- MENU_URL에서 contextPath 제거 → React route 추출

---

### App.js Route 추가 규칙

- 일반 콘텐츠 → `<Route path="/main">` **내부** child
  ```jsx
  <Route path="category/name" element={<ComponentPage />} />
  ```
  (path 앞에 `/` 없음)
- 팝업/독립 → `/main` **밖** top-level Route
  ```jsx
  <Route path="/category/name" element={<PopupPage />} />
  ```
- App.js 전체 재작성 금지 — `<Route>` 라인 + import 추가만 허용

---

<!-- meta-agent added: 2026-03-18 -->
## Phase 3 실행 결과 — 발견된 공통 패턴 라이브러리

이 항목들은 ArcFlow_Webv1.2 Phase 3 마이그레이션(30개 화면 완료, 2026-03-18) 결과로 발견된 재사용 가능한 패턴입니다.

### Step 0 필수 확인 항목 (추가)

일반 콘텐츠 페이지를 마이그레이션할 때 **반드시** 다음을 Step 0에서 확인하세요:

#### 리스트 화면 구성 요소
- `<table><thead>`: 헤더 행이 항상 렌더링되는가? (데이터 없을 때도)
  → **필수 구현**: colSpan empty-state 패턴으로 thead 항상 유지
- `<thead><tr><th>`: 컬럼 개수와 헤더명
- 페이지네이션: JSP에서 offset/limit 계산 로직 있는가?
  → **필수 구현**: React에서 page state + offset/limit 계산

#### 좌측 패널 / 네비게이션
- `<div id="...Tree">` 같은 트리 컨테이너 있는가?
  - 관련 JS: `var tree_data = [...]` 같은 재귀 구조
  → **필수 구현**: lazy-load tree + click filter
- `<ul class="nav">` 같은 탭/아코디언 있는가?
  → **필수 구현**: active tab state + fade transition

#### 특수 입력 요소
- `<input type="text" class="datepicker">`: jQuery datepicker 사용?
  → **권장 구현**: HTML5 `<input type="date">` 대체
- `<audio>`, `<video>`, `<canvas>`: 미디어 관련 요소?
  → **필수**: 모든 태그와 커스텀 listener 체인 추적

#### 전역 변수 / 초기화 코드
```javascript
var gv_sessionData = { siteCode: "...", levelCode: "...", ... }
var gv_param = { mapperName: "...", ... }
```
- 서버에서 주입되는 모든 변수 목록화
- sessionStorage로 대체 필요 여부 판단

### 공통 구현 패턴

#### 패턴: Empty Table with Static Header (19개 화면)
```jsx
<table>
  <thead>
    <tr><th>컬럼1</th><th>컬럼2</th>...</tr>
  </thead>
  <tbody>
    {items.length > 0 ? (
      items.map(item => <tr>...</tr>)
    ) : (
      <tr><td colSpan="3">데이터 없음</td></tr>
    )}
  </tbody>
</table>
```
**적용 화면**: ListenPage, LogAccessPage, LogAccountPage, LogSystemPage, LogWebPage, UserPage, GroupPage, PermPage, ServerPage, SenderPage, ConfigPage, ConfigSettingPage, MenuPage, CodePage, ApprovePage, ApproveRequestPage, InterfaceInfoPage, TableManagerPage, ListenTargetPage

#### 패턴: Pagination with Range Display (10개 화면)
```jsx
<div className="pagination">
  <button onClick={() => setPage(1)}>처음</button>
  <button onClick={() => setPage(page-1)} disabled={page===1}>이전</button>
  {/* 페이지 번호 1~5 */}
  <button onClick={() => setPage(page+1)} disabled={page===maxPage}>다음</button>
  <button onClick={() => setPage(maxPage)}>마지막</button>
  <span>총 {totalCount}건 ({pageSize}건/페이지)</span>
</div>
```
**적용 화면**: ListenPage, LogAccessPage, LogAccountPage, LogSystemPage, LogWebPage, UserPage, GroupPage, ServerPage, ApprovePage, ApproveRequestPage

#### 패턴: Lazy-Load Tree Panel (2개 화면)

**UserPage** — 조직도 트리:
```jsx
// 트리 데이터 구조
{
  groupCode: "GRP001",
  groupName: "IT부서",
  hasChildren: true,
  children: []  // lazy-load로 클릭 시에만 로드
}
// 클릭 이벤트: 그룹 선택 → 해당 사용자 필터링
```

**ApprovePage** — 결재 상태 트리:
```jsx
[
  { status: "WAITING", count: 15 },      // 대기
  { status: "SCHEDULED", count: 8 },     // 예정
  { status: "IN_PROGRESS", count: 3 },   // 진행 중
  { status: "COMPLETED", count: 42 }     // 종료
]
// 클릭 → 해당 상태의 문서만 로드
```

#### 패턴: DatePickerInput (9개 화면)
JSP의 jQuery datepicker 대신 `DatePickerInput` 컴포넌트 사용 (react-datepicker v9 래퍼):
```jsx
import DatePickerInput from '../../components/DatePickerInput';

function todayStr() { return new Date().toISOString().slice(0, 10); }
function daysAgoStr(n) { const d = new Date(); d.setDate(d.getDate() - n); return d.toISOString().slice(0, 10); }

const [startDate, setStartDate] = useState(() => daysAgoStr(7));
const [endDate, setEndDate]     = useState(() => todayStr());

<DatePickerInput id="startDate" value={startDate} onChange={setStartDate} maxDate={new Date()} />
<DatePickerInput id="endDate"   value={endDate}   onChange={setEndDate}
  minDate={new Date(startDate)} maxDate={new Date()} />
```
- `showYearDropdown` / `showMonthDropdown` / `dropdownMode="select"` — 넓은 범위 날짜 선택 가능
- `appliedSearch` 초기값 반드시 설정 (null이면 마운트 시 조회 안 됨)
- **적용 화면**: ListenPage, LogAccessPage, LogAccountPage, LogSystemPage, LogWebPage, ApprovePage, ApproveRequestPage, MonitoringPage, ListenTargetPage

#### 패턴: Audio Player (ListenPage)
```jsx
<audio ref={audioRef} src={audioUrl} />
<button onClick={() => audioRef.current.play()}>재생</button>
<button onClick={() => audioRef.current.pause()}>정지</button>
<input type="range" min="0.5" max="2" step="0.5" onChange={e => {
  audioRef.current.playbackRate = parseFloat(e.target.value);
}} />
```

#### 패턴: Server Status Cards (MonitoringPage)
```jsx
// API: arcFlow.selectArcFlowDeviceList
// 응답: [{ deviceId, deviceName, status }]
{items.map(item => (
  <div className={`card status-${item.status}`}>
    {/* status-online (green), status-warning (yellow), status-offline (red) */}
  </div>
))}
```

### 설계 결함 — 사후 문제 분석

#### Issue 1: migration-screen-map.json reactRoute 경로 오류
- **Root Cause**: App.js를 nested route로 설계했으나 screen map의 reactRoute는 flat 경로
- **Symptom**: 잘못된 URL → 404 → /login 리다이렉트 → 세션 재확인 → /main empty Outlet 반복
- **Resolution**: reactRoute에 `main/` prefix 추가 (`dashboard/monitoring` → `main/dashboard/monitoring`)
- **Test**: deep-link 모든 화면 접근 가능 확인

#### Issue 2: Step 0 누락 — 좌측 패널
- **What Happened**: UserPage/ApprovePage 트리 초기화 코드가 먼저 발견되지 않음
- **Why**: JSP 본문이 비어있고 JavaScript로 동적 생성 → dom 요소 추적 단계에서 누락 가능
- **Prevention**: Step 0-2 "연결 JS 파일 읽기"에서 `var tree_data`, `#orgChart` 같은 키워드 grep 필수

<!-- Phase 3.5 added: 2026-03-18 -->
## Phase 3.5 — jQuery DataTables → TanStack Table v8 (DataGrid)

모든 목록 화면의 DataTables를 TanStack Table v8 기반 `DataGrid` 컴포넌트로 교체 완료.

### 전제 조건

```bash
# 패키지 설치 (이미 완료)
npm install @tanstack/react-table xlsx
```

### 공용 컴포넌트

`src/main/frontend/src/components/DataGrid.jsx` — 서버사이드 그리드 컴포넌트

Props:
- `data` — 서버 응답 rows 배열
- `columns` — TanStack columnDef 배열
- `total` — 전체 건수 (`recordsTotal` or `totalCount`)
- `pageIndex` (0-based), `pageSize`, `pageSizeOptions`
- `sorting` — `[{ id, desc }]`
- `loading` — 로딩 스피너
- `onPagination({ pageIndex, pageSize })`, `onSorting(updater)`
- `onExcelExport?` — 엑셀 다운로드 버튼
- `onRowDblClick?(row.original)` — 행 더블클릭
- `scrollX` (default: true)

### 패턴: DataGrid 서버사이드 페이지

> ⚠ `/selectGridData`는 DataTables 1.9 전용 파라미터(`iDisplayStart`, `iDisplayLength`, `sSortCol`)를 사용한다.
> `start`/`length`/`order[0][*]`로 직접 호출하면 서버 페이징 분기가 트리거되지 않아 데이터가 표출되지 않는다.
> **반드시 `fetchGridData` 어댑터를 사용할 것** (`src/api/gridDataFetch.js`).

```jsx
import DataGrid from '../../components/DataGrid';
import * as XLSX from 'xlsx';
import { fetchGridData } from '../../api/gridDataFetch';

function SomePage() {
  const [data, setData]           = useState([]);
  const [total, setTotal]         = useState(0);
  const [loading, setLoading]     = useState(false);
  const [pageIndex, setPageIndex] = useState(0);
  const [pageSize, setPageSize]   = useState(30);
  const [sorting, setSorting]     = useState([{ id: 'DEFAULT_COL', desc: true }]);
  // appliedSearch: null이면 마운트 시 fetchData 미실행 — 날짜 초기값이 있으면 반드시 초기화
  const [appliedSearch, setAppliedSearch] = useState(() => ({
    startDate: daysAgoStr(7),
    endDate: todayStr(),
    // 기타 검색 필드 기본값
  }));

  // ① fetchData — gridDataFetch 어댑터 사용 (DataTables 1.9 프로토콜 자동 변환)
  const fetchData = useCallback(async (pi, ps, sort, search) => {
    setLoading(true);
    try {
      const sortId  = sort?.[0]?.id   ?? 'DEFAULT_COL';
      const sortDir = sort?.[0]?.desc ? 'desc' : 'asc';
      const { data: rows, total: cnt } = await fetchGridData({
        mapperName: 'mapper.selectXxx',   // JSP JS 파일에서 확인
        pageIndex: pi,
        pageSize: ps,
        sortCol: sortId,
        sortDir,
        extraParams: {
          ...search,
          // 'ALL' 값은 빈 문자열로 변환 (서버 mapper 조건 처리)
          // serverCode: (search?.serverCode === 'ALL') ? '' : (search?.serverCode || ''),
        },
      });
      setData(rows);
      setTotal(cnt);
    } catch(e) { setData([]); setTotal(0); }
    finally { setLoading(false); }
  }, []);

  useEffect(() => {
    fetchData(pageIndex, pageSize, sorting, appliedSearch);
  }, [pageIndex, pageSize, sorting, appliedSearch, fetchData]);

  // ② 검색 실행
  const handleSearch = useCallback(() => {
    setAppliedSearch({ field1: val1, field2: val2 });
    setPageIndex(0);
  }, [val1, val2]);

  // ③ 페이지/크기 변경
  const handlePagination = useCallback(({ pageIndex: pi, pageSize: ps }) => {
    if (ps !== pageSize) { setPageSize(ps); setPageIndex(0); }
    else setPageIndex(pi);
  }, [pageSize]);

  // ④ 엑셀 다운로드
  const handleExcelExport = useCallback(() => {
    const rows = data.map(r => ({ 컬럼1: r.COL1, 컬럼2: r.COL2 }));
    const ws = XLSX.utils.json_to_sheet(rows);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, '시트명');
    XLSX.writeFile(wb, `파일명_${new Date().toISOString().slice(0,10)}.xlsx`);
  }, [data]);

  // ⑤ 컬럼 정의 — JSP listen.js columns[] 를 TanStack 형식으로 변환
  const columns = useMemo(() => [
    {
      accessorKey: 'COL_FIELD',   // data: "FIELD_NAME" 대응
      header: '헤더명',
      size: 100,                   // width px
      className: 'dt-center',
      cell: ({ getValue }) => formatValue(getValue()),  // render 함수 대응
    },
    {
      id: 'actionBtn',
      header: '버튼',
      enableSorting: false,
      className: 'dt-center',
      cell: ({ row }) => (
        <button onClick={e => { e.stopPropagation(); handleAction(row.original); }}>
          동작
        </button>
      ),
    },
    // hidden 컬럼 (visible: false): 컬럼에서 제외, row.original.HIDDEN_FIELD 로 직접 접근
  ], [handleAction]);

  return (
    <DataGrid
      data={data} columns={columns} total={total}
      pageIndex={pageIndex} pageSize={pageSize} pageSizeOptions={[30, 60, 90]}
      sorting={sorting} loading={loading}
      onPagination={handlePagination} onSorting={setSorting}
      onExcelExport={handleExcelExport}
      onRowDblClick={row => { setSelected(row); setShowDetail(true); }}
      scrollX={true}
    />
  );
}
```

### JSP DataTables → TanStack 변환 규칙

| JSP DataTables | TanStack Table v8 |
|---|---|
| `{ data: "FIELD", title: "헤더" }` | `{ accessorKey: 'FIELD', header: '헤더' }` |
| `{ visible: false }` | 컬럼 배열에서 제외 (row.original로 직접 접근) |
| `render: fn(data)` | `cell: ({ getValue }) => fn(getValue())` |
| `render: fn(data, type, full)` | `cell: ({ getValue, row }) => fn(getValue(), null, row.original)` |
| `defaultContent: ""` | 생략 (TanStack 자동 undefined → '' 처리) |
| `className: "dt-center"` | `className: 'dt-center'` (그대로) |
| `serverSide: true` + `fnServerParams` | `manualPagination + manualSorting + fetchData` |
| `order: [[col, 'desc']]` | `sorting: [{ id: 'FIELD_ID', desc: true }]` |
| `pageLength: 30` | `pageSize: 30` |
| `lengthMenu: [30,60,90]` | `pageSizeOptions={[30,60,90]}` |
| `buttons: [엑셀]` | `onExcelExport` + xlsx 라이브러리 |
| `on('dblclick')` | `onRowDblClick` prop |

### 서버 응답 키 파싱

`fetchGridData` 어댑터가 내부적으로 처리하므로 직접 파싱 불필요.
어댑터 정규화 순서 (참고용):
```js
// gridDataFetch.js 내부 — 직접 사용 금지
data  = res.aaData || res.rows || res.data || res.resultMap || []
total = res.iTotalRecords ?? res.iTotalDisplayRecords ?? res.totalCount ?? data.length
```

`/selectList` 엔드포인트 (페이징 없는 목록 조회)는 `apiPostForm` 직접 사용:
```js
const res = await apiPostForm('/selectList', { mapperName: '...', ...params });
const rows = res?.resultMap || [];
```

### Step 0 추가 확인 항목 (DataTables 화면)

```
[ ] mfn_xxxGrid.load() 의 mapperName 확인 (fnServerParams 내부)
[ ] sAjaxSource 확인 (/selectGridData vs /selectList vs custom)
[ ] columns[].render 함수 — 코드값 변환 로직 (장비번호, 채널, 상태코드 등)
[ ] downloadYn 기반 컬럼 숨김 조건
[ ] 버튼 컬럼 (play/download/toggle) — onClick에서 e.stopPropagation() 필수
[ ] colReorder (Phase 6에서 @dnd-kit/sortable로 대체 예정)
```

### Testing Checklist (next iteration)

Phase 3 마이그레이션 진행 시 최종 QA:

```
[ ] 모든 리스트 화면: 데이터 없을 때 헤더만 표시 (colSpan row 있음)
[ ] 모든 페이징 화면: page 범위 1-5 + 총 건수 표시
[ ] 사용자 화면: 조직도 트리 클릭 → 사용자 필터링 동작
[ ] 결재 화면: 상태 트리 클릭 → 해당 상태 문서만 로드
[ ] listen 화면: 오디오 재생/정지/배속 모두 동작
[ ] monitoring 화면: 서버 상태 카드 상태별 컬러 표시
[ ] 날짜 입력: type="date"로 native picker 표시
[ ] migration-screen-map.json: 모든 reactRoute에 main/ prefix 확인
[ ] deep-link 테스트: 각 화면 직접 URL 입력 → 200 응답
[ ] DataGrid 화면: 엑셀 다운로드 → .xlsx 파일 생성 확인
[ ] DataGrid 화면: 페이지 크기 변경 → pageIndex 0 리셋 확인
[ ] DataGrid 화면: 컬럼 헤더 클릭 → 정렬 방향 토글 + 재조회 확인
```
