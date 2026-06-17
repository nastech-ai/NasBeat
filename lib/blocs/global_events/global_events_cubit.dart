import 'dart:developer';

import 'package:nasbeat/core/constants/setting_keys.dart';
import 'package:nasbeat/services/nasbeat_updater_tools.dart';
import 'package:nasbeat/services/db/dao/settings_dao.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'global_events_state.dart';

class GlobalEventsCubit extends Cubit<GlobalEventsState> {
  final SettingsDAO _settingsDao;

  GlobalEventsCubit({required SettingsDAO settingsDao})
      : _settingsDao = settingsDao,
        super(GlobalEventsInitial()) {
    checkForUpdates();
  }

  void checkForUpdates() async {
    final Map<String, dynamic> updates = await getAppUpdates();
    log("Checking for updates...", name: 'GlobalEventsCubit');

    if (updates['changelogs'] != null) {
      emit(WhatIsNewState(changeLogs: updates['changelogs']));
    }

    if (await _settingsDao.getSettingBool(SettingKeys.autoUpdateNotify) ??
        true) {
      if (updates["results"]) {
        emit(UpdateAvailable(
          newVersion: updates["newVer"],
          newBuild: updates["newBuild"],
          downloadUrl: updates["download_url"] ?? "https://github.com/nastech-ai/NasBeat/releases/latest",
        ));
      }
    }
  }

  Future<void> downloadUpdate(String downloadUrl) async {
    log('Starting update download: $downloadUrl', name: 'GlobalEventsCubit');
    try {
      final path = await downloadUpdateFile(
        downloadUrl,
        onProgress: (progress) => emit(
          UpdateDownloadProgress(
              progress: progress, downloadUrl: downloadUrl),
        ),
      );
      emit(UpdateDownloadComplete(filePath: path));
      log('Update downloaded to: $path', name: 'GlobalEventsCubit');
    } catch (e, st) {
      log('Update download failed: $e\n$st', name: 'GlobalEventsCubit');
      emit(UpdateDownloadError(
          message: e.toString(), downloadUrl: downloadUrl));
    }
  }

  void showAlertDialog(String title, String content) {
    emit(AlertDialogState(title: title, content: content));
  }
}
