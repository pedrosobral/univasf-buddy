import 'package:flutter/material.dart';
import 'package:flutter_buddy/models/data_meal.dart';

import 'news_datails_builder.dart';

const CARDAPIO_URL =
    'http://portais.univasf.edu.br/proae/restaurante-universitario/cardapio';

class WeeklyMenuPage extends StatefulWidget {
  final DataMeal data;
  final int initialTabIndex;
  final int initialTileIndex;

  WeeklyMenuPage({
    Key key,
    @required this.data,
    @required this.initialTabIndex,
    @required this.initialTileIndex,
  }) : super(key: key);

  _WeeklyMenuPageState createState() => _WeeklyMenuPageState();
}

class _WeeklyMenuPageState extends State<WeeklyMenuPage> {
  @override
  Widget build(BuildContext context) {
    var children = <Widget>[];
    var tabs = <Tab>[];

    widget.data.data.forEach((k, v) {
      var initialTileIndex;
      if (k == widget.initialTabIndex.toString()) {
        initialTileIndex = widget.initialTileIndex;
      }

      tabs.add(Tab(text: v.tabDayLabel));

      children.add(MenuPage(
        data: widget.data.data[k],
        initialTileIndex: initialTileIndex,
      ));
    });

    return DefaultTabController(
      initialIndex: widget.initialTabIndex - 1,
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(tabs: tabs),
          title: Text('Cardápio semanal'),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.open_in_browser),
              tooltip: 'Abrir no navegador',
              onPressed: () {
                launchURL(CARDAPIO_URL);
              },
            ),
          ],
        ),
        body: TabBarView(children: children),
      ),
    );
  }
}

class MenuPage extends StatelessWidget {
  final int initialTileIndex;

  const MenuPage({
    Key key,
    @required Meals data,
    this.initialTileIndex,
  })  : _data = data,
        super(key: key);

  final Meals _data;

  @override
  Widget build(BuildContext context) {
    final breakfast = this._data.breakfast;
    final lunch = this._data.lunch;
    final dinner = this._data.dinner;
    final _data = [breakfast, lunch, dinner];

    return ListView.builder(
      key: PageStorageKey(this._data.day),
      itemCount: 3,
      itemBuilder: (context, index) {
        var meal = _data[index].data;
        return ExpansionTile(
          initiallyExpanded: initialTileIndex == null
              ? true
              : index >= initialTileIndex ? true : false,
          key: PageStorageKey(_data[index].time),
          title: ListTile(
            title: Text(
              _data[index].location,
              style: TextStyle(fontFamily: 'Montserrat'),
            ),
            subtitle: Text(_data[index].time),
          ),
          children: <Widget>[
            ListView.separated(
              key: PageStorageKey(this._data.day),
              shrinkWrap: true,
              physics: ClampingScrollPhysics(),
              separatorBuilder: (context, index) {
                return Divider(
                  indent: 72,
                );
              },
              itemCount: meal.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Image.asset(
                    'asset/images/${meal[index].image}',
                    width: 40,
                    height: 40,
                  ),
                  title: Text(
                    meal[index].meal,
                  ),
                  subtitle: Text(meal[index].description),
                );
              },
            )
          ],
        );
      },
    );
  }
}
