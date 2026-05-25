import 'api_client.dart';

class EmergencyContactsSettings {
  final String? ambulance;
  final String? doctor;
  final String? codeBlue;
  final String? notes;

  const EmergencyContactsSettings({
    this.ambulance,
    this.doctor,
    this.codeBlue,
    this.notes,
  });

  factory EmergencyContactsSettings.fromJson(Map<String, dynamic> json) {
    return EmergencyContactsSettings(
      ambulance: _clean(json['ambulance']),
      doctor: _clean(json['doctor']),
      codeBlue: _clean(json['codeBlue'] ?? json['code_blue']),
      notes: _clean(json['notes']),
    );
  }

  Map<String, String> toPhoneMap() {
    return {
      if (ambulance != null) 'ambulance': ambulance!,
      if (doctor != null) 'doctor': doctor!,
      if (codeBlue != null) 'codeBlue': codeBlue!,
    };
  }
}

class FacilityBillingSettings {
  final String? accountName;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankIban;
  final String? walletProvider;
  final String? walletNumber;
  final String? instructions;

  const FacilityBillingSettings({
    this.accountName,
    this.bankName,
    this.bankAccountNumber,
    this.bankIban,
    this.walletProvider,
    this.walletNumber,
    this.instructions,
  });

  factory FacilityBillingSettings.fromJson(Map<String, dynamic> json) {
    return FacilityBillingSettings(
      accountName: _clean(json['accountName'] ?? json['account_name']),
      bankName: _clean(json['bankName'] ?? json['bank_name']),
      bankAccountNumber:
          _clean(json['bankAccountNumber'] ?? json['bank_account_number']),
      bankIban: _clean(json['bankIban'] ?? json['bank_iban']),
      walletProvider: _clean(json['walletProvider'] ?? json['wallet_provider']),
      walletNumber: _clean(json['walletNumber'] ?? json['wallet_number']),
      instructions: _clean(json['instructions']),
    );
  }

  bool get isEmpty =>
      accountName == null &&
      bankName == null &&
      bankAccountNumber == null &&
      bankIban == null &&
      walletProvider == null &&
      walletNumber == null &&
      instructions == null;

  String get displayText {
    final lines = <String>[];
    if (bankName != null || bankAccountNumber != null) {
      lines.add([
        if (bankName != null) 'البنك: $bankName',
        if (bankAccountNumber != null) 'رقم الحساب: $bankAccountNumber',
      ].join(' - '));
    }
    if (bankIban != null) {
      lines.add('IBAN: $bankIban');
    }
    if (walletProvider != null || walletNumber != null) {
      lines.add([
        if (walletProvider != null) 'المحفظة: $walletProvider',
        if (walletNumber != null) walletNumber,
      ].join(' - '));
    }
    if (accountName != null) {
      lines.add('اسم الحساب: $accountName');
    }
    if (instructions != null) {
      lines.add(instructions!);
    }
    return lines.join('\n');
  }
}

class FacilityProfileSettings {
  final String? facilityName;
  final String? address;
  final String? phone;
  final String? email;
  final String? logoUrl;
  final String? reportLegalFooter;
  final String? licenseNumber;
  final String? facilityYearOfEst;
  final String? facilityCapacity;
  final String? facilityLocationUrl;

  const FacilityProfileSettings({
    this.facilityName,
    this.address,
    this.phone,
    this.email,
    this.logoUrl,
    this.reportLegalFooter,
    this.licenseNumber,
    this.facilityYearOfEst,
    this.facilityCapacity,
    this.facilityLocationUrl,
  });

  factory FacilityProfileSettings.fromJson(Map<String, dynamic> json) {
    return FacilityProfileSettings(
      facilityName: _clean(json['facilityName'] ?? json['facility_name']),
      address: _clean(json['address']),
      phone: _clean(json['phone']),
      email: _clean(json['email']),
      logoUrl: _clean(json['logoUrl'] ?? json['logo_url']),
      reportLegalFooter:
          _clean(json['reportLegalFooter'] ?? json['report_legal_footer']),
      licenseNumber: _clean(json['licenseNumber'] ?? json['license_number']),
      facilityYearOfEst: _clean(json['facilityYearOfEst'] ??
          json['facility_year_of_est'] ??
          json['yearOfEst'] ??
          json['establishedYear']),
      facilityCapacity: _clean(json['facilityCapacity'] ?? json['capacity']),
      facilityLocationUrl: _clean(json['facilityLocationUrl'] ??
          json['facility_location_url'] ??
          json['locationUrl'] ??
          json['mapUrl']),
    );
  }
}

