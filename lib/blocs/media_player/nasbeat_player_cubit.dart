import 'package:nasbeat/services/nasbeat_player.dart';
import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';
part 'nasbeat_player_state.dart';

class NasBeatPlayerCubit extends Cubit<NasBeatPlayerState> {
  final NasBeatMusicPlayer nasbeatPlayer;
  late ValueStream<ProgressBarStreams> progressStreams;

  NasBeatPlayerCubit(this.nasbeatPlayer)
      : super(NasBeatPlayerState(isReady: true)) {
    nasbeatPlayer.syncPublicState();
    _setupProgressStreams();
  }

  void switchShowLyrics({bool? value}) {
    emit(NasBeatPlayerState(
        isReady: true, showLyrics: value ?? !state.showLyrics));
  }

  void _setupProgressStreams() {
    progressStreams = Rx.combineLatest4(
      Rx.defer(() => nasbeatPlayer.engine.positionStream, reusable: true),
      Rx.defer(() => nasbeatPlayer.engine.durationStream, reusable: true),
      Rx.defer(() => nasbeatPlayer.engine.bufferedStream, reusable: true),
      Rx.defer(() => nasbeatPlayer.engine.playingStream, reusable: true),
      (Duration position, Duration duration, Duration buffered, bool playing) =>
          ProgressBarStreams(
        position: position,
        duration: duration,
        buffered: buffered,
        isPlaying: playing,
      ),
    ).shareValueSeeded(
      ProgressBarStreams(
        position: Duration.zero,
        duration: Duration.zero,
        buffered: Duration.zero,
        isPlaying: false,
      ),
    );
  }

  @override
  Future<void> close() {
    // Intentionally does NOT stop the player.
    // The AudioService foreground service manages its own lifecycle via
    // onTaskRemoved() / onNotificationDeleted().
    return super.close();
  }
}
