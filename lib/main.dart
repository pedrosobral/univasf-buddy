import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:firebase_analytics/observer.dart';

import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter_buddy/blocs/settings_bloc.dart';
import 'package:flutter_buddy/models/data_meal.dart';
import 'package:flutter_buddy/models/meal_card_data.dart';
import 'package:flutter_buddy/pages/news_page.dart';
import 'package:flutter_buddy/pages/notifications_configuration.dart';
import 'package:flutter_buddy/services/settings_service.dart';
import 'package:flutter_buddy/widgets/card_meal.dart';

import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_buddy/widgets/loading_news.dart';
import 'package:flutter_buddy/widgets/news_card.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MyApp());

const locale = 'pt_BR';

class MyApp extends StatelessWidget {
  static FirebaseAnalytics analytics = FirebaseAnalytics();
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  MyApp() {
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Univasf Buddy',
      theme: ThemeData(
        primaryColor: Colors.white,
        accentColor: Colors.blue,
      ),
      home: Home(),
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics),
      ],
    );
  }
}

class Home extends StatefulWidget {
  final Widget child;

  Home({Key key, this.child}) : super(key: key);

  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  final Firestore firestore = Firestore.instance;
  AnimationController controller;
  final PageController _pageController =
      PageController(viewportFraction: 0.8, initialPage: 1);
  Animation animation;

  final settingsBloc =
      SettingsBloc(notificationsService: NotificationsService());

  Stream<DocumentSnapshot> _data;
  Stream<DocumentSnapshot> _weeklyMenuData;

  Stream<DocumentSnapshot> getNews() {
    return firestore.collection('news').document('latest').snapshots();
  }

  Stream<DocumentSnapshot> getWeeklyMenuData() {
    return firestore.collection('cardapio').document('latest').snapshots();
  }

  @override
  void initState() {
    super.initState();

    settingsBloc.init();

    controller =
        AnimationController(duration: Duration(seconds: 3), vsync: this);

    animation = Tween(begin: 0.0, end: 1.0).animate(controller);

    _data = getNews();
    _weeklyMenuData = getWeeklyMenuData();

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext _context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              floating: true,
              snap: true,
              title: _buildTitle(),
              centerTitle: true,
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.settings),
                  color: Colors.black,
                  tooltip: 'Configurações',
                  onPressed: () => _showBottomSheet(context),
                ),
              ],
            ),
          ];
        },
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildNews(),
              _buildMeals(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNews() {
    return Container(
      child: StreamBuilder(
        stream: _data,
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingListView();
          }

          List<dynamic> latest = snapshot.data.data['data'];

          final topNews = <Widget>[];
          latest.sublist(0, 3).asMap().forEach((i, v) {
            var time = DateTime.parse('${v['datetime']}');
            topNews.add(
              NewsCard(
                data: latest,
                news: v,
                time: time,
                initialIndex: i,
              ),
            );
          });

          return Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              selected: false,
              title: Text(
                'Últimas notícias',
                style: TextStyle(
                  fontFamily: 'Lato',
                  color: Colors.black,
                ),
              ),
            ),
            ...topNews,
            Divider(height: 0),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: FlatButton(
                color: Colors.white,
                child: Text(
                  'Ler mais notícias',
                  style: TextStyle(color: Colors.blue),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return NewsPage(data: latest.sublist(0, 20));
                      },
                      settings: RouteSettings(name: 'NewsListPage'),
                    ),
                  );
                },
              ),
            )
          ]);
        },
      ),
    );
  }

  _buildMeals() {
    return Container(
      margin: EdgeInsets.only(top: 0),
      child: StreamBuilder(
          stream: _weeklyMenuData,
          builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container();
            }

            var baseData = DataMeal.fromFirestore(snapshot.data.data);
            var data = baseData.data;

            var weekendDays = [DateTime.saturday, DateTime.sunday];
            var today = new DateTime.now().weekday;

            var initialIndex =
                weekendDays.contains(today) ? DateTime.monday : today;

            var meal = data[initialIndex.toString()];

            var breakfast = new MealCardData(
              location: meal['breakfast'].location,
              image: meal.breakfast.data[4].image,
              description: "${meal.breakfast.data[4].description}",
              meal: meal.breakfast.data[4].meal,
              time: "${meal.day} aberto das ${meal.breakfast.time}",
            );

            var lunch = new MealCardData(
              location: meal.lunch.location,
              image: meal.lunch.data[3].image,
              description:
                  "${meal.lunch.data[3].description}\n${meal.lunch.data[4].description}",
              meal: meal.lunch.data[3].meal,
              time: "${meal.day} aberto das ${meal.lunch.time}",
            );

            var dinner = new MealCardData(
              location: meal.dinner.location,
              image: meal.dinner.data[3].image,
              description: "${meal.dinner.data[3].description}",
              meal: meal.dinner.data[3].meal,
              time: "${meal.day} aberto das ${meal.dinner.time}",
            );

            return Column(
              children: <Widget>[
                ListTile(
                  title: Text(
                    'Cardápio semanal',
                    style: TextStyle(fontFamily: 'Lato'),
                  ),
                ),
                Container(
                  height: 160,
                  child: PageView(
                    controller: _pageController,
                    children: <Widget>[
                      CardMeal(
                        meal: breakfast,
                        data: baseData,
                        initialTabIndex: initialIndex,
                        initialTileIndex: 0,
                      ),
                      CardMeal(
                        meal: lunch,
                        data: baseData,
                        initialTabIndex: initialIndex,
                        initialTileIndex: 1,
                      ),
                      CardMeal(
                        meal: dinner,
                        data: baseData,
                        initialTabIndex: initialIndex,
                        initialTileIndex: 2,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
    );
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.notifications),
                  title: Text('Configurar notificações'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) {
                            return NotificationsConfiguration(
                              settingsBloc: settingsBloc,
                            );
                          },
                          settings:
                              RouteSettings(name: 'NotificationsConfigPage')),
                    ).then((value) => Navigator.pop(context));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Sobre o Univasf Buddy'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),
          );
        });
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'UNIVASF BUDDY',
      applicationVersion: 'v201917032002',
      applicationLegalese: '@2019 Pedro Henrique',
      children: [
        Text(
            '\nBem vindo ao novo aplicativo Univasf Buddy.\n\nNas próximas semanas estaremos adicionando novas funcionalidades.\n'),
        OutlineButton(
          onPressed: () {
            launch(
                'mailto:pedrosobralxv@gmail.com?subject=Sobre o Univasf Buddy&body=Olá Pedro Henrique,');
          },
          child: Text('ENVIAR CRÍTICA OU SUGESTÕES'),
        )
      ],
    );
  }

  Widget _buildTitle() {
    var logoHeight = 50.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(bottom: 4),
          height: logoHeight,
          width: logoHeight * 1.65,
          child: FlareActor(
            'asset/animation.flr',
            animation: 'go',
            fit: BoxFit.fitHeight,
          ),
        ),
        Text(
          ' buddy',
          style: TextStyle(
            fontFamily: 'Baloo',
            fontSize: 25,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingListView() {
    return Column(
      children:
          List<int>.generate(3, (i) => i).map((i) => LoadingNews()).toList(),
    );
  }

  @override
  void dispose() {
    super.dispose();

    settingsBloc.dispose();
  }
}
