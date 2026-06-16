// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:nasbeat/blocs/media_player/bloomee_player_cubit.dart';
import 'package:nasbeat/core/models/exported.dart' hide MediaItem;
import 'package:nasbeat/core/adapters/track_adapter.dart';
import 'package:nasbeat/services/player/player_engine.dart';
import 'package:rxdart/rxdart.dart';

// ─── State ───────────────────────────────────────────────────────────────────

/// Visibility & playback state for the mini-player.
///
/// Intentionally simple — only 2 concrete states instead of 7.
/// The widget reads [isVisible], [isPlaying], and [isLoading] to decide layout.
class MiniPlayerState extends Equatable {
  /// The current track metadata. null → nothing loaded yet.
  final Track? track;

  /// Whether audio is actively playing.
  final bool isPlaying;

  /// Whether the engine is loading or buffering (show spinner).
  final bool isLoading;

  /// Whether the player is resolving the media URL (before engine loads).
  final bool isResolving;

  /// Whether the track has finished (show replay icon).
  final bool isCompleted;

  /// Whether the engine is in an error state.
  final bool hasError;

  /// True while the mini-player is hidden because the user scrolled down.
  final bool scrollHidden;

  const MiniPlayerState({
    this.track,
    this.isPlaying = false,
    this.isLoading = false,
    this.isResolving = false,
    this.isCompleted = false,
    this.hasError = false,
    this.scrollHidden = false,
  });

  /// Mini player is visible whenever there's a track to show.
  bool get isVisible => track != null && track!.id != 'Null' && !scrollHidden;

  const MiniPlayerState.hidden()
      : track = null,
        isPlaying = false,
        isLoading = false,
        isResolving = false,
        isCompleted = false,
        hasError = false,
        scrollHidden = false;

  MiniPlayerState copyWith({
    Track? track,
    bool? isPlaying,
    bool? isLoading,
    bool? isResolving,
    bool? isCompleted,
    bool? hasError,
    bool? scrollHidden,
  }) {
    return MiniPlayerState(
      track: track ?? this.track,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      isResolving: isResolving ?? this.isResolving,
      isCompleted: isCompleted ?? this.isCompleted,
      hasError: hasError ?? this.hasError,
      scrollHidden: scrollHidden ?? this.scrollHidden,
    );
  }

  @override
  List<Object?> get props =>
      [track, isPlaying, isLoading, isResolving, isCompleted, hasError, scrollHidden];
}

// ─── Cubit ───────────────────────────────────────────────────────────────────

/// Drives the mini-player widget.
///
/// Design principles:
/// - **Show instantly**: As soon as [mediaItem] emits a non-null track, the
///   mini-player appears — even if the engine is still loading. This gives
///   the user immediate feedback that their tap registered.
/// - **Survive resizes**: No animations or conditions based on screen size.
///   Visibility is purely data-driven ([isVisible]).
/// - **Minimal state machine**: One [MiniPlayerState] with boolean flags
///   instead of a sealed class hierarchy with 5+ subtypes.
class MiniPlayerCubit extends Cubit<MiniPlayerState> {
  final BloomeePlayerCubit _playerCubit;
  StreamSubscription? _sub;

  MiniPlayerCubit({required BloomeePlayerCubit playerCubit})
      : _playerCubit = playerCubit,
        super(const MiniPlayerState.hidden()) {
    _listen();
  }

  void _listen() {
    _sub = Rx.combineLatest4<MediaItem?, EngineState, bool, bool,
        (MediaItem?, EngineState, bool, bool)>(
      _playerCubit.bloomeePlayer.mediaItem,
      Rx.defer(() => _playerCubit.bloomeePlayer.engine.stateStream,
          reusable: true),
      Rx.defer(() => _playerCubit.bloomeePlayer.engine.playingStream,
          reusable: true),
      _playerCubit.bloomeePlayer.isResolving,
      (media, engineState, playing, resolving) =>
          (media, engineState, playing, resolving),
    ).listen((record) {
      final (media, engineState, playing, resolving) = record;

      if (media == null || media.id == 'Null') {
        if (state.isVisible) emit(const MiniPlayerState.hidden());
        return;
      }

      final track = mediaItemToTrack(media);

      emit(MiniPlayerState(
        track: track,
        isPlaying: playing,
        isLoading: engineState == EngineState.loading ||
            engineState == EngineState.buffering,
        isResolving: resolving,
        isCompleted: engineState == EngineState.completed,
        hasError: engineState == EngineState.error,
      ));
    });
  }

  /// Called by scroll listeners when the user scrolls down through content.
  void hideForScroll() {
    if (!state.scrollHidden) emit(state.copyWith(scrollHidden: true));
  }

  /// Called by scroll listeners when the user scrolls back up.
  void revealAfterScroll() {
    if (state.scrollHidden) emit(state.copyWith(scrollHidden: false));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
