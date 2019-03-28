import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:firebase_analytics/observer.dart';

import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter_buddy/pages/notifications_configuration.dart';
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
    _firebaseMessaging.subscribeToTopic('news_notifications');
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
  Animation animation;

  Stream<DocumentSnapshot> _data;

  Stream<DocumentSnapshot> getNews() {
    return firestore.collection('news').document('latest').snapshots();
  }

  @override
  void initState() {
    super.initState();

    controller =
        AnimationController(duration: Duration(seconds: 3), vsync: this);

    animation = Tween(begin: 0.0, end: 1.0).animate(controller);

    _data = getNews();

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
                  color: Colors.blue,
                  tooltip: 'Configurações',
                  onPressed: () => _showBottomSheet(context),
                ),
              ],
            ),
          ];
        },
        body: Container(
            margin: EdgeInsets.only(top: 0),
            child: StreamBuilder(
              stream: _data,
              builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingListView();
                }

                List<dynamic> latest = snapshot.data.data['data'];

                return ListView.builder(
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.only(top: 0),
                  itemCount: latest.length,
                  itemBuilder: (context, index) {
                    var time = DateTime.parse('${latest[index]['datetime']}');
                    print(time);
                    return NewsCard(news: latest[index], time: time);
                  },
                );
              },
            )),
      ),
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
                        return NotificationsConfiguration();
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
    var value = 50.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(bottom: 4),
          height: value,
          width: value * 1.65,
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

  ListView _buildLoadingListView() {
    return ListView.builder(
      itemCount: 10,
      physics: BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        return LoadingNews();
      },
    );
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
      margin: EdgeInsets.symmetric(vertical: 8.0),
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
              return Scaffold(
                body: DetailsPage(
                  title: news['title'],
                  url: news['url'],
                ),
              );
            }));
          },
        ),
      ),
    );
  }
}

class DetailsPage extends StatefulWidget {
  final Widget child;
  final String url;
  final String title;

  DetailsPage({
    Key key,
    this.child,
    @required this.url,
    @required this.title,
  }) : super(key: key);

  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  var client = Client();
  final snackBar = SnackBar(
      content: Text(
          'Ocorreu um erro ao carregar os detalhes da notícia.\n Verifique sua conexão com a internet.'));
  BuildContext _scaffoldContext;

  String text;
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
          document.querySelector("div[property='rnews:articleBody']");

      var imgs =
          document.querySelectorAll("img[property='rnews:thumbnailUrl']");

      Set<String> imgList = {};
      for (var item in imgs) {
        imgList.add(item.attributes['src'].split('/@@')[0]);
      }

      setState(() {
        text = mainContent.innerHtml;
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
    Scaffold.of(_scaffoldContext).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    _scaffoldContext = context;

    if (loading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return NestedScrollView(
      physics: BouncingScrollPhysics(),
      headerSliverBuilder: (BuildContext _context, bool innerBoxIsScrolled) {
        return <Widget>[
          SliverAppBar(
            floating: true,
            pinned: false,
            snap: true,
            title: Text(
              'Detalhes',
              style: TextStyle(color: Colors.black, fontFamily: 'Lato'),
            ),
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
      body: _buildPageView(context),
    );
  }

  Widget _buildPageView(context) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
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
          images.length > 0 ? _buildImages() : Container(),
          text != null ? _buildHtml() : _showLoadError(),
        ],
      ),
    );
  }

  Widget _showLoadError() {
    return Container();
  }

  Widget _buildHtml() {
    return Html(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
      defaultTextStyle: TextStyle(
        height: 1.2,
        fontSize: 15.0,
      ),
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
