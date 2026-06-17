import 'package:nasbeat/core/di/service_locator.dart';
import 'package:nasbeat/core/models/exported.dart';
import 'package:nasbeat/plugins/utils/media_id.dart';
import 'package:nasbeat/services/nasbeat_player.dart';
import 'package:nasbeat/services/db/dao/track_dao.dart';
import 'package:nasbeat/services/db/db_provider.dart';
import 'package:nasbeat/src/rust/api/plugin/commands.dart';
import 'package:nasbeat/src/rust/api/plugin/types.dart';

enum SongMetadataRefreshStatus {
  success,
  invalidMediaId,
  pluginUnavailable,
  failed,
}

class SongMetadataRefreshResult {
  final SongMetadataRefreshStatus status;
  final Track? track;

  const SongMetadataRefreshResult({required this.status, this.track});

  bool get isSuccess => status == SongMetadataRefreshStatus.success;
}

class SongMetadataRefreshService {
  SongMetadataRefreshService._();

  static Future<SongMetadataRefreshResult> refreshTrack(
    Track track, {
    NasBeatMusicPlayer? player,
  }) async {
    final parts = tryParseMediaId(track.id);
    if (parts == null) {
      return const SongMetadataRefreshResult(
        status: SongMetadataRefreshStatus.invalidMediaId,
      );
    }

    final pluginService = ServiceLocator.pluginService;
    if (!pluginService.isInitialized) {
      return const SongMetadataRefreshResult(
        status: SongMetadataRefreshStatus.pluginUnavailable,
      );
    }

    final isLoaded = await pluginService.isPluginLoaded(
      pluginId: parts.pluginId,
      pluginType: PluginType.contentResolver,
    );
    if (!isLoaded) {
      return const SongMetadataRefreshResult(
        status: SongMetadataRefreshStatus.pluginUnavailable,
      );
    }

    try {
      final response = await pluginService.execute(
        pluginId: parts.pluginId,
        request: PluginRequest.contentResolver(
          ContentResolverCommand.getTrackDetails(id: parts.localId),
        ),
      );

      if (response is! PluginResponse_TrackDetails) {
        return const SongMetadataRefreshResult(
          status: SongMetadataRefreshStatus.failed,
        );
      }

      final refreshedTrack = response.field0;
      await TrackDAO(DBProvider.db).upsertTrack(refreshedTrack);

      if (player != null) {
        await player.replaceTrackInQueue(refreshedTrack);
      }

      return SongMetadataRefreshResult(
        status: SongMetadataRefreshStatus.success,
        track: refreshedTrack,
      );
    } catch (_) {
      return const SongMetadataRefreshResult(
        status: SongMetadataRefreshStatus.failed,
      );
    }
  }
}
