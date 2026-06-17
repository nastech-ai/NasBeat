part of 'global_events_cubit.dart';

sealed class GlobalEventsState extends Equatable {
  const GlobalEventsState();

  @override
  List<Object> get props => [];
}

final class GlobalEventsInitial extends GlobalEventsState {}

final class UpdateAvailable extends GlobalEventsState {
  final String newVersion;
  final String newBuild;
  final String downloadUrl;

  const UpdateAvailable(
      {required this.newVersion,
      required this.newBuild,
      required this.downloadUrl});
}

final class WhatIsNewState extends GlobalEventsState {
  final String changeLogs;

  const WhatIsNewState({required this.changeLogs});
}

final class AlertDialogState extends GlobalEventsState {
  final String title;
  final String content;

  const AlertDialogState({required this.title, required this.content});
}

final class UpdateDownloadProgress extends GlobalEventsState {
  final double progress;
  final String downloadUrl;

  const UpdateDownloadProgress(
      {required this.progress, required this.downloadUrl});

  @override
  List<Object> get props => [progress, downloadUrl];
}

final class UpdateDownloadComplete extends GlobalEventsState {
  final String filePath;

  const UpdateDownloadComplete({required this.filePath});

  @override
  List<Object> get props => [filePath];
}

final class UpdateDownloadError extends GlobalEventsState {
  final String message;
  final String downloadUrl;

  const UpdateDownloadError(
      {required this.message, required this.downloadUrl});

  @override
  List<Object> get props => [message, downloadUrl];
}
