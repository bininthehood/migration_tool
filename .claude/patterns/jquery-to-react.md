jQuery 기반 라이브러리를 React 컴포넌트로 이관합니다.

Spring MVC + JSP → React SPA 마이그레이션 시 사용하는 표준 교체 절차입니다.
인자 없이 호출하면 전체 분석 + 이관을 진행합니다.

## 인자 형식

```
/jquery-to-react [target]
```

| 인자 | 동작 |
|------|------|
| 인자 없음 | jQuery 사용 현황 분석 → 전체 교체 실행 |
| `analyze` | 분석만 수행 (코드 변경 없음) |
| `datatable` | DataTables만 교체 |
| `datepicker` | datepicker만 교체 |
| `modal` | modal만 교체 |

---

## Step 0 — 경로 확인

Bash로 frontend 루트를 결정합니다:
```bash
FRONTEND_ROOT="{project_root}/src/main/frontend"
WEBAPP_ROOT="{project_root}/src/main/webapp/resources/js"
```

---

## Step 1 — jQuery 사용 현황 스캔

```bash
# 각 라이브러리 사용 빈도 카운트
echo "=== DataTables ===" && grep -rl "\.DataTable\|\.dataTable\|selectGridData" "$WEBAPP_ROOT" | wc -l
echo "=== datepicker ===" && grep -rl "datepicker\|DatePicker\|gfn_setDatePicker" "$WEBAPP_ROOT" | wc -l
echo "=== modal ===" && grep -rl "openModal\|\.modal\(" "$WEBAPP_ROOT" | wc -l
echo "=== draggable ===" && grep -rl "\.draggable\(" "$WEBAPP_ROOT" | wc -l
echo "=== tooltip ===" && grep -rl "\.tooltip\(" "$WEBAPP_ROOT" | wc -l
echo "=== sortable ===" && grep -rl "\.sortable\(" "$WEBAPP_ROOT" | wc -l
echo "=== select2 ===" && grep -rl "\.select2\(" "$WEBAPP_ROOT" | wc -l
echo "=== Highcharts ===" && find "$WEBAPP_ROOT" -name "*.js" | xargs grep -l "Highcharts" 2>/dev/null | wc -l
```

결과를 출력하고 교체 우선순위를 결정합니다.

---

## Step 2 — 패키지 설치

필요한 패키지를 설치합니다 (이미 설치된 경우 스킵):

```bash
cd "$FRONTEND_ROOT"
PACKAGES=""

# DataTables 사용 시
grep -rl "\.DataTable\|selectGridData" "$WEBAPP_ROOT" | grep -q . && PACKAGES="$PACKAGES @tanstack/react-table xlsx"

# draggable/sortable 사용 시 (Phase 6)
# grep -rl "\.draggable\|\.sortable" "$WEBAPP_ROOT" | grep -q . && PACKAGES="$PACKAGES @dnd-kit/core @dnd-kit/sortable"

# select2 사용 시
# grep -rl "\.select2" "$WEBAPP_ROOT" | grep -q . && PACKAGES="$PACKAGES react-select"

[ -n "$PACKAGES" ] && npm install $PACKAGES
```

---

## Step 3 — DataGrid 컴포넌트 생성/갱신

### DataTables → TanStack Table v8

`src/main/frontend/src/components/DataGrid.jsx` 파일이 없으면 생성합니다.
있으면 현재 버전을 읽어 최신 패턴과 비교 후 필요한 경우만 갱신합니다.

#### 3-0. datagrid.css 생성 및 index.html 연결 (필수)

DataTables CSS를 제거했으므로 DataGrid 전용 CSS가 반드시 있어야 합니다.

```bash
DATAGRID_CSS="{project_root}/src/main/frontend/public/resources/css/common/datagrid.css"
INDEX_HTML="{project_root}/src/main/frontend/public/index.html"

# CSS 파일 없으면 생성
[ ! -f "$DATAGRID_CSS" ] && echo "datagrid.css 생성 필요"

# index.html에 링크 없으면 추가
grep -q "datagrid.css" "$INDEX_HTML" || echo "index.html에 datagrid.css 링크 추가 필요"
```

