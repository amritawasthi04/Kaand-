class SportsScore {
  final String id;
  final String league;
  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;
  final String status; // 'live', 'final', 'scheduled', 'in_progress'
  final DateTime? startTime;
  final String? venue;
  final String? sport; // 'cricket', 'football', 'basketball', 'tennis', etc.
  final String? tournament;
  final String? matchUrl;
  final String? imageUrl;
  final bool isLive;
  final String? inning; // For cricket
  final String? overs; // For cricket
  final String? commentary; // Latest commentary

  SportsScore({
    required this.id,
    required this.league,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.status,
    this.startTime,
    this.venue,
    this.sport,
    this.tournament,
    this.matchUrl,
    this.imageUrl,
    this.isLive = false,
    this.inning,
    this.overs,
    this.commentary,
  });

  factory SportsScore.fromJson(Map<String, dynamic> json) {
    return SportsScore(
      id: json['id'] as String? ?? '',
      league: json['league'] as String? ?? '',
      homeTeam: json['homeTeam'] as String? ?? '',
      awayTeam: json['awayTeam'] as String? ?? '',
      homeScore: json['homeScore'] as int? ?? 0,
      awayScore: json['awayScore'] as int? ?? 0,
      status: json['status'] as String? ?? 'scheduled',
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime'] as String) : null,
      venue: json['venue'] as String?,
      sport: json['sport'] as String?,
      tournament: json['tournament'] as String?,
      matchUrl: json['matchUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      isLive: json['isLive'] as bool? ?? false,
      inning: json['inning'] as String?,
      overs: json['overs'] as String?,
      commentary: json['commentary'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'league': league,
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'status': status,
      'startTime': startTime?.toIso8601String(),
      'venue': venue,
      'sport': sport,
      'tournament': tournament,
      'matchUrl': matchUrl,
      'imageUrl': imageUrl,
      'isLive': isLive,
      'inning': inning,
      'overs': overs,
      'commentary': commentary,
    };
  }

  String get scoreDisplay => '$homeScore - $awayScore';
  
  String get teamsDisplay => '$homeTeam vs $awayTeam';
  
  String get shortStatus {
    switch (status) {
      case 'live':
        return 'LIVE';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'final':
        return 'FINAL';
      case 'scheduled':
        return 'SCHEDULED';
      default:
        return status.toUpperCase();
    }
  }
}

class SportsScoreParser {
  // Parse ESPN RSS for live scores
  static List<SportsScore> parseEspnRss(String xmlContent) {
    // This is a simplified parser - real implementation would use proper XML parsing
    // For now, return empty list - we'll enhance with actual parsing
    return [];
  }

  // Parse generic sports RSS for scores
  static List<SportsScore> parseGenericSportsRss(String xmlContent, String source) {
    // Generic parser for sports feeds
    return [];
  }

  // Extract score from title like "India 285/3 vs Australia 280/10 - Final"
  static SportsScore? extractScoreFromTitle(String title, String url, String source) {
    // Patterns for various sports
    final cricketPattern = RegExp(r'(\w+)\s+(\d+/\d+|\d+)\s*(?:vs|v)\s*(\w+)\s+(\d+/\d+|\d+)\s*[-–]\s*(\w+)', caseSensitive: false);
    final footballPattern = RegExp(r'(\w+)\s+(\d+)\s*[-–]\s*(\d+)\s+(\w+)', caseSensitive: false);
    
    // Try cricket pattern first
    final cricketMatch = cricketPattern.firstMatch(title);
    if (cricketMatch != null) {
      return SportsScore(
        id: url,
        league: 'Cricket',
        homeTeam: cricketMatch.group(1) ?? '',
        awayTeam: cricketMatch.group(3) ?? '',
        homeScore: _parseScore(cricketMatch.group(2) ?? '0'),
        awayScore: _parseScore(cricketMatch.group(4) ?? '0'),
        status: cricketMatch.group(5)?.toLowerCase() == 'final' ? 'final' : 'live',
        sport: 'cricket',
        matchUrl: url,
      );
    }
    
    // Try football pattern
    final footballMatch = footballPattern.firstMatch(title);
    if (footballMatch != null) {
      return SportsScore(
        id: url,
        league: 'Football',
        homeTeam: footballMatch.group(1) ?? '',
        awayTeam: footballMatch.group(4) ?? '',
        homeScore: int.tryParse(footballMatch.group(2) ?? '0') ?? 0,
        awayScore: int.tryParse(footballMatch.group(3) ?? '0') ?? 0,
        status: 'final',
        sport: 'football',
        matchUrl: url,
      );
    }
    
    return null;
  }
  
  static int _parseScore(String scoreStr) {
    // Handle cricket scores like "285/3"
    if (scoreStr.contains('/')) {
      return int.tryParse(scoreStr.split('/')[0]) ?? 0;
    }
    return int.tryParse(scoreStr) ?? 0;
  }
}