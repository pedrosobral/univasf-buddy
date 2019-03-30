// import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

const String _LATEST_NEWS_NOTIFICATIONS_ENABLED_KEY =
    "latestNewsNotificationEnabledKey";

const _KeyTopics = {
  _LATEST_NEWS_NOTIFICATIONS_ENABLED_KEY: 'latest_news'
};

class NotificationsService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  NotificationsService() {
    init();
  }

  Future init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    _KeyTopics.forEach((key, topic) {
      bool isTopicEnabled = prefs.getBool(key) ?? true;

      if (isTopicEnabled) {
        _firebaseMessaging.subscribeToTopic(topic);
      }
    });
  }

  void subscribeToTopic(String topic) {
    _firebaseMessaging.subscribeToTopic(topic);
  }

  void unsubscribeFromTopic(String topic) {
    _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  Future<bool> isLatestNewsNotificationsEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_LATEST_NEWS_NOTIFICATIONS_ENABLED_KEY);
  }

  Future<void> setLatestNewsNotifications({bool enabled}) async {
    var topic = _KeyTopics[_LATEST_NEWS_NOTIFICATIONS_ENABLED_KEY];

    if (enabled) {
      this.subscribeToTopic(topic);
    } else {
      this.unsubscribeFromTopic(topic);
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(_LATEST_NEWS_NOTIFICATIONS_ENABLED_KEY, enabled);
  }
}
