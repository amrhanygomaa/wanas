// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// أداء الموظفين والتقارير والجلسات الطبية
// جزء (part) من مكتبة app_riverpod.dart — يوسّع AppRiverpod عبر extension.
part of 'app_riverpod.dart';

extension AppRiverpodStaffReports on AppRiverpod {
  int get totalStaffCount => staffPerformanceList.length;
  int get activeStaffCount =>
      staffPerformanceList.where((s) => s.status == 'online').length;
  double get averageStaffCompletion {
    if (staffPerformanceList.isEmpty) return 0.0;
    final total = staffPerformanceList
        .map((s) => s.completionRate)
        .reduce((a, b) => a + b);
    return total / staffPerformanceList.length;
  }

  void addStaff(StaffPerformance staff) {
    staffPerformanceList.insert(0, staff);

    triggerNotification(
      title: 'موظف جديد بالمنشأة 📋',
      body: 'تم تسجيل ${staff.name} ضمن الطاقم (${staff.role}).',
      type: 'admin',
      targetRole: 'مدير',
    );

    notifyListeners();
  }

  Future<void> joinOpportunity(String opportunityId) async {
    final idx = volunteerOpportunities.indexWhere((o) => o.id == opportunityId);
    if (idx != -1) {
      final opp = volunteerOpportunities[idx];

      final bookingId = 'book_$opportunityId';
      if (!volunteerBookings.any((b) => b.id == bookingId)) {
        final synced = await _runBackendMutation(() {
          return BackendMutationService.instance
              .createVolunteerBooking(opportunityId);
        });
        if (!synced) return;
        volunteerBookings.insert(
          0,
          VolunteerBooking(
            id: bookingId,
            title: opp.title,
            timeInfo: '${opp.dateInfo} · ${opp.hours} ساعة',
            day: DateTime.now().day + 1,
            month: 'أبريل',
            status: 'confirmed',
            location: opp.org,
            points: opp.points,
          ),
        );

        volunteerOpportunities[idx] = VolunteerOpportunity(
          id: opp.id,
          title: opp.title,
          org: opp.org,
          dateInfo: opp.dateInfo,
          icon: opp.icon,
          tags: opp.tags,
          hours: opp.hours,
          points: opp.points,
          isNew: opp.isNew,
          description: opp.description,
          totalSlots: opp.totalSlots,
          filledSlots: opp.filledSlots + 1,
          targetAudience: opp.targetAudience,
          targetResident: opp.targetResident,
          requiredSkills: opp.requiredSkills,
        );

        triggerNotification(
          title: 'تم الانضمام بنجاح! 🎉',
          body: 'أنت الآن مسجل في "${opp.title}". موعدنا قادماً!',
          type: 'volunteer',
          targetRole: 'متطوع',
        );

        notifyListeners();
        unawaited(syncBackendData());
      }
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    final idx = volunteerBookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      final synced = await _runBackendMutation(() {
        return BackendMutationService.instance
            .cancelVolunteerBooking(bookingId);
      });
      if (!synced) return;
      final booking = volunteerBookings[idx];
      volunteerBookings[idx] = VolunteerBooking(
        id: booking.id,
        title: booking.title,
        timeInfo: booking.timeInfo,
        day: booking.day,
        month: booking.month,
        status: 'cancelled',
        location: booking.location,
        points: booking.points,
        isUrgent: booking.isUrgent,
        startTime: booking.startTime,
        isRatingRequired: booking.isRatingRequired,
      );
      notifyListeners();
      unawaited(syncBackendData());
    }
  }

