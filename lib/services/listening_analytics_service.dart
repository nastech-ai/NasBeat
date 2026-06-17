import 'dart:async';
import 'dart:developer';

import 'package:audio_service/audio_service.dart';

/// Tracks listening history in real-time and exposes genre/artist affinity.
///
/// Wire up once the player is ready:
/// ```dart
/// await ListeningAnalyticsService.instance.init(playerMediaItemStream);
/// ```
///
/// On every track change (= previous track was played), the service increments
/// play-count for each genre tag and artist in the previous track's metadata.
/// Affinity is held in-memory for the session lifetime.
///
/// Consumers call [getTopGenres] / [getTopArtists] or listen to
/// [genreAffinityStream] for live updates.
class ListeningAnalyticsService {
  ListeningAnalyticsService._();
  static final ListeningAnalyticsService instance =
      ListeningAnalyticsService._();

  StreamSubscription<MediaItem?>? _mediaSub;
  bool _initialized = false;

  final Map<String, int> _genreAffinity = {};
  final Map<String, int> _artistAffinity = {};

  final _genreController = StreamController<List<String>>.broadcast();

  /// Emits the top 5 genre tags whenever a track is recorded.
  Stream<List<String>> get genreAffinityStream => _genreController.stream;

  bool get isInitialized => _initialized;

  // ── Initialise ──────────────────────────────────────────────────────────────

  Future<void> init(Stream<MediaItem?> mediaItemStream) async {
    if (_initialized) return;
    _initialized = true;
    _listenToTrackChanges(mediaItemStream);
    log('ListeningAnalyticsService initialized', name: 'Analytics');
  }

  // ── Track completion detection ───────────────────────────────────────────────

  void _listenToTrackChanges(Stream<MediaItem?> stream) {
    MediaItem? previous;
    _mediaSub = stream.listen((current) {
      if (current == null) return;
      if (previous != null && previous!.id != current.id) {
        _recordPlay(previous!);
      }
      previous = current;
    });
  }

  // ── Recording ───────────────────────────────────────────────────────────────

  void _recordPlay(MediaItem item) {
    // Genre tags
    final genreStr = item.genre ?? '';
    final genres = genreStr
        .split(RegExp(r'[,/|;]'))
        .map((g) => g.trim().toLowerCase())
        .where((g) => g.isNotEmpty && g.length > 1)
        .toList();

    for (final genre in genres) {
      _genreAffinity[genre] = (_genreAffinity[genre] ?? 0) + 1;
    }

    // Artist affinity
    final artist = (item.artist ?? '').trim().toLowerCase();
    if (artist.isNotEmpty) {
      _artistAffinity[artist] = (_artistAffinity[artist] ?? 0) + 1;
    }

    final top = _topKeys(_genreAffinity, 5);
    _genreController.add(top);
    log('Recorded play: ${item.title} | genres: $genres | artist: $artist',
        name: 'Analytics');
  }

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Returns top [limit] genre tags sorted by play count.
  List<String> getTopGenres({int limit = 5}) =>
      _topKeys(_genreAffinity, limit);

  /// Returns top [limit] artists sorted by play count.
  List<String> getTopArtists({int limit = 5}) =>
      _topKeys(_artistAffinity, limit);

  /// Returns total number of play events recorded this session.
  int get totalPlays =>
      _genreAffinity.values.fold(0, (a, b) => a + b);

  /// Clears all stored analytics data.
  Future<void> clearHistory() async {
    _genreAffinity.clear();
    _artistAffinity.clear();
    _genreController.add([]);
    log('Analytics history cleared', name: 'Analytics');
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  List<String> _topKeys(Map<String, int> map, int limit) {
    if (map.isEmpty) return [];
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    await _mediaSub?.cancel();
    await _genreController.close();
    _initialized = false;
  }
}
