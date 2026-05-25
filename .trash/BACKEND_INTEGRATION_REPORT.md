# تقرير شامل: حالة الباك اند والتكامل مع تطبيق طبطبة (Taptaba)

> **تاريخ التقرير**: 2026-05-19
> **المشروع**: نظام رعاية المسنين — طبطبة
> **الباك اند**: `aws_raaya_backend/` (NestJS + AWS)
> **الفرونت اند**: `lib/` (Flutter + Riverpod)

---

## 📋 ملخص تنفيذي (TL;DR)

| | الحالة |
|---|---|
| **الباك اند** | ✅ مكتمل بنسبة كبيرة جداً — 27 موديول NestJS، 25 SQL migration، AWS Cognito + RDS + Bedrock + S3 + Lambda |
| **الفرونت اند** | 🔴 يعمل بـ 100% Mock Data — لا يوجد أي اتصال HTTP فعلي بالباك اند |
| **عدد الـ Endpoints الجاهزة** | ~70 endpoint موثق على Swagger |
| **عدد جداول قاعدة البيانات** | 25+ جدول PostgreSQL |
| **النواقص الرئيسية** | طبقة Service/Repository داخل التطبيق، AuthService بـ Cognito، طبقة الـ DTO Mappers، ربط الـ UI بالـ providers الحقيقية بدلاً من القوائم الـ in-memory |

---

## 1️⃣ تحليل الباك اند (AWS Raaya Backend)

### 1.1 التقنيات المستخدمة

| الطبقة | التقنية |
|---|---|
| Framework | **NestJS 11** (TypeScript 5.7) |
| Database | **PostgreSQL** عبر AWS RDS — مع `pg` driver خام (بدون ORM) |
| Authentication | **AWS Cognito** + `passport-jwt` + `jwks-rsa` |
| AI | **AWS Bedrock** (Claude Haiku 4.5) |
| Storage | **AWS S3** (presigned URLs) |
| Scheduled Jobs | **AWS Lambda** + **EventBridge** + `JOB_SECRET` |
| Deployment | **AWS EC2 (Docker)** + **ECR** |
| Docs | **Swagger UI** على `/api/docs` |
| Monitoring | **AWS CloudWatch** |
| CI/CD | **GitHub Actions** |

### 1.2 جدول الـ Modules الكاملة (27 موديول)

| # | الموديول | الـ Endpoints | الوصف |
|---|---|---|---|
| 1 | **AuthModule** | `POST /auth/login`, `GET /auth/me` | تسجيل دخول Cognito وإرجاع JWT |
| 2 | **UsersModule** | `GET /users/me`, `GET /users/admin`, `GET /users/clinical` | اختبار RBAC |
| 3 | **ResidentsModule** | `POST/GET/PATCH /residents`, `GET/PUT /residents/:id/medical-info` | إدارة المقيمين + معلوماتهم الطبية |
| 4 | **MedicationsModule** | `/medications/schedules` (CRUD), `/medications/doses` (CRUD), `/medications/overdue`, `/medications/adherence` | جدولة الأدوية + تسجيل الجرعات + تقارير الالتزام |
| 5 | **FamilyBridgeModule** | `/family-bridge/media/upload`, `/family-bridge/media/:id/confirm`, `GET /family-bridge/media`, `/family-bridge/visits` (CRUD + status) | الجسر بين العائلة والدار: وسائط + زيارات |
| 6 | **HealthModule** | `/health/vitals` (POST/GET), `/health/alerts` (GET/PATCH), `/health/thresholds` (GET/PUT) | العلامات الحيوية والتنبيهات تلقائياً |
| 7 | **KpiModule** | `GET /kpi/dashboard` | مؤشرات الأداء الإدارية |
| 8 | **ComplaintsModule** | `/complaints` (POST/GET), `/complaints/:id`, `/complaints/:id/status` | إدارة الشكاوى مع state machine |
| 9 | **AdminManagementModule** | `/admin/users` (POST/GET), `/admin/users/:id/disable`, `/admin/settings` (GET/PUT), `/admin/staff-performance` | إدارة الحسابات والإعدادات وأداء الموظفين |
| 10 | **NursingNotesModule** | `/nursing-notes` (CRUD) | الملاحظات التمريضية |
| 11 | **HandoffsModule** | `/handoffs` (POST/GET), `/handoffs/:id` | تسليم الشفت بين الممرضين |
| 12 | **CareTasksModule** | `/care-tasks` (POST/GET), `/care-tasks/:id/complete` | مهام الرعاية اليومية |
| 13 | **InventoryModule** | `/inventory` (POST/GET), `/inventory/:id/stock`, `/inventory/low-stock` | إدارة المخزون والتنبيه على النقص |
| 14 | **DoctorVisitsModule** | `/doctor-visits` (CRUD) | زيارات الطبيب الخارجية |
| 15 | **MedicalSessionsModule** | `/medical-sessions` (POST/GET) | الجلسات الطبية (طبيب، علاج طبيعي، علامات حيوية) |
| 16 | **PrescriptionsModule** | `/prescriptions` (POST/GET) | الوصفات الطبية |
| 17 | **MealPlansModule** | `/meal-plans` (CRUD) | خطط الوجبات لكل مقيم |
| 18 | **ActivitiesModule** | `/activities` (POST/GET/PATCH) | الأنشطة الترفيهية للمسنين |
| 19 | **VolunteersModule** | `/volunteers/profile`, `/volunteers/opportunities`, `/volunteers/bookings`, `/volunteers/certificates`, `/volunteers/ratings`, `/volunteers/reviews` | نظام المتطوعين الكامل |
| 20 | **MemoriesModule** | `/memories` (POST/GET), `/memories/:id/appreciate` | لحظات الذكريات (Memory Wall) |
| 21 | **VoiceMessagesModule** | `/voice-messages/upload`, `GET /voice-messages` | الرسائل الصوتية |
| 22 | **BillingModule** | `/billing` (POST/GET), `/billing/:id/pay` | الفواتير العائلية |
| 23 | **SocialModule** | `/social/needs`, `/social/assessment-tools`, `/social/resident-scores`, `/social/assessments`, `/social/kpis` | الأخصائي الاجتماعي: تقييمات وكي بي آيز |
| 24 | **ReportsModule** | `/reports/nursing/preview`, `/completeness`, `/export`, `/history`, `/settings`, `/send` | تقارير التمريض (preview + export + send) |
| 25 | **NotificationsModule** | `/notifications` (POST), `/notifications/:userId` (GET), `/notifications/:id/read` (PATCH) | الإشعارات الداخلية |
| 26 | **AiModule** | `/ai/chat`, `/ai/recommendations/:residentId`, `/ai/memory/:residentId` (GET/POST) | الرفيق الذكي + التوصيات + ذاكرة المسن |
| 27 | **JobsModule** | `/jobs/medication-reminder`, `/jobs/daily-digest`, `/jobs/weekly-ai-summary` | محمية بـ `x-job-secret` لاستدعاء Lambda |

