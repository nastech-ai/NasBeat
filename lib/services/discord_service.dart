import 'dart:developer';
import 'dart:io';
import 'package:nasbeat/core/models/exported.dart';
import 'package:nasbeat/core/constants/sentinel_values.dart';
import 'package:dart_discord_rpc/dart_discord_rpc.dart';

class DiscordService {
  static DiscordRPC? _discordRPC;

  // Reset on every new track — keeps elapsed timer accurate per song.
  static int? _startTimeStamp;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  /// Initialises Discord RPC once at startup. Desktop-only.
  static void initialize() {
    if (!_isDesktop) return;
    try {
      DiscordRPC.initialize();
      _discordRPC = DiscordRPC(applicationId: '1516382558173270108');
      _discordRPC?.start(autoRegister: true);
      log('Discord RPC initialised — App ID 1516382558173270108',
          name: 'DiscordService');
    } catch (e) {
      log('Failed to initialise Discord RPC: $e', name: 'DiscordService');
    }
  }

  /// Call on app exit — clears presence then shuts down the connection.
  static void dispose() {
    if (!_isDesktop) return;
    try {
      _discordRPC?.clearPresence();
      _discordRPC?.shutDown();
      _discordRPC = null;
      _startTimeStamp = null;
      log('Discord RPC shut down cleanly', name: 'DiscordService');
    } catch (e) {
      log('Failed to shut down Discord RPC: $e', name: 'DiscordService');
    }
  }

  // ─── Track events ──────────────────────────────────────────────────────────

  /// Call whenever a new track starts so the elapsed timer resets per song.
  static void resetTimestamp() {
    _startTimeStamp = DateTime.now().millisecondsSinceEpoch;
  }

  // ─── Presence ──────────────────────────────────────────────────────────────

  /// Updates Rich Presence with current track + play/pause state.
  ///
  /// Art assets required in Discord Developer Portal → Rich Presence → Art Assets:
  ///   • `nasbeat_logo`  — main cover art / large image
  ///   • `nasbeat_play`  — small play icon
  ///   • `nasbeat_pause` — small pause icon
  static void updatePresence({
    required Track track,
    required bool isPlaying,
  }) {
    if (_discordRPC == null || isTrackNull(track)) return;
    try {
      final artist = track.artists.isNotEmpty
          ? track.artists.map((a) => a.name).join(', ')
          : 'Unknown Artist';

      _discordRPC!.updatePresence(
        DiscordPresence(
          details: track.title,
          state: isPlaying ? 'Playing ・ $artist' : 'Paused ・ $artist',
          largeImageKey: 'nasbeat_logo',
          largeImageText: 'NasBeat — Music for everyone',
          smallImageKey: isPlaying ? 'nasbeat_play' : 'nasbeat_pause',
          smallImageText: isPlaying ? 'Playing' : 'Paused',
          // Show elapsed timer only while playing; null hides it when paused.
          startTimeStamp: isPlaying ? _startTimeStamp : null,
        ),
      );
    } catch (e) {
      log('Discord RPC presence error: $e', name: 'DiscordService');
    }
  }

  /// Clears presence (on stop / error / queue empty).
  static void clearPresence() {
    if (!_isDesktop) return;
    try {
      _discordRPC?.clearPresence();
      log('Discord presence cleared', name: 'DiscordService');
    } catch (e) {
      log('Failed to clear Discord presence: $e', name: 'DiscordService');
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static bool get _isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}
