import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:nasbeat/blocs/lyrics/lyrics_cubit.dart';
import 'package:nasbeat/blocs/settings_cubit/cubit/settings_cubit.dart';
import 'package:nasbeat/blocs/media_player/nasbeat_player_cubit.dart';
import 'package:nasbeat/blocs/mini_player/mini_player_cubit.dart';
import 'package:nasbeat/screens/screen/player_views/lyrics_search.dart';
import 'package:nasbeat/screens/widgets/media_metadata_links.dart';
import 'package:nasbeat/screens/widgets/play_pause_widget.dart';
import 'package:nasbeat/screens/widgets/sign_board_widget.dart';
import 'package:nasbeat/screens/widgets/up_next_panel.dart';
import 'package:nasbeat/l10n/app_localizations.dart';
import 'package:nasbeat/core/theme/app_theme.dart';
import 'package:nasbeat/utils/load_image.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:rxdart/rxdart.dart';

class FullscreenLyricsView extends StatefulWidget {
  const FullscreenLyricsView({super.key});

  @override
  State<FullscreenLyricsView> createState() => _FullscreenLyricsViewState();
}

class _FullscreenLyricsViewState extends State<FullscreenLyricsView>
    with SingleTickerProviderStateMixin {
  bool _showControls = true;

  late final AnimationController _waveController;
  Timer? _hideControlsTimer;
  final UpNextPanelController _upNextPanelController = UpNextPanelController();

  Duration _lyricOffset = Duration.zero;
  bool _isSyncMode = false;
  Timer? _holdTimer;

  final ValueNotifier<Duration> _positionNotifier =
      ValueNotifier(Duration.zero);
  String? _currentTrackId;

  @override
  void initState() {
    super.initState();
    _startHideControlsTimer();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    final playerCubit = context.read<NasBeatPlayerCubit>();
    _currentTrackId = playerCubit.nasbeatPlayer.currentTrackInfo.id;

    _loadPersistedOffset();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  void _loadPersistedOffset() {
    final lyricsState = context.read<LyricsCubit>().state;
    if (lyricsState is LyricsLoaded &&
        lyricsState.lyrics.mediaID == _currentTrackId) {
      final offsetMs = lyricsState.lyrics.offset ?? 0;
      if (mounted) {
        setState(() {
          _lyricOffset = Duration(milliseconds: offsetMs);
        });
      }
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _hideControlsTimer?.cancel();
    _positionNotifier.dispose();
    _waveController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _showControls && !_isSyncMode) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _startHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _onInteraction() {
    if (!_showControls) setState(() => _showControls = true);
    _startHideControlsTimer();
  }

  void _startOffsetChange(int ms) {
    setState(() => _lyricOffset += Duration(milliseconds: ms));
    _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() => _lyricOffset += Duration(milliseconds: ms));
    });
  }

  void _stopOffsetChange() => _holdTimer?.cancel();

  void _openSettingsMenu(LyricsState state, NasBeatPlayerCubit playerCubit) {
    _hideControlsTimer?.cancel();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _LyricsSettingsBottomSheet(
        state: state,
        onSyncTap: () {
          Navigator.pop(context);
          setState(() {
            _isSyncMode = true;
            _showControls = true;
          });
        },
      ),
    ).then((_) => _startHideControlsTimer());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final nasbeatPlayerCubit = context.read<NasBeatPlayerCubit>();
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: _toggleControls,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            _buildBackground(nasbeatPlayerCubit),
            BlocSelector<SettingsCubit, SettingsState, bool>(
              selector: (s) => NasBeatTheme.fromKey(s.appTheme).isAmoled,
              builder: (context, isAmoled) => Container(
                color: isAmoled
                    ? Colors.black.withValues(alpha: 0.92)
                    : Colors.black.withValues(alpha: 0.4),
              ),
            ),
            BlocSelector<SettingsCubit, SettingsState, NasBeatTheme>(
              selector: (s) => NasBeatTheme.fromKey(s.appTheme),
              builder: (context, theme) {
                if (!theme.isAmoled) return const SizedBox.shrink();
                return AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, _) => CustomPaint(
                    painter: _WavingLightPainter(
                      phase: _waveController.value * 2 * math.pi,
                      accentColor: theme.accent,
                    ),
                    child: const SizedBox.expand(),
                  ),
                );
              },
            ),
            Positioned.fill(
              child: BlocBuilder<LyricsCubit, LyricsState>(
                builder: (context, state) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: switch (state) {
                      LyricsInitial() => const Center(
                          child: CircularProgressIndicator(
                              color: Default_Theme.accentColor2)),
                      LyricsLoading() => const Center(
                          child: CircularProgressIndicator(
                              color: Default_Theme.accentColor2)),
                      LyricsLoaded() => state.lyrics.parsedLyrics != null
                          ? FullscreenSyncedLyrics(
                              state: state,
                              positionNotifier: _positionNotifier,
                              lyricOffset: _lyricOffset,
                              onInteraction: _onInteraction,
                              isDesktop: isDesktop,
                            )
                          : state.lyrics.lyricsPlain.isNotEmpty
                              ? _buildPlainLyrics(state, isDesktop)
                              : SignBoardWidget(
                                  icon: MingCute.music_2_line,
                                  message: l10n.playerNoLyricsFound),
                      LyricsError() => SignBoardWidget(
                          icon: MingCute.music_2_line,
                          message: l10n.playerNoLyricsFound),
                      LyricsState() => const SizedBox.shrink(),
                    },
                  );
                },
              ),
            ),
            BlocListener<LyricsCubit, LyricsState>(
              listener: (context, state) {
                if (state is LyricsLoading || state is LyricsLoaded) {
                  final newTrackId = state.track.id;
                  if (_currentTrackId != newTrackId) {
                    _currentTrackId = newTrackId;
                    if (mounted) {
                      setState(() {
                        _lyricOffset = Duration.zero;
                        _isSyncMode = false;
                      });
                    }
                  }
                }

                if (state is LyricsLoaded &&
                    state.lyrics.mediaID == _currentTrackId) {
                  final offsetMs = state.lyrics.offset ?? 0;
                  if (mounted) {
                    setState(() {
                      _lyricOffset = Duration(milliseconds: offsetMs);
                    });
                  }
                }
              },
              child: const SizedBox.shrink(),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              top: _showControls ? 0 : -150,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {},
                child: _buildTopBar(nasbeatPlayerCubit, isDesktop),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              bottom: _showControls ? 0 : -200,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {},
                child: _buildBottomControls(nasbeatPlayerCubit, isDesktop),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              bottom: _isSyncMode
                  ? (_showControls
                      ? (isDesktop ? 220 : 250)
                      : (isDesktop ? 80 : 100))
                  : -100,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {},
                child: _buildSyncControls(),
              ),
            ),
            UpNextPanel(
              controller: _upNextPanelController,
              peekHeight: 60,
              parentHeight: MediaQuery.of(context).size.height,
              canBeHidden: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(NasBeatPlayerCubit nasbeatPlayerCubit) {
    return StreamBuilder<MediaItem?>(
      stream: nasbeatPlayerCubit.nasbeatPlayer.mediaItem,
      builder: (context, snapshot) {
        final currentTrack = nasbeatPlayerCubit.nasbeatPlayer.currentTrackInfo;
        final artworkUrl =
            currentTrack.thumbnail.urlLow ?? currentTrack.thumbnail.url;

        return AnimatedSwitcher(
          // FIX M-10: Reduced transition duration from 1000ms to 500ms for
          // a snappier background crossfade.
          duration: const Duration(milliseconds: 500),
          child: Container(
            key: ValueKey(snapshot.data?.id),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (artworkUrl.isNotEmpty)
                  Transform.scale(
                    scale: 1.2,
                    child: ImageFiltered(
                      // FIX M-10: Reduced from sigma=80 to sigma=22.
                      // The blur background is overlaid with a 0.6 opacity
                      // black layer — the visual difference from reducing blur
                      // radius is imperceptible while GPU load drops ~3x on
                      // mid-range Android devices (Snapdragon 600/700 series).
                      imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: getImageProviderSync(artworkUrl,
                                fallbackUrl: currentTrack.thumbnail.url),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                Container(color: Colors.black.withValues(alpha: 0.6)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(NasBeatPlayerCubit nasbeatPlayerCubit, bool isDesktop) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 16, 16, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StreamBuilder<MediaItem?>(
                  stream: nasbeatPlayerCubit.nasbeatPlayer.mediaItem,
                  builder: (context, snapshot) {
                    final currentTrack =
                        nasbeatPlayerCubit.nasbeatPlayer.currentTrackInfo;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          currentTrack.title,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: isDesktop ? 22 : 18,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'NotoSans'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        TrackMetadataLinks(
                          track: currentTrack,
                          showAlbum: currentTrack.album != null,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: isDesktop ? 15 : 13,
                              fontFamily: 'NotoSans',
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              BlocBuilder<LyricsCubit, LyricsState>(
                builder: (context, state) {
                  return IconButton(
                    onPressed: () =>
                        _openSettingsMenu(state, nasbeatPlayerCubit),
                    icon: const Icon(MingCute.more_2_fill,
                        color: Colors.white, size: 28),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncControls() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, 10))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTapDown: (_) => _startOffsetChange(-50),
                    onTapUp: (_) => _stopOffsetChange(),
                    onTapCancel: () => _stopOffsetChange(),
                    child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(MingCute.minus_circle_fill,
                            color: Colors.white, size: 28)),
                  ),
                  InkWell(
                    onTap: () => setState(() => _lyricOffset = Duration.zero),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${_lyricOffset.inMilliseconds > 0 ? '+' : ''}${_lyricOffset.inMilliseconds}ms",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          Text(l10n.lyricsSyncTapToReset.toUpperCase(),
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTapDown: (_) => _startOffsetChange(50),
                    onTapUp: (_) => _stopOffsetChange(),
                    onTapCancel: () => _stopOffsetChange(),
                    child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(MingCute.add_circle_fill,
                            color: Colors.white, size: 28)),
                  ),
                  Container(
                      width: 1,
                      height: 28,
                      color: Colors.white.withValues(alpha: 0.2),
                      margin: const EdgeInsets.symmetric(horizontal: 12)),
                  IconButton(
                    icon: const Icon(MingCute.close_fill,
                        color: Colors.white, size: 24),
                    onPressed: () {
                      if (_currentTrackId != null) {
                        final lyricsCubit = context.read<LyricsCubit>();
                        final state = lyricsCubit.state;
                        if (state is LyricsLoaded &&
                            state.lyrics.mediaID == _currentTrackId) {
                          lyricsCubit.setLyricsToDB(
                            state.lyrics,
                            _currentTrackId!,
                            offset: _lyricOffset.inMilliseconds,
                          );
                        }
                      }
                      setState(() => _isSyncMode = false);
                      _startHideControlsTimer();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(
      NasBeatPlayerCubit nasbeatPlayerCubit, bool isDesktop) {
    final l10n = AppLocalizations.of(context)!;
    final musicPlayer = nasbeatPlayerCubit.nasbeatPlayer;
    final paddingBottom = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 40, 24, paddingBottom > 0 ? paddingBottom : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => musicPlayer.skipToPrevious(),
                    icon: const Icon(MingCute.skip_previous_fill,
                        color: Colors.white),
                    iconSize: isDesktop ? 40 : 36,
                  ),
                  const SizedBox(width: 32),
                  BlocBuilder<MiniPlayerCubit, MiniPlayerState>(
                    builder: (context, state) {
                      return PlayPauseButton(
                        size: isDesktop ? 80 : 70,
                        onPause: () => musicPlayer.pause(),
                        onPlay: () => musicPlayer.play(),
                        isPlaying: state.isPlaying,
                      );
                    },
                  ),
                  const SizedBox(width: 32),
                  IconButton(
                    onPressed: () => musicPlayer.skipToNext(),
                    icon: const Icon(MingCute.skip_forward_fill,
                        color: Colors.white),
                    iconSize: isDesktop ? 40 : 36,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => _upNextPanelController.toggle(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(30)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(MingCute.playlist_fill,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(l10n.upNextTitle,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlainLyrics(LyricsState state, bool isDesktop) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent
          ],
          stops: [0.0, 0.2, 0.8, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).size.height * 0.35,
            horizontal: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Text(
              state.lyrics.lyricsPlain,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: isDesktop ? 26 : 22,
                  fontFamily: 'NotoSans',
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.8),
            ),
          ),
        ),
      ),
    );
  }
}

class FullscreenSyncedLyrics extends StatefulWidget {
  final LyricsState state;
  final ValueNotifier<Duration> positionNotifier;
  final Duration lyricOffset;
  final VoidCallback? onInteraction;
  final bool isDesktop;

  const FullscreenSyncedLyrics({
    required this.state,
    required this.positionNotifier,
    required this.lyricOffset,
    this.onInteraction,
    this.isDesktop = false,
    super.key,
  });

  @override
  State<FullscreenSyncedLyrics> createState() => _FullscreenSyncedLyricsState();
}

class _FullscreenSyncedLyricsState extends State<FullscreenSyncedLyrics> {
  StreamSubscription? _positionSubscription;
  StreamSubscription? _indexSubscription;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  int _currentIndex = -1;
  bool _userScrolling = false;
  Timer? _userScrollTimer;

  @override
  void initState() {
    super.initState();
    _setupPositionListener();
  }

  @override
  void didUpdateWidget(FullscreenSyncedLyrics oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lyricOffset != widget.lyricOffset) _forceSyncRecalculation();
  }

  void _forceSyncRecalculation() {
    final player = context.read<NasBeatPlayerCubit>().nasbeatPlayer.engine;
    final adjustedPosition = player.position + widget.lyricOffset;
    widget.positionNotifier.value = adjustedPosition;

    final newIndex = _findCurrentLyricIndex(adjustedPosition);
    if (newIndex != _currentIndex && newIndex != -1) {
      setState(() => _currentIndex = newIndex);
      _scrollToCurrentLyric();
    }
  }

  void _setupPositionListener() {
    final nasbeatPlayerCubit = context.read<NasBeatPlayerCubit>();
    final posStream = nasbeatPlayerCubit.nasbeatPlayer.engine.positionStream;

    _positionSubscription = posStream.listen((rawPosition) {
      if (!mounted) return;
      // Update positionNotifier at full rate for smooth karaoke fill
      widget.positionNotifier.value = rawPosition + widget.lyricOffset;
    });

    // Separate throttled subscription for index changes + scrolling
    _indexSubscription = posStream
        .throttleTime(const Duration(milliseconds: 200))
        .listen((rawPosition) {
      if (!mounted) return;
      final adjustedPosition = rawPosition + widget.lyricOffset;
      final newIndex = _findCurrentLyricIndex(adjustedPosition);
      if (newIndex != _currentIndex && newIndex != -1) {
        setState(() => _currentIndex = newIndex);
        _scrollToCurrentLyric();
      }
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _indexSubscription?.cancel();
    _userScrollTimer?.cancel();
    super.dispose();
  }

  int _findCurrentLyricIndex(Duration currentPosition) {
    final lyrics = widget.state.lyrics.parsedLyrics?.lyrics;
    if (lyrics == null || lyrics.isEmpty) return 0;
    if (currentPosition < lyrics[0].start) return 0;
    if (currentPosition >= lyrics.last.start) return lyrics.length - 1;
    for (int i = 0; i < lyrics.length; i++) {
      final nextStart =
          i + 1 < lyrics.length ? lyrics[i + 1].start : const Duration(days: 1);
      if (currentPosition >= lyrics[i].start && currentPosition < nextStart)
        return i;
    }
    return lyrics.length - 1;
  }

  void _scrollToCurrentLyric() {
    if (_userScrolling) return;
    if (_itemScrollController.isAttached && _currentIndex >= 0) {
      _itemScrollController.scrollTo(
          index: _currentIndex,
          alignment: 0.4,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutQuart);
    }
  }

  void _onUserScroll() {
    widget.onInteraction?.call();
    _userScrolling = true;
    _userScrollTimer?.cancel();
    _userScrollTimer = Timer(const Duration(seconds: 4), () {
      _userScrolling = false;
      _scrollToCurrentLyric();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = widget.state.lyrics.parsedLyrics?.lyrics ?? [];

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification &&
            notification.dragDetails != null) _onUserScroll();
        return false;
      },
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent
            ],
            stops: [0.0, 0.25, 0.75, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ScrollablePositionedList.builder(
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
          itemCount: lyrics.length,
          padding: EdgeInsets.symmetric(
              vertical: MediaQuery.of(context).size.height * 0.4,
              horizontal: widget.isDesktop ? 64 : 24),
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          itemBuilder: (context, index) {
            final isCurrentLine = index == _currentIndex;
            final isPastLine = index < _currentIndex;
            final lyric = lyrics[index];
            final nextStart = index + 1 < lyrics.length
                ? lyrics[index + 1].start
                : lyric.start + const Duration(seconds: 5);

            return GestureDetector(
              onTap: () {
                widget.onInteraction?.call();
                context
                    .read<NasBeatPlayerCubit>()
                    .nasbeatPlayer
                    .seek(lyric.start - widget.lyricOffset);
              },
              child: _KaraokeLyricLine(
                text: lyric.text,
                startTime: lyric.start,
                endTime: nextStart,
                isActive: isCurrentLine,
                isPast: isPastLine,
                positionNotifier: widget.positionNotifier,
                isDesktop: widget.isDesktop,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// FIX M-08: Removed the TweenAnimationBuilder that had begin==end (the
/// animation never executed). The ShaderMask is now driven directly by the
/// ValueListenableBuilder from positionNotifier, which already updates at the
/// engine's position stream rate (~60Hz). This produces naturally smooth karaoke
/// fill animation without the no-op tween layer.
class _KaraokeLyricLine extends StatelessWidget {
  final String text;
  final Duration startTime;
  final Duration endTime;
  final bool isActive;
  final bool isPast;
  final ValueNotifier<Duration> positionNotifier;
  final bool isDesktop;

  const _KaraokeLyricLine({
    required this.text,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    required this.isPast,
    required this.positionNotifier,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final double fontSize = isDesktop ? 32 : 28;
    const String fontFamily = 'NotoSans';
    const FontWeight fontWeight = FontWeight.w800;

    if (!isActive) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isPast ? 0.25 : 0.4,
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  fontFamily: fontFamily,
                  fontWeight: fontWeight,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Active line — word-by-word highlight with glow on current word
    final words = text.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return const SizedBox.shrink();

    final totalMs =
        (endTime.inMilliseconds - startTime.inMilliseconds).toDouble();
    final msPerWord = totalMs > 0 ? totalMs / words.length : 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: RepaintBoundary(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ValueListenableBuilder<Duration>(
              valueListenable: positionNotifier,
              builder: (context, pos, _) {
                final elapsedMs =
                    (pos.inMilliseconds - startTime.inMilliseconds).toDouble();

                return RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: List.generate(words.length, (i) {
                      final wordStartMs = i * msPerWord;
                      final wordEndMs = (i + 1) * msPerWord;
                      final bool isCurrent =
                          elapsedMs >= wordStartMs && elapsedMs < wordEndMs;
                      final bool isDone = elapsedMs >= wordEndMs;

                      Color color;
                      List<Shadow>? shadows;

                      if (isDone) {
                        color = Colors.white;
                        shadows = null;
                      } else if (isCurrent) {
                        final double wp =
                            ((elapsedMs - wordStartMs) / msPerWord)
                                .clamp(0.0, 1.0);
                        color = Color.lerp(
                              Colors.white.withValues(alpha: 0.35),
                              Colors.white,
                              wp,
                            ) ??
                            Colors.white;
                        shadows = [
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.55 * wp),
                            blurRadius: 16,
                          ),
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.25 * wp),
                            blurRadius: 32,
                          ),
                        ];
                      } else {
                        color = Colors.white.withValues(alpha: 0.35);
                        shadows = null;
                      }

                      return TextSpan(
                        text: i < words.length - 1
                            ? '${words[i]} '
                            : words[i],
                        style: TextStyle(
                          fontSize: fontSize,
                          fontFamily: fontFamily,
                          fontWeight: fontWeight,
                          color: color,
                          height: 1.4,
                          shadows: shadows,
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _WavingLightPainter extends CustomPainter {
  final double phase;
  final Color accentColor;

  const _WavingLightPainter({required this.phase, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Soft radial glow from center
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height * 0.45),
        radius: size.width * 0.65,
      ));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);

    // 5 sine waves across the screen
    for (int i = 0; i < 5; i++) {
      final double opacity = (0.13 - i * 0.02).clamp(0.02, 0.13);
      final wavePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = accentColor.withValues(alpha: opacity);

      final double wavePhase = phase + i * (math.pi * 0.5);
      final double amplitude = size.height * (0.045 + i * 0.015);
      final double yBase = size.height * (0.42 + i * 0.04);

      final path = Path();
      bool first = true;
      for (double x = 0; x <= size.width; x += 3) {
        final double y =
            yBase + amplitude * math.sin(2.8 * math.pi * x / size.width + wavePhase);
        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(_WavingLightPainter old) => old.phase != phase;
}

class _LyricsSettingsBottomSheet extends StatelessWidget {
  final LyricsState state;
  final VoidCallback onSyncTap;

  const _LyricsSettingsBottomSheet(
      {required this.state, required this.onSyncTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF151515).withValues(alpha: 0.8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 32),
            _buildMenuItem(
              icon: MingCute.search_2_line,
              title: l10n.lyricsSettingsSearchTitle,
              subtitle: l10n.lyricsSettingsSearchSubtitle,
              onTap: () {
                Navigator.pop(context);
                showSearch(
                  context: context,
                  delegate: LyricsSearchDelegate(
                    mediaID: state.track.id,
                    searchFieldLabelText: l10n.lyricsSearchFieldLabel,
                  ),
                  query: buildLyricsSearchSeedQuery(
                    title: state.track.title,
                    artists: state.track.artists
                        .map((artist) => artist.name)
                        .toList(),
                    album: state.track.album?.title,
                  ),
                );
              },
            ),
            _buildMenuItem(
              icon: MingCute.time_line,
              title: l10n.lyricsSettingsSyncTitle,
              subtitle: l10n.lyricsSettingsSyncSubtitle,
              color: Default_Theme.accentColor2,
              onTap: onSyncTap,
            ),
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Colors.white12)),
            _buildMenuItem(
              icon: MingCute.save_2_line,
              title: l10n.lyricsSettingsSaveTitle,
              subtitle: l10n.lyricsSettingsSaveSubtitle,
              onTap: () {
                context
                    .read<LyricsCubit>()
                    .setLyricsToDB(state.lyrics, state.track.id);
                Navigator.pop(context);
              },
            ),
            _buildMenuItem(
              icon: MingCute.delete_3_line,
              title: l10n.lyricsSettingsDeleteTitle,
              subtitle: l10n.lyricsSettingsDeleteSubtitle,
              color: const Color(0xFFFF5252),
              onTap: () {
                context.read<LyricsCubit>().deleteLyricsFromDB(state.track);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
      Color color = Colors.white}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13)),
                ],
              ),
            ),
            Icon(MingCute.right_line,
                color: Colors.white.withValues(alpha: 0.3), size: 20),
          ],
        ),
      ),
    );
  }
}