### 1.3 جداول قاعدة البيانات (25 SQL Migration)

```
001_create_residents.sql              → residents, family_members, linked_records
002_create_medications.sql            → medication_schedules, dose_logs
003_create_family_bridge.sql          → media_items, visits
004_create_health.sql                 → vital_signs, vital_alerts, vital_thresholds
005_create_complaints.sql             → complaints, complaint_audit_log
006_create_admin_management.sql       → managed_users, facility_settings
007_create_nursing_notes.sql          → nursing_notes
008_create_shift_handoffs.sql         → shift_handoffs
009_create_notifications.sql          → notifications
010_create_resident_medical_info.sql  → resident_medical_info
011_create_care_tasks.sql             → care_tasks
012_create_inventory.sql              → inventory_items
013_create_doctor_visits.sql          → doctor_visits
014_create_medical_sessions.sql       → medical_sessions
015_create_prescriptions.sql          → prescriptions
016_create_meal_plans.sql             → meal_plans
017_create_activity_sessions.sql      → activity_sessions
018_create_volunteers.sql             → volunteer_profiles, opportunities, bookings, certificates
019_create_volunteer_ratings.sql      → volunteer_ratings, volunteer_reviews
020_create_memory_moments.sql         → memory_moments
021_create_voice_messages.sql         → voice_messages
022_create_family_bills.sql           → family_bills
023_create_social_specialist.sql      → social_needs, assessment_tools, resident_scores, assessments
024_create_nursing_report_deliveries.sql → nursing_report_deliveries
025_create_nursing_report_settings.sql   → nursing_report_settings
```

### 1.4 المميزات المتقدمة الموجودة

- ✅ **Facility Scoping**: كل الاستعلامات معزولة تلقائياً عبر `custom:facilityId` من JWT.
- ✅ **RBAC**: `RolesGuard` + `@Roles('Admin'|'Nurse'|'Doctor'|'ClinicalStaff'|'Family')`.
- ✅ **Family Access Guard**: العائلة لا ترى إلا المقيم المرتبط بحسابها.
- ✅ **Auto-triggered Alerts**: تسجيل العلامات الحيوية يولّد تنبيهات تلقائياً من جدول `vital_thresholds`.
- ✅ **State Machines** للشكاوى والزيارات.
- ✅ **AI Guardrails**: منع النصائح الطبية، تحليل المشاعر، دعم لهجات (مصري/سعودي/شامي)، fallback محلي عند فشل Bedrock.
- ✅ **Audit Logs** للتغييرات الحرجة (شكاوى، مهام).
- ✅ **Presigned URLs** لرفع الوسائط مباشرة على S3.
- ✅ **Lambda Functions** جاهزة: تذكير الأدوية، الملخص اليومي، الملخص الأسبوعي بالذكاء الاصطناعي.
- ✅ **Swagger Docs** كاملة لكل endpoint.

---

## 2️⃣ تحليل الفرونت اند (تطبيق طبطبة Flutter)

### 2.1 الحالة الفعلية الحالية

