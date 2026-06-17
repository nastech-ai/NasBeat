import 'package:nasbeat/blocs/player_overlay/player_overlay_cubit.dart';
import 'package:nasbeat/screens/widgets/player_overlay_wrapper.dart';
import 'package:nasbeat/screens/widgets/mini_player_widget.dart';
import 'package:nasbeat/core/theme/app_theme.dart';
import 'package:nasbeat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:responsive_framework/responsive_framework.dart';

class GlobalFooter extends StatefulWidget {
  const GlobalFooter({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  State<GlobalFooter> createState() => _GlobalFooterState();
}

class _GlobalFooterState extends State<GlobalFooter> {
  final ValueNotifier<bool> _navVisible = ValueNotifier(true);

  @override
  void dispose() {
    _navVisible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<PlayerOverlayCubit>();
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return PlayerOverlayWrapper(
      child: BackButtonListener(
        onBackButtonPressed: () async {
          final overlayC = context.read<PlayerOverlayCubit>();
          final router = GoRouter.of(context);

          if (router.canPop()) {
            router.pop();
            return true;
          }
          if (overlayC.state && overlayC.collapseUpNextPanel()) return true;
          if (overlayC.state) {
            overlayC.hidePlayer();
            return true;
          }
          return false;
        },
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            await _handleHardwareBackPress(context);
          },
          child: NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction == ScrollDirection.reverse) {
                if (_navVisible.value) _navVisible.value = false;
              } else if (notification.direction == ScrollDirection.forward) {
                if (!_navVisible.value) _navVisible.value = true;
              }
              return false;
            },
            child: Scaffold(
              backgroundColor: Default_Theme.themeColor,
              drawerScrimColor: Default_Theme.themeColor,
              body: isMobile
                  ? _AnimatedPageView(
                      navigationShell: widget.navigationShell)
                  : Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: VerticalNavBar(
                              navigationShell: widget.navigationShell),
                        ),
                        Expanded(
                          child: _AnimatedPageView(
                              navigationShell: widget.navigationShell),
                        ),
                      ],
                    ),
              bottomNavigationBar: ValueListenableBuilder<bool>(
                valueListenable: _navVisible,
                builder: (context, visible, _) {
                  return AnimatedSize(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut,
                    child: SizedBox(
                      height: visible ? null : 0,
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const MiniPlayerWidget(),
                            if (isMobile)
                              Container(
                                color: Colors.transparent,
                                margin: const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 10),
                                child: HorizontalNavBar(
                                    navigationShell: widget.navigationShell),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleHardwareBackPress(BuildContext context) async {
    final overlayC = context.read<PlayerOverlayCubit>();
    final router = GoRouter.of(context);

    if (router.canPop()) {
      router.pop();
      return;
    }
    if (overlayC.state && overlayC.collapseUpNextPanel()) return;
    if (overlayC.state) {
      overlayC.hidePlayer();
      return;
    }
    if (widget.navigationShell.currentIndex != 0) {
      widget.navigationShell.goBranch(0);
      return;
    }
    if (context.mounted) {
      await SystemNavigator.pop();
    }
  }
}

class _AnimatedPageView extends StatefulWidget {
  const _AnimatedPageView({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  State<_AnimatedPageView> createState() => _AnimatedPageViewState();
}

class _AnimatedPageViewState extends State<_AnimatedPageView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.navigationShell.currentIndex;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(_AnimatedPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationShell.currentIndex != _previousIndex) {
      _previousIndex = widget.navigationShell.currentIndex;
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.navigationShell,
      ),
    );
  }
}

class VerticalNavBar extends StatelessWidget {
  const VerticalNavBar({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return NavigationRail(
      backgroundColor: Default_Theme.themeColor.withValues(alpha: 0.3),
      destinations: [
        NavigationRailDestination(
            icon: const Icon(MingCute.home_4_fill), label: Text(l10n.navHome)),
        NavigationRailDestination(
            icon: const Icon(MingCute.book_5_fill),
            label: Text(l10n.navLibrary)),
        NavigationRailDestination(
            icon: const Icon(MingCute.search_2_fill),
            label: Text(l10n.navSearch)),
        NavigationRailDestination(
            icon: const Icon(MingCute.music_2_fill),
            label: Text(l10n.navLocal)),
        NavigationRailDestination(
            icon: const Icon(MingCute.folder_download_fill),
            label: Text(l10n.navOffline)),
      ],
      selectedIndex: navigationShell.currentIndex,
      minWidth: 70,
      onDestinationSelected: navigationShell.goBranch,
      groupAlignment: 0.0,
      unselectedIconTheme:
          const IconThemeData(color: Default_Theme.primaryColor2),
      indicatorColor: Default_Theme.accentColor2,
      indicatorShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(15)),
      ),
    );
  }
}

class HorizontalNavBar extends StatelessWidget {
  const HorizontalNavBar({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GNav(
      gap: 7.0,
      tabBackgroundColor: Default_Theme.accentColor2.withValues(alpha: 0.22),
      color: Default_Theme.primaryColor2,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      activeColor: Default_Theme.accentColor2,
      textStyle: Default_Theme.secondoryTextStyleMedium.merge(
          const TextStyle(color: Default_Theme.accentColor2, fontSize: 18)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      backgroundColor: Default_Theme.themeColor.withValues(alpha: 0.3),
      tabs: [
        GButton(icon: MingCute.home_4_fill, text: l10n.navHome),
        GButton(icon: MingCute.book_5_fill, text: l10n.navLibrary),
        GButton(icon: MingCute.search_2_fill, text: l10n.navSearch),
        GButton(icon: MingCute.music_2_fill, text: l10n.navLocal),
        GButton(icon: MingCute.folder_download_fill, text: l10n.navOffline),
      ],
      selectedIndex: navigationShell.currentIndex,
      onTabChange: navigationShell.goBranch,
    );
  }
}
