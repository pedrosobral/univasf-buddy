import 'package:flutter/material.dart';

class NotificationsConfiguration extends StatelessWidget {
  final Widget child;

  NotificationsConfiguration({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notificações', style: TextStyle(color: Colors.black, fontFamily: 'Lato')),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 16.0),
          ),
          SwitchListTile(
            title: Text('Últimas notícias'),
            subtitle: Text(
                'Receba uma notificação quando houver uma nova notícia no site principal da Univasf'),
            value: true,
            onChanged: (value) => false,
          ),
        ],
      ),
    );
  }
}