| | |
|---|---|
| إجمالي شاشات Flutter | **62 شاشة** عبر 6 أدوار |
| إجمالي Models | **20+ نموذج** (User, Resident, Medication, FamilyMember, Complaint, ...) |
| State Management | **Riverpod** (`ChangeNotifierProvider` واحد ضخم — `app_riverpod.dart` بـ 4117 سطر) |
| التخزين | `flutter_secure_storage` (محلي فقط، يحفظ Role + isAuthenticated + sessionExpiry) |
| **HTTP Client** | ❌ **غير مثبت** في `pubspec.yaml` |
| **AWS Cognito** | ❌ **غير مثبت** |
| API Service | ❌ **غير موجود** |
| Auth Service | ❌ **غير موجود** |
| Repository Layer | ❌ **غير موجودة** |
| DTO/Mappers | ❌ **غير موجودة** |
| Environment Config | ❌ **غير موجودة** |

### 2.2 منطق الـ Login الحالي (Mock)

من `lib/providers/app_riverpod.dart` (lines 673-739):

```dart
Future<bool> login(String idRaw, String passRaw) async {
  // 1. يبحث في قائمة accounts الـ hard-coded داخل الذاكرة
  // 2. password '123' يُسجّل الدخول لأي مستخدم (Legacy demo support)
  // 3. لا يوجد أي HTTP call إطلاقاً
  ...
}
```

### 2.3 خريطة الـ Mock Data المعرّفة في الـ Provider

| البيانات | السطر | يحتاج Backend Module |
|---|---|---|
| `accounts` | 59-117 | `auth/login` + `admin/users` |
| `handoffs` | 351-360 | `handoffs` |
| `notifications` | 368-554 | `notifications` |
| `nursingNotes` | 608-628 | `nursing-notes` |
| `residentMedicalInfos` | 639-660 | `residents/:id/medical-info` |
| `medications` | 788-838 | `medications/schedules` + `medications/doses` |
| `activities` | 870-932 | `activities` |
| `familyMembersList` | 933-978 | لا يوجد endpoint مباشر ⚠️ |
| `voiceMessagesList` | 979-1006 | `voice-messages` |
| `aiInsights` | 1014-1036 | `ai/recommendations/:residentId` |
| `companionChatHistory` | 1038-1046 | `ai/chat` |
| `memoriesList` | 1054-1092 | `memories` |
| `volunteerOpportunities` | 1107-1152 | `volunteers/opportunities` |
| `volunteerBookings` | 1153-1188 | `volunteers/bookings` |
| `volunteerCertificates` | 1189-1235 | `volunteers/certificates` |
| `volunteerRatings` | 1236-1274 | `volunteers/ratings` |
| `volunteerReviews` | 1275-1305 | `volunteers/reviews` |
| `questionBank` | 1306-1406 | لا يوجد endpoint ⚠️ (يحتاج إضافة) |
| `socialAssessmentTools` | 1426-1460 | `social/assessment-tools` |
| `socialNeeds` | 1461-1481 | `social/needs` |
| `socialResidentScores` | 1482-1517 | `social/resident-scores` |
| `socialComplaints` | 1540-1612 | `complaints` |
| `gdsQuestions` | 1834-1874 | لا يوجد endpoint ⚠️ |
| `assessmentHistory` | 1875-1886 | جزء من `social/assessments` |
| `familyHealthMetrics` | 2339-2349 | جزء من `health/vitals` |
| `familyVisits` | 2366-2403 | `family-bridge/visits` |
| `familyBills` | 2404-2428 | `billing` |
| `residentFiles` | 2429-2519 | `residents` |
| `medicalSessions` | 2562-2588 | `medical-sessions` |
| `medicalPrescriptions` | 2589-2603 | `prescriptions` |
| `sentReports` | 2606-2629 | `reports/nursing/history` |
| `staffPerformanceList` | 2725-2747 | `admin/staff-performance` |
| `memoryMoments` | 3281-3302 | `memories` |

---

## 3️⃣ مقارنة شاملة: Frontend ↔ Backend

### 3.1 الجدول الكامل للمطابقة

