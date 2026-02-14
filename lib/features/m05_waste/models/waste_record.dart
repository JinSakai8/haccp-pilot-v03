
class WasteRecord {
  final String id;
  final String venueId;
  final String zoneId;
  final String userId;
  final String wasteType;
  final String wasteCode;
  final double massKg;
  final String recipientCompany;
  final String? kpoNumber;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? syncedAt;

  WasteRecord({
    required this.id,
    required this.venueId,
    required this.zoneId,
    required this.userId,
    required this.wasteType,
    required this.wasteCode,
    required this.massKg,
    required this.recipientCompany,
    this.kpoNumber,
    this.photoUrl,
    required this.createdAt,
    this.syncedAt,
  });

  factory WasteRecord.fromJson(Map<String, dynamic> json) {
    return WasteRecord(
      id: json['id'] as String,
      venueId: json['venue_id'] as String,
      zoneId: json['zone_id'] as String,
      userId: json['user_id'] as String,
      wasteType: json['waste_type'] as String,
      wasteCode: json['waste_code'] as String,
      massKg: (json['mass_kg'] as num).toDouble(),
      recipientCompany: json['recipient_company'] as String,
      kpoNumber: json['kpo_number'] as String?,
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      syncedAt: json['synced_at'] != null 
          ? DateTime.parse(json['synced_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'venue_id': venueId,
      'zone_id': zoneId,
      'user_id': userId,
      'waste_type': wasteType,
      'waste_code': wasteCode,
      'mass_kg': massKg,
      'recipient_company': recipientCompany,
      'kpo_number': kpoNumber,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
    };
  }
}
