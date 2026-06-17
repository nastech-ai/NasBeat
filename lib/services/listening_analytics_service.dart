import 'dart:async';
import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:hive/hive.dart';

/// Tracks listening history in real-time and exposes genre/artist affinity.
///
/// Wire up once the player is ready:
/// ```dart
/// await ListeningAnalyticsService.instance.init(playerMediaItemStream);
/// ```
///
/// On every track change (= previous track was played), the service increments
/// play-count for each genre tag and artist in the previous track's metadata.
/// Affinity is persisted in Hive so it survives app restarts.
///
/// Consumers call [getTopGenres] / [getTopArtists] or listen to
/// [genreAffinityStream] for live updates.
class ListeningAnalyticsService {
  ListeningAnalyticsService._();
  static final ListeningAnalyticsService instance =
      ListeningAnalyticsService._();

  static const String _boxName = 'nasbeat_listening_analytics';
  static const String _genreKey = 'genre_affinity';
  static const String _artistKey = 'artist_affinity';

  Box? _box;
  StreamSubscription<MediaItem?>? _mediaSub;

  final _genreController = StreamController<List<String>>.broadcast();

  /// Emits the top 5 genre tags whenever a track is recorded.
  Stream<List<String>> get genreAffinityStream => _genreController.stream;

  bool get isInitialized => _box != null;

  // ── Initialise ──────────────────────────────────────────────────────────────

  Future<void> init(Stream<MediaItem?> mediaItemStream) async {
    if (_box != null) return;
    _box = await Hive.openBox(_boxName);
    _listenToTrackChanges(mediaItemStream);
    log('ListeningAnalyticsService initialized', name: 'Analytics');
  }

  // ── Track completion detection ───────────────────────────────────────────────

  void _listenToTrackChanges(Stream<MediaItem?> stream) {
    MediaItem? _previous;
    _mediaSub = stream.listen((current) {
      if (current == null) return;
      if (_previous != null && _previous!.id != current.id) {
        _recordPlay(_previous!);
      }
      _previous = current;
    });
  }

  // ── Recording ───────────────────────────────────────────────────────────────

  void _recordPlay(MediaItem item) {
    final genreAffinity = _loadMap(_genreKey);
    final artistAffinity = _loadMap(_artistKey);

    // Genre tags
    final genreStr = item.genre ?? '';
    final genres = genreStr
        .split(RegExp(r'[,/|;]'))
        .map((g) => g.trim().toLowerCase())
        .where((g) => g.isNotEmpty && g.length > 1)
        .toList();

    for (final genre in genres) {
      genreAffinity[genre] = (genreAffinity[genre] ?? 0) + 1;
    }

    // Artist affinity
    final artist = (item.artist ?? '').trim().toLowerCase();
    if (artist.isNotEmpty) {
      artistAffinity[artist] = (artistAffinity[artist] ?? 0) + 1;
    }

    _saveMap(_genreKey, genreAffinity);
    _saveMap(_artistKey, artistAffinity);

    final top = _topKeys(genreAffinity, 5);
    _genreController.add(top);
    log('Recorded play: ${item.title} | genres: $genres | artist: $artist',
        name: 'Analytics');
  }

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Returns top [limit] genre tags sorted by play count.
  List<String> getTopGenres({int limit = 5}) {
    return _topKeys(_loadMap(_genreKey), limit);
  }

  /// Returns top [limit] artists sorted by play count.
  List<String> getTopArtists({int limit = 5}) {
    return _topKeys(_loadMap(_artistKey), limit);
  }

  /// Returns total number of unique tracks recorded.
  int get totalPlays {
    final map = _loadMap(_genreKey);
    return map.values.fold(0, (a, b) => a + b);
  }

  /// Clears all stored analytics data.
  Future<void> clearHistory() async {
    await _box?.delete(_genreKey);
    await _box?.delete(_artistKey);
    _genreController.add([]);
    log('Analytics history cleared', name: 'Analytics');
  }

  // ── Persistence helpers ──────────────────────────────────────────────────────

  Map<String, int> _loadMap(String key) {
    final raw = _box?.get(key);
    if (raw == null) return {};
    return Map<String, int>.from(raw as Map);
  }

  void _saveMap(String key, Map<String, int> data) {
    _box?.put(key, data);
  }

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
    await _box?.close();
    _box = null;
  }
}
