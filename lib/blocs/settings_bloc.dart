import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_buddy/services/settings_service.dart';

abstract class SettingsEvent extends Equatable {
  SettingsEvent([List props = const []]) : super(props);
}

enum NotificationsTopic { latest }

class NotificationsToggled extends SettingsEvent {
  final bool value;
  final NotificationsTopic topic;

  NotificationsToggled({this.topic, this.value}) : super([value, topic]);
}

class LoadSettings extends SettingsEvent {}

class SettingsState extends Equatable {
  final bool latestNewsEnabled;

  SettingsState({this.latestNewsEnabled}) : super([latestNewsEnabled]);
}

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final NotificationsService notificationsService;

  SettingsBloc({this.notificationsService});

  init() {
    dispatch(LoadSettings());
  }

  @override
  SettingsState get initialState => SettingsState(latestNewsEnabled: true);

  @override
  Stream<SettingsState> mapEventToState(SettingsEvent event) async* {
    if (event is LoadSettings) {
      var enabled =
          await notificationsService.isLatestNewsNotificationsEnabled() ?? true;

      yield SettingsState(latestNewsEnabled: enabled);
    }

    if (event is NotificationsToggled) {
      if (event.topic == NotificationsTopic.latest) {
        await notificationsService.setLatestNewsNotifications(
            enabled: event.value);
      }

      yield SettingsState(latestNewsEnabled: event.value);
    }
  }
}
