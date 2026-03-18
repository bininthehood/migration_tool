# SPA Routing Contract — 상세 명세

## Required `dispatcher-servlet.xml` entries

```xml
<mvc:resources mapping="/ui/**" location="/ui/"/>
<mvc:default-servlet-handler />
<mvc:view-controller path="/ui"  view-name="redirect:/ui/"/>
<mvc:view-controller path="/ui/" view-name="forward:/ui/index.html"/>
<!-- Compatibility mappings: prevent 404 for root-relative asset requests -->
<mvc:resources mapping="/static/**"           location="/ui/static/"/>
<mvc:resources mapping="/manifest.json"       location="/ui/"/>
<mvc:resources mapping="/favicon.ico"         location="/ui/"/>
<mvc:resources mapping="/logo192.png"         location="/ui/"/>
<mvc:resources mapping="/logo512.png"         location="/ui/"/>
<mvc:resources mapping="/robots.txt"          location="/ui/"/>
<mvc:resources mapping="/asset-manifest.json" location="/ui/"/>
```

## Required Java controllers

**`SpaForwardController.java`**: `/ui` redirect, `/ui/` index forward, `/ui/**`(확장자 없음) → `index.html` forward

**`ViewController.java`**: legacy mapping은 반드시 `ui` 경로 제외 패턴 사용:
```java
@RequestMapping(value="/{path:^(?!ui$).+}/{page}")
```

## 검증 항목 (springmvc-spa-routing-guard)

| URL | 기대 응답 |
|-----|---------|
| `GET /ui` | 302 → `/ui/` |
| `GET /ui/` | 200 (index.html) |
| `GET /ui/login` | 200 (index.html) |
| `GET /ui/main/dashboard/monitoring` | 200 (index.html) |
| `GET /ui/static/js/main.js` | 200 (static asset) |

## 변경 전 항상 확인할 파일

```
src/main/webapp/WEB-INF/config/springmvc/dispatcher-servlet.xml
src/main/webapp/WEB-INF/web.xml
src/main/java/.../SpaForwardController.java
src/main/java/.../ViewController.java  (legacy /{path}/{page} 매핑)
```
