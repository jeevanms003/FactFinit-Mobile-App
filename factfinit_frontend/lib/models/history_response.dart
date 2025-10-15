// lib/models/history_response.dart
class HistoryResponse {
  final String message;
  final HistoryData? data;
  final String? error;

  HistoryResponse({required this.message, this.data, this.error});

  factory HistoryResponse.fromJson(Map<String, dynamic> json) {
    return HistoryResponse(
      message: json['message'] ?? '',
      data: json['data'] != null ? HistoryData.fromJson(json['data']) : null,
      error: json['error'],
    );
  }
}

class HistoryData {
  final List<HistoryItem> history;
  final Pagination pagination;

  HistoryData({required this.history, required this.pagination});

  factory HistoryData.fromJson(Map<String, dynamic> json) {
    return HistoryData(
      history: (json['history'] as List<dynamic>?)
              ?.map((item) => HistoryItem.fromJson(item))
              .toList() ??
          [],
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class HistoryItem {
  final String videoURL;
  final String platform;
  final String normalizedTranscript;
  final bool isFinancial;
  final FactCheck factCheck;
  final DateTime createdAt;

  HistoryItem({
    required this.videoURL,
    required this.platform,
    required this.normalizedTranscript,
    required this.isFinancial,
    required this.factCheck,
    required this.createdAt,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      videoURL: json['videoURL'] ?? '',
      platform: json['platform'] ?? '',
      normalizedTranscript: json['normalizedTranscript'] ?? '',
      isFinancial: json['isFinancial'] ?? false,
      factCheck: FactCheck.fromJson(json['factCheck'] ?? {'claims': [], 'sources': []}),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class Pagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  Pagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}

class FactCheck {
  final List<Claim> claims;
  final List<Source> sources;

  FactCheck({required this.claims, required this.sources});

  factory FactCheck.fromJson(Map<String, dynamic> json) {
    return FactCheck(
      claims: (json['claims'] as List<dynamic>?)
              ?.map((claim) => Claim.fromJson(claim))
              .toList() ??
          [],
      sources: (json['sources'] as List<dynamic>?)
              ?.map((source) => Source.fromJson(source))
              .toList() ??
          [],
    );
  }
}

class Claim {
  final String claim;
  final bool isAccurate;
  final String explanation;

  Claim({required this.claim, required this.isAccurate, required this.explanation});

  factory Claim.fromJson(Map<String, dynamic> json) {
    return Claim(
      claim: json['claim'] ?? '',
      isAccurate: json['isAccurate'] ?? false,
      explanation: json['explanation'] ?? '',
    );
  }
}

class Source {
  final String title;
  final String url;
  final String snippet;

  Source({required this.title, required this.url, required this.snippet});

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      snippet: json['snippet'] ?? '',
    );
  }
}