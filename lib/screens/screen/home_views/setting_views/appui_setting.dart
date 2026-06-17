import 'package:nasbeat/blocs/settings_cubit/cubit/settings_cubit.dart';
import 'package:nasbeat/core/di/service_locator.dart';
import 'package:nasbeat/plugins/blocs/chart/chart_bloc.dart';
import 'package:nasbeat/plugins/blocs/chart/chart_event.dart';
import 'package:nasbeat/plugins/blocs/chart/chart_state.dart';
import 'package:nasbeat/plugins/blocs/plugin/plugin_bloc.dart';

import 'package:nasbeat/repository/LastFM/lastfmapi.dart';
import 'package:nasbeat/screens/screen/home_views/setting_views/setting_shared_widgets.dart';
import 'package:nasbeat/screens/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:nasbeat/core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasbeat/l10n/app_localizations.dart';
import 'package:icons_plus/icons_plus.dart';

class AppUISettings extends StatefulWidget {
  const AppUISettings({super.key});

  @override
  State<AppUISettings> createState() => _AppUISettingsState();
}

class _AppUISettingsState extends State<AppUISettings> {
  late final ChartBloc _chartBloc;

  @override
  void initState() {
    super.initState();
    _chartBloc = ChartBloc(
      pluginService: ServiceLocator.pluginService,
    );
    _loadCharts();
  }

  void _loadCharts() {
    final chartProviders =
        context.read<PluginBloc>().state.loadedChartProviders;
    if (chartProviders.isNotEmpty) {
      _chartBloc.add(LoadCharts(pluginId: chartProviders.first.manifest.id));
    }
  }

  @override
  void dispose() {
    _chartBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Default_Theme.themeColor,
      appBar: AppBar(
        backgroundColor: Default_Theme.themeColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Center(
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Default_Theme.primaryColor1,
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          l10n.appuiTitle,
          style: const TextStyle(
            color: Default_Theme.primaryColor1,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ).merge(Default_Theme.secondoryTextStyleMedium),
        ),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        buildWhen: (prev, curr) =>
            prev.autoSlideCharts != curr.autoSlideCharts ||
            prev.lFMPicks != curr.lFMPicks ||
            prev.chartMap != curr.chartMap ||
            prev.appTheme != curr.appTheme,
        builder: (context, state) {
          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // ── Theme Picker ──────────────────────────────────────────────
              const SettingSectionHeader(label: 'App Theme'),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.55,
                children: NasBeatTheme.values.map((theme) {
                  final selected = state.appTheme == theme.key;
                  return GestureDetector(
                    onTap: () => context
                        .read<SettingsCubit>()
                        .setAppTheme(theme.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? theme.accent
                              : Colors.white.withValues(alpha: 0.08),
                          width: selected ? 2.5 : 1,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: theme.accent.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      child: Stack(
                        children: [
                          // Color swatch strip at top
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(14)),
                              child: Container(
                                height: 28,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.background,
                                      theme.accent,
                                      theme.accentSecondary,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Theme name
                          Positioned(
                            bottom: 10,
                            left: 12,
                            right: 28,
                            child: Text(
                              theme.displayName,
                              style: TextStyle(
                                color: theme.primaryText,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Selected checkmark
                          if (selected)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: theme.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check,
                                    size: 13, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              // ── Home Screen ───────────────────────────────────────────────
              SettingSectionHeader(label: l10n.settingsHomeScreen),
              SettingCard(
                children: [
                  SettingToggleTile(
                    icon: MingCute.play_circle_line,
                    title: l10n.appuiAutoSlideCharts,
                    subtitle: l10n.appuiAutoSlideChartsSubtitle,
                    value: state.autoSlideCharts,
                    onChanged: (v) =>
                        context.read<SettingsCubit>().setAutoSlideCharts(v),
                  ),
                  const SettingDivider(),
                  SettingToggleTile(
                    icon: MingCute.music_2_line,
                    title: l10n.exploreLastFmPicks,
                    subtitle: l10n.appuiLastFmPicksSubtitle,
                    value: state.lFMPicks,
                    onChanged: (v) {
                      context.read<SettingsCubit>().setLastFMExpore(v);
                      if (v && LastFmAPI.initialized == false) {
                        Future.delayed(const Duration(milliseconds: 500), () {
                          context.read<SettingsCubit>().setLastFMExpore(false);
                        });
                        SnackbarService.showMessage(l10n.appuiLoginToLastFm);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SettingSectionHeader(label: l10n.settingsChartVisibility),
              BlocBuilder<ChartBloc, ChartState>(
                bloc: _chartBloc,
                builder: (context, chartState) {
                  if (chartState.charts.isEmpty) {
                    return SettingCard(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          child: Row(
                            children: [
                              const SettingIconBox(
                                  icon: MingCute.chart_bar_line),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  l10n.appuiNoChartsAvailable,
                                  style: TextStyle(
                                    color: Default_Theme.primaryColor2
                                        .withValues(alpha: 0.5),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ).merge(Default_Theme.secondoryTextStyle),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return SettingCard(
                    children: [
                      for (var i = 0; i < chartState.charts.length; i++) ...[
                        if (i > 0) const SettingDivider(),
                        SettingToggleTile(
                          icon: MingCute.chart_bar_line,
                          title: chartState.charts[i].title,
                          subtitle: l10n.appuiShowInCarousel,
                          value: state.chartMap[chartState.charts[i].title] ??
                              true,
                          onChanged: (v) {
                            context
                                .read<SettingsCubit>()
                                .setChartShow(chartState.charts[i].title, v);
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}
