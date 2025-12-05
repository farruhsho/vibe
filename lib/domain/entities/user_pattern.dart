/// User Pattern entity for personalized recommendations
///
/// This entity represents a user's music listening preferences
/// derived from their listening history analysis.

import 'package:equatable/equatable.dart';

/// User's music preference pattern based on listening history
class UserPattern extends Equatable {
  /// User ID
  final String userId;

  /// Average energy level preferred (0.0-1.0)
  final double avgEnergy;

  /// Average valence (mood positivity) preferred (0.0-1.0)
  final double avgValence;

  /// Average danceability preferred (0.0-1.0)
  final double avgDanceability;

  /// Average tempo preferred (BPM)
  final double avgTempo;

  /// Average acousticness preferred (0.0-1.0)
  final double avgAcousticness;

  /// Average instrumentalness preferred (0.0-1.0)
  final double avgInstrumentalness;

  /// Average speechiness preferred (0.0-1.0)
  final double avgSpeechiness;

  /// Standard deviation of energy (shows preference variance)
  final double energyStdDev;

  /// Standard deviation of valence
  final double valenceStdDev;

  /// Standard deviation of danceability
  final double danceabilityStdDev;

  /// Standard deviation of tempo (in BPM, normalized 0-1)
  final double tempoStdDev;

  /// Number of tracks analyzed to build this pattern
  final int totalTracksAnalyzed;

  /// When this pattern was last updated
  final DateTime lastUpdated;

  /// Time-of-day preferences (hour: preference factor)
  /// Maps 6 periods (0-5) to energy/valence preferences
  final Map<String, TimeOfDayPreference>? timeOfDayPreferences;

  /// Genre preferences (genre: play count)
  final Map<String, int>? genrePreferences;

  /// Day-of-week preferences
  final Map<int, DayOfWeekPreference>? dayOfWeekPreferences;

  const UserPattern({
    required this.userId,
    required this.avgEnergy,
    required this.avgValence,
    required this.avgDanceability,
    required this.avgTempo,
    this.avgAcousticness = 0.0,
    this.avgInstrumentalness = 0.0,
    this.avgSpeechiness = 0.0,
    this.energyStdDev = 0.0,
    this.valenceStdDev = 0.0,
    this.danceabilityStdDev = 0.0,
    this.tempoStdDev = 0.0,
    required this.totalTracksAnalyzed,
    required this.lastUpdated,
    this.timeOfDayPreferences,
    this.genrePreferences,
    this.dayOfWeekPreferences,
  });

  /// Pattern strength (0.0-1.0)
  /// Lower standard deviation means stronger, more consistent preferences
  double get patternStrength {
    final avgStdDev = (energyStdDev + valenceStdDev + danceabilityStdDev) / 3.0;
    return (1.0 - avgStdDev).clamp(0.0, 1.0);
  }

  /// Whether this pattern has enough data to be reliable
  /// Requires at least 10 tracks for meaningful analysis
  bool get isReliable => totalTracksAnalyzed >= 10;

  /// Whether pattern is stale (older than 7 days)
  bool get isStale => DateTime.now().difference(lastUpdated).inDays > 7;

  /// Pattern confidence level based on sample size
  /// Returns: 'low', 'medium', 'high'
  String get confidenceLevel {
    if (totalTracksAnalyzed >= 50) return 'high';
    if (totalTracksAnalyzed >= 20) return 'medium';
    return 'low';
  }

  /// Numerical confidence (0.0-1.0) based on sample size
  double get confidence {
    // Sigmoid function that approaches 1.0 as track count increases
    // Half-max at 25 tracks, 90% at 50 tracks
    return 1.0 - (1.0 / (1.0 + (totalTracksAnalyzed / 25.0)));
  }

  /// Get energy preference for current time of day
  double? getEnergyForTime(DateTime time) {
    if (timeOfDayPreferences == null) return null;
    final period = (time.hour ~/ 4).toString();
    return timeOfDayPreferences![period]?.avgEnergy;
  }

  /// Get valence preference for current time of day
  double? getValenceForTime(DateTime time) {
    if (timeOfDayPreferences == null) return null;
    final period = (time.hour ~/ 4).toString();
    return timeOfDayPreferences![period]?.avgValence;
  }