| الميزة | Frontend Screen / Provider | Backend Endpoint | الحالة |
|---|---|---|---|
| **🔐 المصادقة** | | | |
| تسجيل الدخول | `login_screen.dart` + `provider.login()` | `POST /auth/login` | 🟡 جاهز Backend — يحتاج Cognito SDK في Flutter |
| تسجيل المدير | `admin_register_screen.dart` + `registerAdmin()` | ❌ لا يوجد endpoint للـ self-register للمدير | 🔴 ناقص — يحتاج `POST /auth/register-admin` |
| تسجيل عائلة/متطوع | `register_screen.dart` + `selfRegister()` | ❌ غير موجود (Cognito SignUp مطلوب) | 🔴 ناقص — يحتاج `POST /auth/register` |
| المستخدم الحالي | جميع الشاشات | `GET /auth/me` | 🟡 جاهز Backend |
| Logout + Token Refresh | `provider.logout()`, `checkAndRefreshSession()` | (Cognito refresh token) | 🔴 يحتاج تنفيذ |
| **👴 شاشات المسن (Elderly)** | | | |
| الأدوية | `medication_screen.dart` | `GET /medications/schedules` + `/doses` | 🟡 جاهز |
| تأكيد المسن لجرعة | `elderlyConfirmMedication()` | `PATCH /medications/doses/:id` | 🟡 جاهز |
| الأنشطة | `activities_screen.dart` | `GET /activities` | 🟡 جاهز |
| المكالمات العائلية | `calls_screen.dart` | ❌ لا يوجد `family-members` endpoint | 🔴 ناقص (موجود جدول family_members لكن بدون كنترولر مستقل) |
| الذكريات | `memories_screen.dart` | `GET /memories` | 🟡 جاهز |
| الرسائل الصوتية | `voice_messages_playback_screen.dart` | `GET /voice-messages` | 🟡 جاهز |
| AI Companion Chat | `widgets/ai_companion_chat.dart` | `POST /ai/chat` | 🟡 جاهز |
| SOS | `widgets/draggable_sos.dart`, `triggerSOS()` | ❌ لا يوجد endpoint مخصص للطوارئ | 🔴 ناقص — مقترح: `POST /emergency/sos` |
| **👨‍⚕️ شاشات الممرض (Nurse)** | | | |
| لوحة المرضى | `nurse_residents_screen.dart` | `GET /residents` | 🟡 جاهز |
| ملف المقيم | `nurse_resident_detail_screen.dart` | `GET /residents/:id` + `/medical-info` | 🟡 جاهز |
| الأدوية المتأخرة | `nurse_medications_screen.dart` | `GET /medications/overdue` | 🟡 جاهز |
| تسليم الشفت | `shift_handoff_screen.dart` | `POST/GET /handoffs` | 🟡 جاهز |
| الملاحظات التمريضية | (داخل nurse_resident_detail) | `POST/GET /nursing-notes` | 🟡 جاهز |
| التقارير | `nurse_reports_screen.dart` | `GET /reports/nursing/preview` + `/export` + `/send` | 🟡 جاهز |
| العلامات الحيوية | `saveMedicalVitals()` في provider | `POST /health/vitals` | 🟡 جاهز |
| مهام الرعاية | `views/operations_view.dart` | `GET/POST /care-tasks` | 🟡 جاهز |
| الجلسات الطبية | (داخل medical_admin_view) | `POST/GET /medical-sessions` | 🟡 جاهز |
| الوصفات الطبية | (مرتبط بالممرض) | `POST/GET /prescriptions` | 🟡 جاهز |
| زيارات الأطباء | (مرتبط بالممرض) | `POST/GET /doctor-visits` | 🟡 جاهز |
| المخزون | (داخل operations_view) | `GET /inventory`, `/low-stock` | 🟡 جاهز |
| خطط الوجبات | (مرتبط بالممرض) | `POST/GET /meal-plans` | 🟡 جاهز |
| **🧠 شاشات الأخصائي الاجتماعي** | | | |
| الاحتياجات | `views/home_view.dart` | `GET/POST /social/needs` | 🟡 جاهز |
| أدوات التقييم | `views/assessment_view.dart` | `GET /social/assessment-tools` | 🟡 جاهز |
| تقييم مقيم | `assessment_detailed_screen.dart` | `POST /social/assessments` | 🟡 جاهز |
| درجات المقيمين | `views/home_view.dart` | `GET /social/resident-scores` | 🟡 جاهز |
| الشكاوى | `views/complaints_view.dart` | `GET/POST /complaints`, `PATCH /complaints/:id/status` | 🟡 جاهز |
| تصعيد الشكوى | `escalateComplaint()` | جزء من `/complaints/:id/status` | 🟡 جاهز (بحاجة دعم flag escalated) |
| ملفات المقيمين | `views/files_view.dart` | `GET /residents` + `/medical-info` | 🟡 جاهز |
| KPI | `views/kpi_view.dart` | `GET /social/kpis` + `/kpi/dashboard` | 🟡 جاهز |
| الأنشطة المنظمة | `views/activities_view.dart` | `GET/POST /activities` | 🟡 جاهز |
| **👨‍👩‍👧 شاشات الأسرة (Family)** | | | |
| لوحة الأسرة | `family_dashboard_screen.dart` | `GET /residents/:id` + `/health/vitals` | 🟡 جاهز |
| جسر الأسرة | `family_bridge_screen.dart` | `GET /family-bridge/media`, `POST /family-bridge/media/upload` | 🟡 جاهز |
| حجز زيارة | `visit_booking_screen.dart` | `POST /family-bridge/visits` | 🟡 جاهز |
| محادثة الأخصائي | `chat_with_specialist_screen.dart` | ❌ لا يوجد chat endpoint بين family ↔ specialist | 🔴 ناقص — مقترح: `POST /messages` |
| تقرير الرعاية | `care_report_detail_screen.dart` | `GET /reports/nursing/preview` | 🟡 جاهز جزئياً |
| الفواتير | (داخل family_dashboard) | `GET /billing`, `PATCH /billing/:id/pay` | 🟡 جاهز |
| ID المقيم | `resident_id_screen.dart` | `GET /residents/:id` | 🟡 جاهز |
| **🙋‍♂️ شاشات المتطوع** | | | |
| الفرص | `opportunities_view.dart` | `GET /volunteers/opportunities` | 🟡 جاهز |
| الانضمام لفرصة | `joinOpportunity()` | `POST /volunteers/bookings` | 🟡 جاهز |
| الحجوزات | `bookings_view.dart` | `GET /volunteers/bookings`, `PATCH .../cancel`, `.../confirm-attendance` | 🟡 جاهز |
| الشهادات | `certificates_view.dart` | `GET /volunteers/certificates` | 🟡 جاهز |
| التقييمات | `ratings_view.dart` | `GET /volunteers/ratings` + `/reviews` | 🟡 جاهز |
| البروفايل | `profile_view.dart` + `edit_profile_sheet.dart` | `GET/PUT /volunteers/profile` | 🟡 جاهز |
| **🏢 شاشات الإدارة (Admin)** | | | |
| لوحة الإدارة | `admin_dashboard_screen.dart` | `GET /kpi/dashboard` | 🟡 جاهز |
| إدارة المقيمين | `views/residents_management_view.dart` | `POST/GET/PATCH /residents` (Admin) | 🟡 جاهز |
| إدارة الموظفين | `views/staff_management_view.dart` | `POST/GET /admin/users`, `PATCH .../disable` | 🟡 جاهز |
| الموافقة على الزيارات | `views/visit_approval_view.dart` | `PATCH /family-bridge/visits/:id/status` | 🟡 جاهز |
| المتطوعين (إدارة) | `views/admin_volunteer_view.dart` | ❌ لا يوجد admin endpoint لمراجعة المتطوعين | 🔴 ناقص |
| التقارير | `views/admin_reports_view.dart` | `GET /reports/nursing/*` | 🟡 جاهز جزئياً (تقرير الدار الإداري الكامل غير موجود) |
| إعدادات الدار | (داخل admin) | `GET/PUT /admin/settings` | 🟡 جاهز |
| **🔔 ميزات مشتركة** | | | |
| الإشعارات | `notifications_center_screen.dart` | `GET /notifications/:userId`, `PATCH .../read` | 🟡 جاهز |
| البروفايل العام | `profile_screen.dart` | `GET /auth/me`, `PUT /volunteers/profile` (للمتطوع) | 🟡 جزئي — يحتاج `PUT /users/me` عام |
| رفع صورة بروفايل | `pickProfileImage()` | ❌ لا يوجد S3 endpoint للبروفايل | 🔴 ناقص |
| الذاكرة الذكية للمسن | (داخل AI screens) | `GET/POST /ai/memory/:residentId` | 🟡 جاهز |

