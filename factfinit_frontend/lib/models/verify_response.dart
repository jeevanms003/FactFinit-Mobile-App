class VerifyResponse {
  final String message;
  final VerifyData? data;
  final String? error;

  VerifyResponse({required this.message, this.data, this.error});

  factory VerifyResponse.fromJson(Map<String, dynamic> json) {
    return VerifyResponse(
      message: json['message'] ?? '',
      data: json['data'] != null ? VerifyData.fromJson(json['data']) : null,
      error: json['error'],
    );
  }
}

class VerifyData {
  final String videoURL;
  final String platform;
  final Map<String, dynamic> transcript;
  final String normalizedTranscript;
  final bool isFinancial;
  final FactCheck factCheck;

  VerifyData({
    required this.videoURL,
    required this.platform,
    required this.transcript,
    required this.normalizedTranscript,
    required this.isFinancial,
    required this.factCheck,
  });

  factory VerifyData.fromJson(Map<String, dynamic> json) {
    return VerifyData(
      videoURL: json['videoURL'] ?? '',
      platform: json['platform'] ?? '',
      transcript: json['transcript'] ?? {},
      normalizedTranscript: json['normalizedTranscript'] ?? '',
      isFinancial: json['isFinancial'] ?? false,
      factCheck: FactCheck.fromJson(json['factCheck'] ?? {'claims': [], 'sources': []}),
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