  /// Create a copy with updated fields
  UserPattern copyWith({
    String? userId,
    double? avgEnergy,
    double? avgValence,
    double? avgDanceability,
    double? avgTempo,
    double? avgAcousticness,
    double? avgInstrumentalness,
    double? avgSpeechiness,
    double? energyStdDev,
    double? valenceStdDev,
    double? danceabilityStdDev,
    double? tempoStdDev,
    int? totalTracksAnalyzed,
    DateTime? lastUpdated,
    Map<String, TimeOfDayPreference>? timeOfDayPreferences,
    Map<String, int>? genrePreferences,
    Map<int, DayOfWeekPreference>? dayOfWeekPreferences,
  }) {
    return UserPattern(
      userId: userId ?? this.userId,
      avgEnergy: avgEnergy ?? this.avgEnergy,
      avgValence: avgValence ?? this.avgValence,
      avgDanceability: avgDanceability ?? this.avgDanceability,
      avgTempo: avgTempo ?? this.avgTempo,
      avgAcousticness: avgAcousticness ?? this.avgAcousticness,
      avgInstrumentalness: avgInstrumentalness ?? this.avgInstrumentalness,
      avgSpeechiness: avgSpeechiness ?? this.avgSpeechiness,
      energyStdDev: energyStdDev ?? this.energyStdDev,
      valenceStdDev: valenceStdDev ?? this.valenceStdDev,
      danceabilityStdDev: danceabilityStdDev ?? this.danceabilityStdDev,
      tempoStdDev: tempoStdDev ?? this.tempoStdDev,
      totalTracksAnalyzed: totalTracksAnalyzed ?? this.totalTracksAnalyzed,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      timeOfDayPreferences: timeOfDayPreferences ?? this.timeOfDayPreferences,
      genrePreferences: genrePreferences ?? this.genrePreferences,
      dayOfWeekPreferences: dayOfWeekPreferences ?? this.dayOfWeekPreferences,
    );
  }

  @override
  List<Object?> get props => [
        userId, avgEnergy, avgValence, avgDanceability, avgTempo,
        avgAcousticness, avgInstrumentalness, avgSpeechiness,
        energyStdDev, valenceStdDev, danceabilityStdDev, tempoStdDev,
        totalTracksAnalyzed, lastUpdated,
      ];

  @override
  String toString() =>
      'UserPattern(energy: ${avgEnergy.toStringAsFixed(2)}, '
      'valence: ${avgValence.toStringAsFixed(2)}, '
      'danceability: ${avgDanceability.toStringAsFixed(2)}, '
      'tempo: ${avgTempo.toStringAsFixed(0)}, '
      'tracks: $totalTracksAnalyzed, '
      'strength: ${(patternStrength * 100).toStringAsFixed(0)}%)';
}

/// Time of day preference for a specific period
class TimeOfDayPreference extends Equatable {
  /// Period (0-5, each representing 4 hours)
  final int period;

  /// Average energy for this time period
  final double avgEnergy;

  /// Average valence for this time period
  final double avgValence;

  /// Number of tracks played during this period
  final int trackCount;

  const TimeOfDayPreference({
    required this.period,
    required this.avgEnergy,
    required this.avgValence,
    required this.trackCount,
  });

  /// Period name for display
  String get periodName {
    switch (period) {
      case 0: return 'Late Night (00:00-04:00)';
      case 1: return 'Early Morning (04:00-08:00)';
      case 2: return 'Morning (08:00-12:00)';
      case 3: return 'Afternoon (12:00-16:00)';
      case 4: return 'Evening (16:00-20:00)';
      case 5: return 'Night (20:00-24:00)';
      default: return 'Unknown';
    }
  }

  @override
  List<Object?> get props => [period, avgEnergy, avgValence, trackCount];
}

/// Day of week preference
class DayOfWeekPreference extends Equatable {
  /// Day of week (1=Monday, 7=Sunday)
  final int dayOfWeek;

  /// Average energy for this day
  final double avgEnergy;

  /// Average valence for this day
  final double avgValence;

  /// Number of tracks played on this day
  final int trackCount;

  const DayOfWeekPreference({
    required this.dayOfWeek,
    required this.avgEnergy,
    required this.avgValence,
    required this.trackCount,
  });

  /// Day name for display
  String get dayName {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return dayOfWeek >= 1 && dayOfWeek <= 7 ? days[dayOfWeek - 1] : 'Unknown';
  }

  @override
  List<Object?> get props => [dayOfWeek, avgEnergy, avgValence, trackCount];
}