`datagrid.css` 필수 스타일:
- `#dataGrid thead th` — 헤더 배경(`#f5f5f5`), 테두리, 정렬 아이콘
- `#dataGrid tbody tr:hover` — 행 hover 효과(`#f0f7ff`)
- `#dataGrid tbody tr:nth-child(even)` — 짝수행 배경(`#fafafa`)
- `#dataGrid tbody td` — 셀 테두리, 패딩
- `.dt-center / .dt-left / .dt-right` — 정렬 클래스
- `.datagrid-toolbar .btn-excel` — 엑셀 버튼 (녹색)
- `.datagrid-pagination button` — 페이지네이션 버튼
- `.btn_play_record / .btn_download_record` — 재생/다운로드 버튼

`index.html` 링크 순서 (공통 CSS 마지막에 추가):
```html
<link rel="stylesheet" href="%PUBLIC_URL%/resources/css/common/header.css" />
<!-- DataGrid 컴포넌트 (DataTables 대체) -->
<link rel="stylesheet" href="%PUBLIC_URL%/resources/css/common/datagrid.css" />
```

참조 구현: `ArcFlow_Webv1.2/src/main/frontend/public/resources/css/common/datagrid.css`

**DataGrid.jsx 필수 기능:**
- `manualPagination` + `manualSorting` — 서버사이드
- 페이지 크기 선택 (pageSizeOptions)
- 로딩 스피너 (loading prop)
- Empty state (colSpan 행)
- 가로 스크롤 (scrollX)
- 엑셀 다운로드 버튼 (onExcelExport)
- 행 더블클릭 (onRowDblClick)
- 정렬 인디케이터 (▲ / ▼)
- 페이지네이션 컨트롤 (처음/이전/번호/다음/마지막 + 페이지 표시)

완성 구현 참조: `migration-agent-phase3.md` → "Phase 3.5 — DataGrid" 섹션

### 각 화면 DataGrid 적용 절차

1. JSP 원본 + 연결 JS 읽기 (Step 0 체크리스트 준수)
2. DataTables 컬럼 정의 → TanStack columnDef 변환:
   ```
   { data: "FIELD", title: "헤더", visible: true }
   → { accessorKey: 'FIELD', header: '헤더', size: 100, className: 'dt-center' }

   { visible: false }
   → 컬럼 배열에서 제외 (row.original.FIELD 로 직접 접근)

   render: function(data) { return transformed; }
   → cell: ({ getValue }) => transform(getValue())
   ```
3. fetchData 함수 — **반드시 `fetchGridData` 어댑터 사용** (직접 `apiPostForm` 호출 금지):
   ```js
   import { fetchGridData } from '../../api/gridDataFetch';

   // fetchData 예시
   const { data, total } = await fetchGridData({
     mapperName: 'listen_01.selectListenList',
     pageIndex,          // 0-based
     pageSize,
     sortCol: 'REC_KEY',
     sortDir: 'desc',
     extraParams: {
       startDate: search?.startDate || '',
       endDate:   search?.endDate   || '',
       serverCode: (search?.serverCode === 'ALL' || !search?.serverCode)
         ? '' : search.serverCode,
     },
   });
   ```
   **주의:** `/selectGridData` 는 DataTables 1.9 전용 파라미터(`iDisplayStart`, `iDisplayLength`, `sSortCol`)를 사용한다.
   React 코드에서 `start`/`length`/`order[0][*]` 로 직접 호출하면 서버의 페이징 분기가 트리거되지 않아 LIMIT 없이 전체 rows 반환 + `aaData` 아닌 `rows` key 반환으로 UI에 데이터가 표출되지 않는다.
   `gridDataFetch.js` 어댑터가 이 변환을 담당한다.
4. 서버 응답 파싱: `fetchGridData`가 `{ data, total }` 형태로 정규화하여 반환 — 직접 파싱 불필요.
5. 엑셀: `XLSX.utils.json_to_sheet` + `XLSX.writeFile`

---

## Step 4 — datepicker → DatePickerInput 컴포넌트

jQuery datepicker는 `src/components/DatePickerInput.jsx` (react-datepicker v9 래퍼)로 교체합니다.
연도/월 드롭다운 내비게이션, 한국어 로케일, YYYY-MM-DD 반환 인터페이스 포함.

