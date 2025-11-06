class CitizenRequestDto {
  final int id;
  final int citizenId;
  final int requestTypeId;
  final int categoryId;
  final String description;
  final int acceptedById;
  final int? assignedToId;
  final String incidentTime;
  final String createdAt;
  final String incidentLocation;
  final String citizenLocation;
  final int requestStatusId;
  final int? districtId;
  final String requestNumber;
  final double? latitude;
  final double? longitude;
  final String? aiCategory;
  final String? aiPriority;
  final String? aiSummary;
  final String? aiSuggestedAction;
  final String? aiSentiment;
  final String? aiAnalyzedAt;
  final bool? isAiCorrected;
  final String? finalCategory;

  const CitizenRequestDto({
    required this.id,
    required this.citizenId,
    required this.requestTypeId,
    required this.categoryId,
    required this.description,
    required this.acceptedById,
    required this.assignedToId,
    required this.incidentTime,
    required this.createdAt,
    required this.incidentLocation,
    required this.citizenLocation,
    required this.requestStatusId,
    required this.districtId,
    required this.requestNumber,
    required this.latitude,
    required this.longitude,
    required this.aiCategory,
    required this.aiPriority,
    required this.aiSummary,
    required this.aiSuggestedAction,
    required this.aiSentiment,
    required this.aiAnalyzedAt,
    required this.isAiCorrected,
    required this.finalCategory,
  });

  factory CitizenRequestDto.fromJson(Map<String, dynamic> json) {
    try {
      return CitizenRequestDto(
        id: json['id'] as int,
        citizenId: json['citizenId'] as int,
        requestTypeId: json['requestTypeId'] as int,
        categoryId: json['categoryId'] as int,
        description: json['description'] as String? ?? '',
        acceptedById: json['acceptedById'] as int,
        assignedToId: json['assignedToId'] as int?,
        incidentTime: json['incidentTime'] as String? ?? DateTime.now().toIso8601String(),
        createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
        incidentLocation: json['incidentLocation'] as String? ?? '',
        citizenLocation: json['citizenLocation'] as String? ?? '',
        requestStatusId: json['requestStatusId'] as int? ?? 1,
        districtId: json['districtId'] as int?,
        requestNumber: json['requestNumber'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        aiCategory: json['aiCategory'] as String?,
        aiPriority: json['aiPriority'] as String?,
        aiSummary: json['aiSummary'] as String?,
        aiSuggestedAction: json['aiSuggestedAction'] as String?,
        aiSentiment: json['aiSentiment'] as String?,
        aiAnalyzedAt: json['aiAnalyzedAt'] as String?,
        isAiCorrected: json['isAiCorrected'] as bool? ?? false,
        finalCategory: json['finalCategory'] as String?,
      );
    } catch (e) {
      throw FormatException('Ошибка парсинга CitizenRequestDto: $e');
    }
  }
}

class CreateCitizenRequestDto {
  final int citizenId;
  final int requestTypeId;
  final int categoryId;
  final String description;
  final int acceptedById;
  final int? assignedToId;
  final String incidentTime; // ISO 8601
  final String incidentLocation;
  final String citizenLocation;
  final double? latitude;
  final double? longitude;
  final int requestStatusId;

  const CreateCitizenRequestDto({
    required this.citizenId,
    required this.requestTypeId,
    required this.categoryId,
    required this.description,
    required this.acceptedById,
    this.assignedToId,
    required this.incidentTime,
    required this.incidentLocation,
    required this.citizenLocation,
    this.latitude,
    this.longitude,
    required this.requestStatusId,
  });

  Map<String, dynamic> toJson() => {
        'citizenId': citizenId,
        'requestTypeId': requestTypeId,
        'categoryId': categoryId,
        'description': description,
        'acceptedById': acceptedById,
        if (assignedToId != null) 'assignedToId': assignedToId,
        'incidentTime': incidentTime,
        'incidentLocation': incidentLocation,
        'citizenLocation': citizenLocation,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'requestStatusId': requestStatusId,
      };

  }






