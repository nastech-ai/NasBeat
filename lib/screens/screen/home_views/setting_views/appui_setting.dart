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
            prev.appTheme != curr.appTheme ||
            prev.autoSlideCharts != curr.autoSlideCharts ||
            prev.lFMPicks != curr.lFMPicks ||
            prev.chartMap != curr.chartMap,
        builder: (context, state) {
          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
                            SettingSectionHeader(label: 'Theme'),
              SettingCard(
                children: [
                  for (final theme in NasBeatTheme.values) ...[
                    if (theme != NasBeatTheme.values.first) const SettingDivider(),
                    _ThemeTile(
                      theme: theme,
                      isSelected: state.appTheme == theme.key,
                      onTap: () => context.read<SettingsCubit>().setAppTheme(theme.key),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 28),
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

class _ThemeTile extends StatelessWidget {
  final NasBeatTheme theme;
  final bool isSelected;
  final VoidCallback onTap;
  const _ThemeTile({required this.theme, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = theme.accent;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.background,
                border: Border.all(
                  color: isSelected ? accent : Colors.white.withValues(alpha: 0.08),
                  width: isSelected ? 2.5 : 1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: isSelected
                  ? Icon(Icons.check_rounded, size: 18, color: accent)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.displayName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (theme.isAmoled)
                    Text(
                      'True black — best for OLED screens',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