class FacilitySettingsService {
  FacilitySettingsService._();
  static final FacilitySettingsService instance = FacilitySettingsService._();

  final _api = ApiClient.instance;

  Future<EmergencyContactsSettings> emergencyContacts() async {
    final res = await _api.get('/admin/settings/emergency-contacts');
    return EmergencyContactsSettings.fromJson(Map<String, dynamic>.from(res));
  }

  Future<EmergencyContactsSettings> updateEmergencyContacts({
    String? ambulance,
    String? doctor,
    String? codeBlue,
    String? notes,
  }) async {
    final res = await _api.put('/admin/settings/emergency-contacts', body: {
      if (ambulance != null) 'ambulance': ambulance,
      if (doctor != null) 'doctor': doctor,
      if (codeBlue != null) 'codeBlue': codeBlue,
      if (notes != null) 'notes': notes,
    });
    return EmergencyContactsSettings.fromJson(Map<String, dynamic>.from(res));
  }

  Future<FacilityBillingSettings> billingSettings() async {
    final res = await _api.get('/admin/settings/billing');
    return FacilityBillingSettings.fromJson(Map<String, dynamic>.from(res));
  }

  Future<FacilityBillingSettings> updateBillingSettings({
    String? accountName,
    String? bankName,
    String? bankAccountNumber,
    String? bankIban,
    String? walletProvider,
    String? walletNumber,
    String? instructions,
  }) async {
    final res = await _api.put('/admin/settings/billing', body: {
      if (accountName != null) 'accountName': accountName,
      if (bankName != null) 'bankName': bankName,
      if (bankAccountNumber != null) 'bankAccountNumber': bankAccountNumber,
      if (bankIban != null) 'bankIban': bankIban,
      if (walletProvider != null) 'walletProvider': walletProvider,
      if (walletNumber != null) 'walletNumber': walletNumber,
      if (instructions != null) 'instructions': instructions,
    });
    return FacilityBillingSettings.fromJson(Map<String, dynamic>.from(res));
  }

  Future<FacilityProfileSettings> facilityProfile() async {
    final res = await _api.get('/admin/settings/facility-profile');
    return FacilityProfileSettings.fromJson(Map<String, dynamic>.from(res));
  }

  Future<FacilityProfileSettings> updateFacilityProfile({
    String? facilityName,
    String? address,
    String? phone,
    String? email,
    String? logoUrl,
    String? reportLegalFooter,
    String? licenseNumber,
    String? facilityYearOfEst,
    String? facilityCapacity,
    String? facilityLocationUrl,
  }) async {
    final res = await _api.put('/admin/settings/facility-profile', body: {
      if (_hasText(facilityName)) 'facilityName': facilityName!.trim(),
      if (_hasText(address)) 'address': address!.trim(),
      if (_hasText(phone)) 'phone': phone!.trim(),
      if (_hasText(email)) 'email': email!.trim(),
      if (_hasText(logoUrl)) 'logoUrl': logoUrl!.trim(),
      if (_hasText(reportLegalFooter))
        'reportLegalFooter': reportLegalFooter!.trim(),
      if (_hasText(licenseNumber)) 'licenseNumber': licenseNumber!.trim(),
      if (_hasText(facilityYearOfEst))
        'facilityYearOfEst': facilityYearOfEst!.trim(),
      if (_hasText(facilityCapacity))
        'facilityCapacity': facilityCapacity!.trim(),
      if (_hasText(facilityLocationUrl))
        'facilityLocationUrl': facilityLocationUrl!.trim(),
    });
    return FacilityProfileSettings.fromJson(Map<String, dynamic>.from(res));
  }
}

String? _clean(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