> **رمز الحالة**:
> - 🟢 مربوط فعلياً
> - 🟡 الـ Backend جاهز، يحتاج فقط طبقة Service في الفرونت اند
> - 🔴 الـ Backend ناقص أو الميزة غير مغطاة

---

## 4️⃣ ما هو ناقص في الباك اند ويحتاج إضافة

### 4.1 Endpoints مفقودة كلياً

| # | Endpoint مقترح | السبب | الأولوية |
|---|---|---|---|
| 1 | `POST /auth/register` | تسجيل ذاتي للأسرة والمتطوع (موجود في الـ UI) | 🔴 عالية |
| 2 | `POST /auth/register-admin` + `POST /facilities` | تسجيل مدير + إنشاء منشأة جديدة (موجود `admin_register_screen.dart`) | 🔴 عالية |
| 3 | `POST /auth/refresh-token` | تجديد الجلسة (موجود في الـ provider منطقياً) | 🔴 عالية |
| 4 | `PATCH /users/me` + `POST /users/me/avatar` | تحديث البروفايل العام ورفع الصورة على S3 | 🟠 متوسطة |
| 5 | `GET/POST /family-members` | إدارة المكالمات/جهات الاتصال للمسن (الجدول موجود لكن بدون كنترولر) | 🔴 عالية |
| 6 | `POST /emergency/sos` + `GET /emergency/alerts` | زر الطوارئ — مهم جداً | 🔴 عالية |
| 7 | `POST /messages` + `GET /messages/conversations` | محادثة بين الأسرة والأخصائي (`chat_with_specialist_screen.dart`) | 🔴 عالية |
| 8 | `POST /calls/initiate` (Zoom/WebRTC link) | المكالمات المرئية بين المسن والعائلة | 🟠 متوسطة |
| 9 | `GET /social/assessment-tools/:id/questions` + `GET /social/gds-questions` | بنك الأسئلة (موجود في `questionBank` و `gdsQuestions` في الـ provider) | 🟠 متوسطة |
| 10 | `GET /admin/financial-reports` + `GET /admin/operational-stats` | التقارير الإدارية الكاملة (`adminStats` في الـ provider) | 🟠 متوسطة |
| 11 | `GET /admin/volunteers` + `PATCH /admin/volunteers/:id/approve` | إدارة المتطوعين من ناحية الإدارة | 🟠 متوسطة |
| 12 | `POST /complaints/:id/escalate` (أو flag منفصل في PATCH status) | تصعيد الشكوى (موجود `escalateComplaint` في الـ provider) | 🟠 متوسطة |
| 13 | `POST /memories/:id/comment` + `GET /memories/feed` | تفاعل العائلة على لحظات الذكريات | 🟡 منخفضة |
| 14 | `GET /activities/:id/participants` + `POST .../join` | تسجيل المسن في نشاط (موجود `completeActivity` في الـ provider) | 🟠 متوسطة |
| 15 | `POST /reviews` (general — للأخصائي/الممرض/الدار) | نموذج `Review` في `app_models.dart` بلا endpoint | 🟡 منخفضة |
| 16 | `GET /accessibility-settings` + `PUT` | حفظ تفضيلات (Dark mode, font size, high contrast) في السحابة | 🟡 منخفضة |
| 17 | `GET /onboarding/state` + `POST /onboarding/complete` | حفظ حالة الـ onboarding على السيرفر | 🟡 منخفضة |
| 18 | WebSocket / SSE للإشعارات اللحظية | الإشعارات الحالية polling فقط | 🟠 متوسطة |
| 19 | `POST /push-tokens` (تسجيل FCM/APNS token) | لإرسال إشعارات Push حقيقية للموبايل | 🔴 عالية |
| 20 | `POST /reports/admin/export` (PDF + CSV) | الإدارة لها تقريرها الخاص (PDF generation موجود في الفرونت فقط) | 🟠 متوسطة |

