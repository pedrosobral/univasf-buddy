import 'package:flutter/material.dart';

import 'package:http/http.dart';
import 'package:html/parser.dart';
import 'package:share/share.dart';
import 'package:transparent_image/transparent_image.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_html/flutter_html.dart';

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
