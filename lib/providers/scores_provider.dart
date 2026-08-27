import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sports_score.dart';
import '../repositories/scores_repository.dart';

enum ScoresStatus { idle, loading, success, error }

class ScoresProvider extends ChangeNotifier {
  final ScoresRepository _repository = ScoresRepository();

  List<SportsScore> _liveScores = [];
  List<SportsScore> get liveScores => _liveScores;

  List<SportsScore> _cricketScores = [];
  List<SportsScore> get cricketScores => _cricketScores;

  List<SportsScore> _footballScores = [];
  List<SportsScore> get footballScores => _footballScores;

  List<SportsScore> _otherScores = [];
  List<SportsScore> get otherScores => _otherScores;

  ScoresStatus _status = ScoresStatus.idle;
  ScoresStatus get status => _status;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  Timer? _refreshTimer;
  static const _refreshInterval = Duration(minutes: 2);

  bool _isDisposed = false;

  Future<void> loadScores() async {
    if (_isDisposed) return;
    
    _status = ScoresStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final scores = await _repository.fetchLiveScores();
      
      if (_isDisposed) return;
      
      _liveScores = scores;
      _categorizeScores();
      _status = ScoresStatus.success;
    } catch (e) {
      if (_isDisposed) return;
      _status = ScoresStatus.error;
      _errorMessage = 'Failed to load live scores. Please try again.';
    }
    notifyListeners();
  }

  void _categorizeScores() {
    _cricketScores = _liveScores.where((s) => s.sport == 'cricket').toList();
    _footballScores = _liveScores.where((s) => s.sport == 'football').toList();
    _otherScores = _liveScores.where((s) => s.sport != 'cricket' && s.sport != 'football').toList();
    
    // Sort by live status first, then by start time
    for (final list in [_cricketScores, _footballScores, _otherScores, _liveScores]) {
      list.sort((a, b) {
        if (a.isLive != b.isLive) return a.isLive ? -1 : 1;
        final timeA = a.startTime?.millisecondsSinceEpoch ?? 0;
        final timeB = b.startTime?.millisecondsSinceEpoch ?? 0;
        return timeA.compareTo(timeB);
      });
    }
  }

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (!_isDisposed) {
        loadScores();
      }
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _refreshTimer?.cancel();
    super.dispose();
  }
}