### 4.2 تحسينات على الـ Endpoints الموجودة

| الموديول | التحسين المطلوب |
|---|---|
| **Auth** | إضافة `POST /auth/forgot-password` + `POST /auth/reset-password` + `POST /auth/verify-email` |
| **Residents** | إضافة `DELETE /residents/:id` (soft delete) + `POST /residents/:id/avatar` |
| **Medications** | إضافة `DELETE /medications/schedules/:id` + `POST /medications/schedules/:id/pause` |
| **FamilyBridge** | إضافة pagination + filter بالـ date range |
| **Notifications** | إضافة `PATCH /notifications/read-all` + `DELETE /notifications/:id` + filter بـ type/role |
| **AI** | جعل `/ai/memory/:residentId` يخزن في DB بدلاً من `Map` داخل الذاكرة (حالياً تضيع عند إعادة التشغيل) |
| **KPI** | إضافة فلاتر زمنية (`?from=&to=`) + breakdown per role |
| **Volunteers** | إضافة `GET /volunteers/impact` (residents served + hours + ratings) — موجود `VolunteerImpact` في الـ model |
| **Reports** | إضافة `GET /reports/admin/*` للإدارة (ليس فقط `nursing`) |
| **Complaints** | إضافة timeline events endpoint (`/complaints/:id/timeline`) |

### 4.3 جداول DB مقترحة للإضافة

