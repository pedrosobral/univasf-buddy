import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:firebase_analytics/observer.dart';

import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter_buddy/blocs/settings_bloc.dart';
import 'package:flutter_buddy/models/data_meal.dart';
import 'package:flutter_buddy/models/meal_card_data.dart';
import 'package:flutter_buddy/pages/news_page.dart';
import 'package:flutter_buddy/pages/notifications_configuration.dart';
import 'package:flutter_buddy/services/settings_service.dart';
import 'package:flutter_buddy/widgets/card_meal.dart';
import 'package:transparent_image/transparent_image.dart';

import 'package:flutter_buddy/widgets/loading_news.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart';
import 'package:html/parser.dart';
import 'package:share/share.dart';

void main() => runApp(MyApp());

const locale = 'pt_BR';

class MyApp extends StatelessWidget {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  static FirebaseAnalytics analytics = FirebaseAnalytics();
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  MyApp() {
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());
    _firebaseMessaging.getToken().then((token) {
      print(token);
    });
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
            ...latest.sublist(0, 3).map((item) {
              var time = DateTime.parse('${item['datetime']}');
              return NewsCard(news: item, time: time);
            }).toList(),
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
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) {
                    return NewsPage(data: latest);
                  }));
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
                      MaterialPageRoute(builder: (BuildContext context) {
                        return NotificationsConfiguration(
                          settingsBloc: settingsBloc,
                        );
                      }),
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

class NewsCard extends StatelessWidget {
  const NewsCard({
    Key key,
    @required this.news,
    @required this.time,
  }) : super(key: key);

  final news;
  final DateTime time;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(0),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: InkWell(
        splashColor: Colors.blue.withAlpha(30),
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          title: Text(
            news['title'],
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
            style: TextStyle(fontFamily: 'Montserrat', color: Colors.black87),
          ),
          subtitle:
              Text(timeago.format(time, locale: 'pt_BR', allowFromNow: true)),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) {
              return DetailsPage(
                title: news['title'],
                url: news['url'],
              );
            }));
          },
        ),
      ),
    );
  }
}

class DetailsPage extends StatefulWidget {
  final String url;
  final String title;

  DetailsPage({
    Key key,
    @required this.url,
    @required this.title,
  }) : super(key: key);

  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  var client = Client();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final snackBar = SnackBar(
      content: Text(
          'Ocorreu um erro ao carregar os detalhes da notícia.\n Verifique sua conexão com a internet.'));
  String text;
  String publishDate;
  Set<String> images = {};
  bool loading = true;

  int currentImage = 0;

  final PageController _pageController = PageController(viewportFraction: 0.8);

  @override
  void initState() {
    super.initState();

    init();
  }

  init() async {
    try {
      Response response = await client.get(widget.url);
      var document = parse(response.body);

      var mainContent =
          document.querySelector("div[property='rnews:articleBody']").innerHtml;

      var publish =
          document.querySelector("span[property='rnews:datePublished']").text;

      var imgs =
          document.querySelectorAll("img[property='rnews:thumbnailUrl']");

      Set<String> imgList = {};
      for (var item in imgs) {
        imgList.add(item.attributes['src'].split('/@@')[0]);
      }

      setState(() {
        text = mainContent;
        publishDate = publish;
        images = imgList;
      });

      if (text == null) {
        print('show error');
      }
    } catch (e) {
      _showErrorMessage();
      print('CATCH ERROR\n\n\n\n$e');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  _launchURL(url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  _showErrorMessage() {
    _scaffoldKey.currentState.showSnackBar(this.snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext _context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              floating: true,
              pinned: false,
              snap: true,
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.share),
                  tooltip: 'Compartilhar',
                  onPressed: () {
                    Share.share(widget.url);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.open_in_browser),
                  tooltip: 'Abrir no navegador',
                  onPressed: () {
                    _launchURL(widget.url);
                  },
                ),
              ],
            ),
          ];
        },
        body: loading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : _buildPageView(context),
      ),
    );
  }

  Widget _buildPageView(context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16),
            child: Text(
              widget.title,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: Theme.of(context).textTheme.title.fontSize,
              ),
            ),
          ),
          _buildDatetimeInfo(),
          images.length > 0 ? _buildImages() : Container(),
          text != null ? _buildHtml() : _showLoadError(),
        ],
      ),
    );
  }

  Padding _buildDatetimeInfo() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16),
      child: text != null
          ? Text(
              'Publicado $publishDate',
              style: TextStyle(color: Colors.black54),
            )
          : Container(),
    );
  }

  Widget _showLoadError() {
    return Container();
  }

  Widget _buildHtml() {
    return Html(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      defaultTextStyle: const TextStyle(
        height: 1.2,
        fontSize: 16.0,
      ),
      useRichText: true,
      data: text,
      onLinkTap: (link) => _launchURL(link),
    );
  }

  _buildImages() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      height: 250,
      child: Stack(
        children: <Widget>[
          PageView(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                currentImage = page;
              });
            },
            physics: BouncingScrollPhysics(),
            children: images.map((url) => _buildImage(url)).toList(),
          ),
          images.length > 1 ? _buildImageCounter() : Container()
        ],
      ),
    );
  }

  Container _buildImageCounter() {
    return Container(
      alignment: Alignment.bottomRight,
      padding: EdgeInsets.only(right: 16),
      child: Chip(
        elevation: 2,
        backgroundColor: Colors.transparent,
        label: Text('${currentImage + 1}/${images.length}'),
      ),
    );
  }

  Widget _buildImage(url) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Center(
          child: CircularProgressIndicator(),
        ),
        Container(
          padding: EdgeInsets.only(right: 8, bottom: 8),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FadeInImage.memoryNetwork(
                placeholder: kTransparentImage,
                image: url,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
