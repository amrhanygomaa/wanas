# Wanas (Flutter) — Cleanup & Professionalization Report

> Executed against the multi-phase cleanup prompt. Branch: `codex/app-fixes-ci`.
> **Scope decisions (confirmed with maintainer):** targeted split only (no full feature-restructure),
> git history left intact. God-file split **complete** — see §4.

---

## 1. Files deleted

| File | Tracked? | Reason |
|------|----------|--------|
| `lib/screens/specialist/views/analysis.txt` | Yes → `git rm` | UTF-16 analyzer error dump committed by mistake; not source |
| `C:tmpanalysis.txt`, `C:tmpflutter_analyze.txt` | No (local) | Malformed-path analyzer dumps cluttering the tree |
| `flutter_01.log`, `hs_err_pid3528.log` | No (local) | Run log + JVM crash dump |

> The many root-level docs (`Wanas *.pdf/.docx/.md`, `Wanas-*.png`), `google-service-account.json`,
> and `replace_aws.py` were **left in place** — they are already git-ignored and not tracked, so they
> do not affect the public repository.

## 2. Files added

| File | Purpose |
|------|---------|
| `README.md` (rewritten) | Professional overview, 6 roles, tech stack, configuration, build/test |
| `LICENSE` | MIT |
| `CODE_OF_CONDUCT.md` | Contributor Covenant 2.1 |
| `dart_defines.example.json` | Template for build-time config (`--dart-define-from-file`) |
| `.github/ISSUE_TEMPLATE/bug_report.md` | Bug template |
| `.github/ISSUE_TEMPLATE/feature_request.md` | Feature template |
| `.github/dependabot.yml` | Weekly `pub` + monthly `github-actions` updates |
| `.claude/inventory.md` | Phase-1 analysis (git-ignored working artifact) |

## 3. Files changed

| File | Change |
|------|--------|
| `.gitignore` | Added `dart_defines.json` (developer-filled config) |
| 26 `lib/**` files | `dart format` (whitespace only — no logic changes) |

> `lib/services/backend_sync_service.dart` was intentionally **excluded** from all changes — it had
> unrelated uncommitted work-in-progress from the maintainer.

## 4. Architecture

The app keeps its layer-first structure (`config/ models/ providers/ services/
widgets/ screens/<role>/`). A full feature-based restructure
(`lib/features/<x>/{data,domain,presentation}`) was evaluated and rejected for
this pass (would require moving ~152 files and rewriting every import).

### God-file split — DONE
The 6704-line `lib/providers/app_riverpod.dart` (single `AppRiverpod
extends ChangeNotifier`, ~465 methods, 110 fields) was split to **1978 lines
(-70%)** by moving cohesive method groups into **11 `part`-file extensions** —
no consumer import changes, all fields/constructor stay in the class:

| Part file | Domain |
|-----------|--------|
| `app_riverpod_memories.dart` | local albums / memories |
| `app_riverpod_facility.dart` | billing, audit trail, call history |
| `app_riverpod_residents_family.dart` | display prefs, family activities, AI errors |
| `app_riverpod_staff_reports.dart` | staff performance, reports, medical sessions |
| `app_riverpod_nursing_ops.dart` | nursing ops, care tasks, inventory, visits |
| `app_riverpod_family_reminders.dart` | family medication reminders |
| `app_riverpod_assessments.dart` | GDS / detailed assessments |
| `app_riverpod_memory_wall.dart` | family memory wall |
| `app_riverpod_elderly_media.dart` | gallery permissions, elderly tabs, media |
| `app_riverpod_auth_accounts.dart` | account management, registration, session, dark mode |
| `app_riverpod_activities_ai_emergency.dart` | family activity participation, AI insights, SOS |

**Recipe per part file** (validated by `flutter analyze` after each batch):
`extension AppRiverpodX on AppRiverpod {…}` in a `part of 'app_riverpod.dart'`
file; `// ignore_for_file: invalid_use_of_protected_member,
invalid_use_of_visible_for_testing_member` (because `notifyListeners()` is
`@protected`); and qualify static members as `AppRiverpod.<name>`. The analyzer
flagged one field hidden in a range (`totalCapacity`, trailing-comment line) —
moved back into the class.

## 5. Security & secrets audit

| Item | Finding | Action |
|------|---------|--------|
| `google-service-account.json` (real GCP secret) | **Never committed**; git-ignored | None needed; keep out of VCS |
| `git log --all` for `*.pem/*.p12/.env/*secret*/*.jks/*service-account*` | **All empty** | No history rewrite required |
| `lib/firebase_options.dart` Firebase Web API key | Client-side key (standard generated file) | Acceptable to commit; documented in README |
| `android/app/google-services.json` | Client-side Firebase config (Google-sanctioned to commit) | Left tracked; documented |
| `lib/config/api_config.dart` Cognito pool/client IDs | Public identifiers, not secrets | OK |
| App secrets (`ADMIN_REG_SECRET`, `API_BASE_URL`, `FACILITY_ID`) | Read via `String.fromEnvironment` | Already correct; templated in `dart_defines.example.json` |
| `debugPrint` near FCM token | Logs the *error*, never the token value | No leak |

## 6. Code quality

- **Dead code / unused imports:** none — `package:flutter_lints` is active and `flutter analyze`
  reports **No issues found!**, so unused imports/fields/elements are already eliminated.
- **TODO/FIXME/HACK:** **0** real markers (the inventory's earlier "20" were false positives from
  the substring `toDouble`).
- **Formatting:** 26 files brought to `dart format` standard.

## 7. Remaining technical debt

| Item | Status / approach |
|------|-------------------|
| `app_riverpod.dart` further reduction | Now 1978 lines (mostly fields/constructor/core init). Could shrink further with the same `part`-extension recipe; diminishing returns since fields must stay in the class. |
| Large screen files (140 KB `family_dashboard_screen.dart`, etc.) | Not done. Extract private widget classes into per-screen `widgets/` files incrementally. |
| Hardcoded UI strings | Not done. Arabic strings are inline; optional `core/constants/app_strings.dart` consolidation later. |

## 8. Verification

| Command | Result |
|---------|--------|
| `flutter analyze --no-fatal-infos` (baseline, pre-change) | ✅ No issues found! (276 s) |
| `dart format` | ✅ Applied (whitespace only) |
| `flutter test` | ✅ All tests passed |
| `flutter analyze` after **each** god-file split batch | ✅ No issues found! |

## 9. Commits (this effort)

```
chore:    remove stray analyzer dump and ignore filled build config
docs:     add professional README, LICENSE, Code of Conduct, and config template
ci:       add issue templates and Dependabot configuration
style:    apply dart format to source files
fix:      add braces to if statement flagged after formatting
refactor(state): extract Memories/Albums domain from AppRiverpod god-file
refactor(state): split 4 more domains out of AppRiverpod god-file
refactor(state): split 4 final domains out of AppRiverpod god-file
refactor(state): split auth/accounts and activities/AI/emergency domains out of AppRiverpod god-file
docs:     update cleanup report and executive summary (11 parts, -70%)
```

History was **not** rewritten (no leaked secrets; maintainer chose to keep history).