```sql
-- جدول الطوارئ
CREATE TABLE emergency_alerts (
  id UUID PRIMARY KEY,
  facility_id TEXT NOT NULL,
  resident_id UUID REFERENCES residents(id),
  triggered_by TEXT, -- userId (المسن أو أحد الطاقم)
  type TEXT, -- 'sos', 'fall', 'medical'
  status TEXT, -- 'active', 'responding', 'resolved'
  notes TEXT,
  responded_by TEXT,
  responded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- جدول المحادثات
CREATE TABLE conversations (
  id UUID PRIMARY KEY,
  facility_id TEXT NOT NULL,
  participants TEXT[], -- [userId1, userId2]
  resident_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE TABLE messages (
  id UUID PRIMARY KEY,
  conversation_id UUID REFERENCES conversations(id),
  sender_id TEXT,
  body TEXT,
  media_url TEXT,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- جدول Push Tokens للإشعارات
CREATE TABLE push_tokens (
  id UUID PRIMARY KEY,
  user_id TEXT NOT NULL,
  token TEXT NOT NULL,
  platform TEXT, -- 'ios', 'android'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- بنك أسئلة التقييم (GDS, MMSE, ...)
CREATE TABLE assessment_question_bank (
  id UUID PRIMARY KEY,
  tool_id TEXT NOT NULL, -- 'gds', 'mmse', 'social', ...
  question_index INT,
  text TEXT,
  type TEXT, -- 'choice', 'scale', 'text'
  options JSONB
);

-- تفضيلات المستخدم (Accessibility)
CREATE TABLE user_preferences (
  user_id TEXT PRIMARY KEY,
  dark_mode BOOLEAN DEFAULT FALSE,
  high_contrast BOOLEAN DEFAULT FALSE,
  font_scale NUMERIC DEFAULT 1.0,
  language TEXT DEFAULT 'ar-eg',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- جهات الاتصال العائلية للمسن (للمكالمات)
CREATE TABLE family_contacts (
  id UUID PRIMARY KEY,
  resident_id UUID REFERENCES residents(id),
  family_member_id UUID REFERENCES family_members(id),
  zoom_link TEXT,
  is_pinned BOOLEAN DEFAULT TRUE,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 5️⃣ خطة الربط (Integration Roadmap)

### 5.1 المرحلة الأولى — البنية التحتية في Flutter (أسبوع 1)

1. **إضافة المكتبات** في `pubspec.yaml`:
   ```yaml
   dependencies:
     http: ^1.2.0
     amazon_cognito_identity_dart_2: ^3.6.0
     dio: ^5.4.0   # أفضل من http للـ interceptors
     flutter_dotenv: ^5.1.0
     # … الموجود الآن
   ```

2. **إنشاء طبقة API service**:
   ```
   lib/
   ├── config/
   │   └── api_config.dart         # baseUrl, Cognito IDs
   ├── services/
   │   ├── auth_service.dart       # Cognito login/logout/refresh
   │   ├── api_client.dart         # Dio + JWT interceptor + 401 handler
   │   ├── residents_service.dart
   │   ├── medications_service.dart
   │   ├── ai_service.dart
   │   ├── family_bridge_service.dart
   │   ├── volunteers_service.dart
   │   ├── notifications_service.dart  (موجود حالياً → توسيعها)
   │   └── ... (واحد لكل موديول)
   ├── repositories/
   │   └── *_repository.dart       # caching + offline support
   └── models/
       └── dto/                    # DTOs لكل endpoint
   ```

3. **توسيع `pubspec.yaml`**: إضافة `flutter_secure_storage` (موجود) + Cognito + Dio + firebase_messaging (للـ push).

### 5.2 المرحلة الثانية — استبدال الـ Mock تدريجياً (أسبوعين)

ترتيب مقترح حسب الأهمية:

| الموجة | الموديولات | ملاحظات |
|---|---|---|
| **W1** | Auth (Cognito) + Residents + Notifications | الأساس لكل شيء بعدها |
| **W2** | Medications + Health (Vitals) + Care Tasks | للممرض |
| **W3** | Family Bridge + Visits + Billing + Memories | للأسرة |
| **W4** | Social + Complaints + Assessments + KPI | للأخصائي |
| **W5** | Volunteers (كل الموديول) | للمتطوع |
| **W6** | Admin Management + Reports + KPI Dashboard | للإدارة |
| **W7** | AI Chat + AI Recommendations + AI Memory | الذكاء الاصطناعي |
| **W8** | Push Notifications (FCM) + WebSocket لإشعارات لحظية | تحسين تجربة المستخدم |

### 5.3 المرحلة الثالثة — Endpoints جديدة في الباك اند (بالتوازي)

أولويات الباك اند:

| Sprint | المهمة |
|---|---|
| **Sprint 1** | `POST /auth/register`, `POST /auth/register-admin`, `POST /facilities` |
| **Sprint 1** | `POST /auth/refresh-token`, `POST /auth/forgot-password` |
| **Sprint 2** | `family-members` controller + `family-contacts` table |
| **Sprint 2** | `emergency_alerts` (SOS) module |
| **Sprint 3** | `messages` module (chat between family ↔ specialist) |
| **Sprint 3** | `push-tokens` module + FCM integration |
| **Sprint 4** | `admin/financial-reports` + `admin/operational-stats` + admin volunteer mgmt |
| **Sprint 5** | تخزين AI memory في DB (لا في Map ذاكرة) + WebSocket gateway للإشعارات |
| **Sprint 5** | `accessibility-settings` + `onboarding-state` |
| **Sprint 6** | تحسينات: pagination, filters, soft delete, search |

---

## 6️⃣ مخاطر وملاحظات حرجة

### 6.1 مخاطر تقنية

1. ⚠️ **AI Memory مخزّن في Map ذاكرة**: في `ai.controller.ts` السطر 201 — `residentMemory = new Map()`. سيضيع كل شيء عند إعادة تشغيل السيرفر أو الـ scale out.
   - **الحل**: نقله إلى جدول `ai_resident_memory` في PostgreSQL.

2. ⚠️ **JOB_SECRET بدون rotation**: مفتاح ثابت بدون آلية تدوير.
   - **الحل**: استخدام AWS Secrets Manager + rotation policy.

3. ⚠️ **HTTP بدون TLS في الـ production**: الـ `flutter-integration.md` يذكر `http://13.219.217.9:3000` — يجب الانتقال لـ HTTPS قبل الإنتاج.

4. ⚠️ **Self-registration للأدوار**: حالياً في الـ Flutter `selfRegister()` يقبل أي دور بدون تحقق — يجب الباك اند يفرض أن الأدوار `Family` و `Volunteer` فقط هي القابلة للتسجيل الذاتي.

5. ⚠️ **`pubspec.yaml` لا يحتوي على `http`**: نسي التطبيق إضافة أي عميل HTTP — هذا أكبر دليل أن الربط لم يبدأ.

### 6.2 ثغرات في تطابق الـ Models

