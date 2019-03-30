import 'package:flutter/material.dart';
import 'package:flutter_buddy/blocs/settings_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationsConfiguration extends StatelessWidget {
  final settingsBloc;

  NotificationsConfiguration({Key key, @required this.settingsBloc})
      : super(key: key) {
    settingsBloc.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notificações',
            style: TextStyle(color: Colors.black, fontFamily: 'Lato')),
      ),
      body: BlocBuilder(
        bloc: settingsBloc,
        builder: (context, SettingsState state) {
          return Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 16.0),
              ),
              _buildSwitchLatestNews(state),
            ],
          );
        },
      ),
    );
  }

  SwitchListTile _buildSwitchLatestNews(SettingsState state) {
    return SwitchListTile(
      title: Text('Últimas notícias'),
      subtitle: Text(
          'Receba uma notificação quando houver uma nova notícia no site principal da Univasf'),
      value: state.latestNewsEnabled,
      onChanged: (value) => settingsBloc.dispatch(
            NotificationsToggled(
                value: !state.latestNewsEnabled,
                topic: NotificationsTopic.latest),
          ),
    );
  }
}