  Future<void> confirmAttendance(String bookingId) async {
    final idx = volunteerBookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      final synced = await _runBackendMutation(() {
        return BackendMutationService.instance
            .confirmVolunteerAttendance(bookingId);
      });
      if (!synced) return;
      final b = volunteerBookings[idx];
      volunteerBookings[idx] = VolunteerBooking(
        id: b.id,
        title: b.title,
        timeInfo: b.timeInfo,
        day: b.day,
        month: b.month,
        status: 'done',
        location: b.location,
        points: b.points,
        isUrgent: false,
        startTime: b.startTime,
        isRatingRequired: true,
      );
      addPoints(b.points);

      triggerNotification(
        title: 'تم تأكيد الحضور! ✅',
        body:
            'شكراً لمساهمتك في "${b.title}". تم إضافة ${b.points} نقطة لحسابك.',
        type: 'volunteer',
        targetRole: 'متطوع',
      );

      notifyListeners();
      unawaited(syncBackendData());
    }
  }

  void submitBookingRating(String bookingId) {
    final idx = volunteerBookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      final b = volunteerBookings[idx];
      volunteerBookings[idx] = VolunteerBooking(
        id: b.id,
        title: b.title,
        timeInfo: b.timeInfo,
        day: b.day,
        month: b.month,
        status: b.status,
        location: b.location,
        points: b.points,
        isUrgent: b.isUrgent,
        startTime: b.startTime,
        isRatingRequired: false,
      );
      notifyListeners();
    }
  }

  void saveMedicalVitals({
    required String residentName,
    required String bp,
    required String sugar,
    required String temp,
  }) async {
    await _syncVitals(
      residentName: residentName,
      bp: bp,
      sugar: sugar,
      temp: temp,
    );
    if (backendSyncError != null) return;

    final newSession = MedicalSession(
      id: 's${DateTime.now().millisecondsSinceEpoch}',
      type: 'vitals',
      specialistName: currentAccount?.name ?? 'فريق التمريض',
      time: 'الآن',
      date: 'اليوم',
      notes:
          'تم فحص المؤشرات الحيوية: الضغط ($bp)، السكر ($sugar مجم/دل)، الحرارة ($temp°)',
      residentName: residentName,
    );

    medicalSessions.insert(0, newSession);

    triggerNotification(
      title: 'تم حفظ القراءات 🏥',
      body: 'تم تسجيل العلامات الحيوية لـ $residentName بنجاح.',
      type: 'medical',
    );

    notifyListeners();
  }

  Future<void> addFamilyVisit(FamilyVisit visit) async {
    final residentId = _looksLikeBackendId(backendResidentId)
        ? backendResidentId
        : residentFiles.isNotEmpty
            ? residentFiles.first.id
            : null;
    if (residentId == null || !_looksLikeBackendId(residentId)) {
      backendSyncError = 'لا يوجد residentId من السيرفر لحجز الزيارة';
      notifyListeners();
      return;
    }
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.bookVisit(
        residentId: residentId,
        visit: visit,
      );
    });
    if (!synced) return;
    familyVisits.insert(0, visit);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<bool> approveVisit(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.approveVisit(id);
    });
    if (!synced) return false;
    final idx = familyVisits.indexWhere((v) => v.id == id);
    if (idx != -1) {
      familyVisits[idx] = familyVisits[idx].copyWith(status: 'upcoming');
      notifyListeners();
    }
    unawaited(syncBackendData());
    return true;
  }

  Future<bool> rejectVisit(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.rejectVisit(id);
    });
    if (!synced) return false;
    final idx = familyVisits.indexWhere((v) => v.id == id);
    if (idx != -1) {
      familyVisits[idx] = familyVisits[idx].copyWith(status: 'cancelled');
      notifyListeners();
    }
    unawaited(syncBackendData());
    return true;
  }

  Future<bool> cancelFamilyVisit(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.cancelVisit(id);
    });
    if (!synced) return false;
    final idx = familyVisits.indexWhere((v) => v.id == id);
    if (idx != -1) {
      familyVisits[idx] = familyVisits[idx].copyWith(status: 'cancelled');
      notifyListeners();
    }
    unawaited(syncBackendData());
    return true;
  }

  void sendFamilyMessage(String message, String residentName) {
    // LINK: Family to Specialist
    triggerNotification(
      title: 'رسالة من الأهل 📩',
      body: 'بخصوص $residentName: $message',
      type: 'complaint',
      targetRole: 'أخصائي',
    );
    notifyListeners();
  }

  Future<void> clearUnpaidBills() async {
    final unpaidBills = familyBills.where((b) => !b.isPaid).toList();
    for (final bill in unpaidBills) {
      final synced = await _runBackendMutation(() {
        return BackendMutationService.instance.payBill(bill.id);
      });
      if (!synced) return;
    }
    unawaited(syncBackendData());
    notifyListeners();
  }

  Future<void> addSocialNeed(SocialSpecialistNeed need) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createSocialNeed(need);
    });
    if (!synced) return;
    socialNeeds.insert(0, need);

    triggerNotification(
      title: 'احتياج جديد مسجل 🛡️',
      body: 'تم تسجيل احتياج ${need.type} للغرفة ${need.roomNumber}.',
      type: 'specialist',
      targetRole: 'أخصائي',
    );

    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> updateResident(SpecialistResidentFile resident) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.updateResident(resident);
    });
    if (!synced) return;
    final index = residentFiles.indexWhere((r) => r.id == resident.id);
    if (index != -1) {
      residentFiles[index] = resident;
      notifyListeners();
    }
    unawaited(syncBackendData());
  }

  Future<void> addResident(SpecialistResidentFile resident) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createResident(resident);
    });
    if (!synced) return;
    residentFiles.insert(0, resident);

    triggerNotification(
      title: 'إضافة مقيم جديد 👥',
      body: 'تم تسجيل ${resident.name} في الغرفة ${resident.room}.',
      type: 'admin',
      targetRole: 'مدير',
    );

    triggerNotification(
      title: 'مقيم جديد تحت الرعاية 🛡️',
      body: 'المقيم ${resident.name} انضم للمسكن في الغرفة ${resident.room}.',
      type: 'social',
      targetRole: 'أخصائي',
    );

    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<bool> deleteResident(String residentId) async {
    final index = residentFiles.indexWhere((r) => r.id == residentId);
    if (index == -1) return false;

    final removedResident = residentFiles[index];
    final removedFamilyMembers =
        familyMembersList.where((m) => m.residentId == residentId).toList();
    final previousNotifications = List<TaptabaNotification>.from(notifications);
    residentFiles.removeAt(index);
    familyMembersList.removeWhere((m) => m.residentId == residentId);
    notifications.removeWhere((n) =>
        n.body.contains(removedResident.name) ||
        n.title.contains(removedResident.name) ||
        (removedResident.room.isNotEmpty &&
            n.body.contains(removedResident.room)));
    notifyListeners();

    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.deleteResident(residentId);
    });
    if (!synced) {
      final restoreAt =
          index > residentFiles.length ? residentFiles.length : index;
      residentFiles.insert(restoreAt, removedResident);
      familyMembersList.addAll(removedFamilyMembers);
      notifications = previousNotifications;
      notifyListeners();
      return false;
    }

    unawaited(syncBackendData());
    return true;
  }

  double get medicationComplianceRate {
    if (medications.isEmpty) return 1.0;
    final taken = medications.where((m) => m.isTaken).length;
    return taken / medications.length;
  }

  int get unresolvedComplaintsCount =>
      socialComplaints.where((c) => c.status != 'done').length;

  Future<void> closeComplaint(String id, String resolutionNote) async {
    final idx = socialComplaints.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final c = socialComplaints[idx];
      await _syncComplaintStatus(
        id,
        'closed',
        resolutionNotes: resolutionNote,
      );
      if (backendSyncError != null) return;

      // Update status and add to timeline
      final updatedTimeline = List<ComplaintStep>.from(c.timeline);
      updatedTimeline.add(ComplaintStep(
        text: 'تم الحل: $resolutionNote',
        time: 'الآن',
        status: 'done',
      ));

      socialComplaints[idx] = SocialSpecialistComplaint(
        id: c.id,
        title: c.title,
        residentName: c.residentName,
        room: c.room,
        date: c.date,
        priority: c.priority,
        status: 'done',
        category: c.category,
        icon: c.icon,
        timeline: updatedTimeline,
      );

      triggerNotification(
        title: 'تم حل شكواكم بنجاح ✅',
        body:
            'بخصوص "${c.title}" لسرير ${c.residentName}. التفاصيل: $resolutionNote',
        type: 'social',
        targetRole: 'أهل',
      );

      notifyListeners();
    }
  }

  double get occupancyRate {
    if (totalCapacity == 0) return 0.0;
    return residentFiles.length / totalCapacity;
  }

  String generatePerformanceSummary() {
    final compliance = (medicationComplianceRate * 100).toInt();
    final occupancy = (occupancyRate * 100).toInt();
    return '''
ملخص أداء ${facilityName.isEmpty ? 'المنشأة' : facilityName}
التاريخ: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}

1. الإشغال: $occupancy%
2. الالتزام الدوائي: $compliance%
3. الشكاوى المفتوحة: $unresolvedComplaintsCount شكاوى
4. الطاقم النشط: $activeStaffCount من أصل $totalStaffCount موظف

التوصيات: 
- الحفاظ على مستوى الاستجابة السريع للشكاوى.
- تعزيز فترات الراحة للطاقم الطبي لضمان استمرارية الجودة.
''';
  }

  Future<String> exportReport(String format) async {
    if (format == 'pdf') {
      final pdf = pw.Document();
      final now = DateTime.now();
      final timeStr = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
      final dateStr = "${now.day}/${now.month}/${now.year}";

      final fontData = await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
      final ttf = pw.Font.ttf(fontData);
      final boldFontData = await rootBundle.load("assets/fonts/Cairo-Bold.ttf");
      final ttfBold = pw.Font.ttf(boldFontData);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
          textDirection: pw.TextDirection.rtl,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(facilityName,
                            style: pw.TextStyle(
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue900)),
                        pw.Text('تقرير الأداء الإداري والتشغيلي',
                            style: const pw.TextStyle(
                                fontSize: 12, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.PdfLogo(),
                  ],
                ),
              ),
              pw.SizedBox(height: 25),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                child: pw.Column(
                  children: [
                    _pdfInfoRow('اسم الدار:', facilityName),
                    _pdfInfoRow('اسم المدير المسئول:', managerName),
                    _pdfInfoRow('تاريخ التقرير:', dateStr),
                    _pdfInfoRow('وقت الاستخراج:', timeStr),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Text('ملخص مؤشرات الأداء:',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Divider(thickness: 1.5, color: PdfColors.blue100),
              pw.SizedBox(height: 15),
              pw.TableHelper.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(
                    color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.blue800),
                cellAlignment: pw.Alignment.centerRight,
                data: <List<String>>[
                  <String>['المؤشر الإحصائي', 'القيمة'],
                  <String>[
                    'نسبة إشغال الأسرة',
                    '${(occupancyRate * 100).toInt()}%'
                  ],
                  <String>[
                    'معدل الالتزام الدوائي',
                    '${(medicationComplianceRate * 100).toInt()}%'
                  ],
                  <String>[
                    'عدد الشكاوى قيد المعالجة',
                    unresolvedComplaintsCount.toString()
                  ],
                  <String>['عدد الموظفين المتواجدين', '$activeStaffCount موظف'],
                ],
              ),
              pw.SizedBox(height: 40),
              pw.Text('التوصيات والإجراءات المطلوبة:',
                  style: pw.TextStyle(
                      fontSize: 15, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              _pdfBullet(ttf, 'ضرورة متابعة تحديث بيانات المقيمين الجدد.'),
              _pdfBullet(ttf, 'التأكد من جاهزية مخزون الأدوية للأسبوع القادم.'),
              _pdfBullet(ttf,
                  'مراجعة ملاحظات الأخصائي الاجتماعي بخصوص الحالات الحرجة.'),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('يعتمد من مدير المنشأة',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 10),
                      pw.Text(managerName),
                      pw.SizedBox(height: 30),
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                              bottom: pw.BorderSide(
                                  width: 1, style: pw.BorderStyle.dashed)),
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text('التوقيع والختم الرسمي',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey)),
                    ],
                  ),
                ],
              ),
            ];
          },
        ),
      );

      await Printing.sharePdf(
          bytes: await pdf.save(), filename: 'Taptaba_Report.pdf');
    } else if (format == 'csv' || format == 'excel') {
      final csvBuffer = StringBuffer();
      csvBuffer.write('\uFEFF');
      csvBuffer.writeln('تقرير أداء المنشأة: $facilityName');
      csvBuffer.writeln('المدير المسئول: $managerName');
      csvBuffer.writeln(
          'التاريخ: ${DateTime.now().toLocal().toString().split(' ')[0]}');
      csvBuffer.writeln('');
      csvBuffer.writeln('المؤشر الإحصائي,القيمة');
      csvBuffer.writeln('نسبة الإشغال,${(occupancyRate * 100).toInt()}%');
      csvBuffer.writeln(
          'الالتزام الدوائي,${(medicationComplianceRate * 100).toInt()}%');
      csvBuffer.writeln('الشكاوى المفتوحة,$unresolvedComplaintsCount');
      csvBuffer.writeln('الطاقم النشط,$activeStaffCount');

      final encodedCsv = Uri.encodeComponent(csvBuffer.toString());
      final url = 'data:text/csv;charset=utf-8,$encodedCsv';

      try {
        final uri = Uri.parse(url);
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {}
    }

    final dateStrFile =
        "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
    final fileName = "Taptaba_Report_$dateStrFile.$format";
    return fileName;
  }

  pw.Widget _pdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text(label,
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(width: 5),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}