| Frontend Model | Backend Schema | الفرق |
|---|---|---|
| `Resident` (Flutter) | `residents` table | الفرونت يحتوي على `bloodType, allergies, chronicDiseases, dietType` — الـ Backend وضعها في جدول منفصل `resident_medical_info`. **يجب الـ Mapper يجمعهم.** |
| `Medication` (Flutter) | `medication_schedules` + `dose_logs` | الفرونت model واحد، الـ Backend مفصول لجدولين. **يجب التحويل في الـ Service layer.** |
| `FamilyMember` (Flutter) | `family_members` table | الفرونت فيه `zoomLink, isAvailable, isPinned` — الباك اند ينقصه. **يحتاج توسيع الـ schema.** |
| `Activity` (Flutter) | `activity_sessions` | الفرونت فيه `emoji, badges, pointsReward, colorValue` — الباك اند schema بسيط. **يحتاج توسيع.** |
| `TaptabaNotification` (Flutter) | `notifications` table | الفرونت فيه `targetRole, residentId` — يجب تأكيد وجودهم في الباك اند. |
| `Review` (Flutter) | ❌ لا يوجد جدول | يحتاج إنشاء `reviews` table كامل |

### 6.3 ميزات في الفرونت ليس لها مقابل واضح في الباك اند

- **Offline mode** (`pendingAssessments`, `syncAssessments`) — الفرونت يدعم العمل أوفلاين، لكن لا يوجد batch sync endpoint.
- **Real-time SOS broadcast** — يحتاج WebSocket/SSE.
- **Live video calls** — يحتاج توقيع Zoom JWT أو Twilio Video token من السيرفر.
- **PDF generation** — حالياً في الفرونت فقط، يفضل نقلها للباك اند لمركزية القوالب.
- **TTS/STT** — في الفرونت فقط، لا تحتاج باك اند.

---

## 7️⃣ خلاصة وتوصيات نهائية

### ما هو **جاهز**:
✅ **70% من الـ endpoints الأساسية** موجودة وموثقة في الباك اند.
✅ Schema قاعدة بيانات قوية ومنظمة بـ 25 migration.
✅ AWS Cognito + RBAC + Multi-tenancy (facility scoping) موجودين.
✅ AI integration كامل مع guardrails وfallback.
✅ Lambda jobs جاهزة للجدولة.
✅ Swagger Docs كاملة.

### ما هو **ناقص في الباك اند** (20 endpoint مقترح):
🔴 Auth: register, register-admin, refresh-token, forgot-password
🔴 Family contacts/calls module (الجدول موجود، الكنترولر لا)
🔴 Emergency/SOS module
🔴 Messages module (family ↔ specialist chat)
🔴 Push tokens + WebSocket للإشعارات اللحظية
🟠 Admin volunteer management
🟠 Question bank (GDS/MMSE) endpoints
🟠 User preferences + accessibility settings
🟠 Admin operational/financial reports

### ما هو **ناقص في الفرونت اند** (الأكبر):
🔴 **كل طبقة الـ networking غير موجودة** — لا يوجد `http`, لا Cognito SDK, لا API service, لا repository، لا DTO mappers.
🔴 **Login لا يكلم Cognito** — يعتمد على in-memory matching.
🔴 **لا يوجد أي شاشة فيها HTTP call فعلي** — كل البيانات mock.

### الخطوة الأولى المقترحة (المرحلة 0):
1. إنشاء `lib/config/api_config.dart` و `lib/services/api_client.dart` و `lib/services/auth_service.dart`.
2. ربط شاشة الـ Login بـ `POST /auth/login`.
3. ربط شاشة قائمة المقيمين بـ `GET /residents`.
4. التحقق أن الجلسة تتجدد عبر Cognito refresh token.

بعد إثبات أن طريق الـ integration يعمل بثلاث شاشات، يمكن التوسع للباقي بنفس النمط.

---

## 📎 ملحق: روابط مرجعية داخل المشروع

- الباك اند: [aws_raaya_backend/aws_raaya_backend/src/](aws_raaya_backend/aws_raaya_backend/src/)
- وثائق API الكاملة: [aws_raaya_backend/aws_raaya_backend/docs/api.md](aws_raaya_backend/aws_raaya_backend/docs/api.md)
- دليل تكامل Flutter (موجود مسبقاً): [aws_raaya_backend/aws_raaya_backend/docs/flutter-integration.md](aws_raaya_backend/aws_raaya_backend/docs/flutter-integration.md)
- البنية المعمارية: [aws_raaya_backend/aws_raaya_backend/docs/architecture.md](aws_raaya_backend/aws_raaya_backend/docs/architecture.md)
- Migrations DB: [aws_raaya_backend/aws_raaya_backend/migrations/](aws_raaya_backend/aws_raaya_backend/migrations/)
- مزود الحالة الحالي (Mock): [lib/providers/app_riverpod.dart](lib/providers/app_riverpod.dart)
- نماذج الفرونت اند: [lib/models/app_models.dart](lib/models/app_models.dart)
- شاشة الدخول (نقطة البداية للربط): [lib/screens/auth/login_screen.dart](lib/screens/auth/login_screen.dart)

---

> 🛠 **آخر شيء**: يوجد ملف `docs/flutter-integration.md` في الباك اند يحتوي على عينة كود `ApiService` جاهز للنسخ — هذا يوفر وقت كبير في المرحلة الأولى.