```jsx
import DatePickerInput from '../../components/DatePickerInput';

// 오늘/N일 전 헬퍼
function todayStr() { return new Date().toISOString().slice(0, 10); }
function daysAgoStr(n) { const d = new Date(); d.setDate(d.getDate() - n); return d.toISOString().slice(0, 10); }

// 변경 전 (JSP)
// <input type="text" class="datepicker" id="searchStartDate">
// gfn_setDatePicker('#searchStartDate', -7);  // 7일 전

// 변경 후 (React)
const [startDate, setStartDate] = useState(() => daysAgoStr(7));
const [endDate, setEndDate] = useState(() => todayStr());

// appliedSearch도 초기값 설정 (페이지 로드 시 자동 조회)
const [appliedSearch, setAppliedSearch] = useState(() => ({
  startDate: daysAgoStr(7), endDate: todayStr(),
  // 기타 검색 필드의 기본값...
}));

// JSX
<DatePickerInput id="startDate" value={startDate} onChange={setStartDate} maxDate={new Date()} />
<DatePickerInput id="endDate" value={endDate} onChange={setEndDate}
  minDate={new Date(startDate)} maxDate={new Date()} />
```

**주의**: `value="ALL"` 등 드롭다운 기본값이 서버 mapper와 맞는지 확인.
전체 조회 옵션 value는 서버가 빈 문자열로 처리하는지 확인 후 fetchData에서 변환 처리:
```js
serverCode: search?.serverCode === 'ALL' ? '' : (search?.serverCode || ''),
```

---

## Step 5 — modal → React state 기반 모달

jQuery `openModal('#popXxx')` → React 조건부 렌더링으로 교체:

```jsx
// 변경 전 (JSP)
openModal('#popListenInfo', function() { ... });

// 변경 후 (React)
const [showModal, setShowModal] = useState(false);
const [modalData, setModalData] = useState(null);

// 열기
setModalData(rowData);
setShowModal(true);

// 모달 컴포넌트 (인라인 또는 별도 파일)
{showModal && modalData && (
  <div className="layer_popup" style={{
    display: 'flex', position: 'fixed', inset: 0, zIndex: 1000,
    background: 'rgba(0,0,0,0.4)', alignItems: 'center', justifyContent: 'center',
  }}>
    <div className="layer_wrap" style={{ background: '#fff', borderRadius: '4px', minWidth: '480px' }}>
      {/* 모달 내용 */}
      <div className="layer_popup_footer">
        <button onClick={() => setShowModal(false)}>닫기</button>
      </div>
    </div>
  </div>
)}
```

---

## Step 6 — 기타 라이브러리 대체 계획 (Phase 6 이후)

| jQuery 라이브러리 | React 대체 | 시기 |
|---|---|---|
| `draggable` | `@dnd-kit/core` | Phase 6 |
| `sortable` | `@dnd-kit/sortable` | Phase 6 |
| `tooltip` | CSS `title` 속성 or React tooltip | Phase 6 |
| `select2` | `react-select` | 해당 화면 마이그레이션 시 |
| `Highcharts` | `recharts` or `react-highcharts` | 해당 화면 마이그레이션 시 |
| `colReorder` (DataTables) | `@dnd-kit/sortable` | Phase 6 |

---

## Step 7 — 빌드 검증

```bash
cd "$FRONTEND_ROOT" && npm run build 2>&1 | tail -5
```

`Compiled successfully` 확인. 실패 시 에러 메시지 분석 후 수정.

---

## Step 8 — TASK_BOARD.md 업데이트

완료된 항목을 `[x]` 표시:
```
[x] DataGrid.jsx 생성/갱신
[x] {PageName}.jsx 그리드 → DataGrid 컴포넌트 적용
```

---

## 적용 완료 현황 (ArcFlow_Webv1.2 기준, 2026-03-18)

| 라이브러리 | 상태 | 비고 |
|---|---|---|
| DataTables (20개 화면) | ✅ 완료 | DataGrid.jsx + TanStack Table v8 |
| datepicker | ✅ 완료 | native `type="date"` |
| modal | ✅ 완료 | React state 기반 조건부 렌더링 |
| draggable | ⏳ Phase 6 | @dnd-kit/core |
| tooltip | ⏳ Phase 6 | CSS title 속성 |
| sortable | ⏳ Phase 6 | @dnd-kit/sortable |
| select2 | ⏳ 해당 화면 | react-select |
| Highcharts | ⏳ 해당 화면 | recharts |
