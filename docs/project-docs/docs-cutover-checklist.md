# Migration Cutover Checklist

## Phase 0 — Setup
- [ ] bootstrap-frontend.sh --apply --install-deps completed
- [ ] dispatcher-servlet.xml SPA routing configured
- [ ] SpaForwardController.java created
- [ ] ViewController.java updated to exclude /ui path
- [ ] Initial npm run build successful
- [ ] webapp/ui deployed and GET /rays/ui/ returns 200

## Phase 1 — Inventory
- [ ] All JSP screens catalogued (23 screens)
- [ ] API endpoints documented
- [ ] Session contract verified

## Phase 2 — React Integration
- [ ] React router configured with context path support
- [ ] Session guard implemented
- [ ] Common layout created

## Phase 3 — Screen Migration (P0)
- [ ] Login screen migrated (/ui/login)
- [ ] Main screen migrated (/ui/main)

## Phase 3 — Screen Migration (P1+)
- [ ] Remaining 21 screens migrated

## Go-Live
- [ ] All screens smoke tested
- [ ] Legacy JSP screens removed or redirected
- [ ] Performance validated

## Status
- Phase 0 — initial stub checklist.
