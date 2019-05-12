import 'package:flutter/material.dart';
import 'package:flutter_buddy/resources/news_api_provider.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

import 'news_details.dart';

const ErrorMessage =
    'Ocorreu um erro ao carregar a notícia.\nO site da Univasf pode estar fora do ar.\nPor favor, também verifique a sua conexão com à internet.';

launchURL(url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

class NewsDetailsBuilder extends StatefulWidget {
  final List<dynamic> data;
  final int initialIndex;
  final PageController _controller;

  NewsDetailsBuilder({
    Key key,
    @required this.data,
    @required this.initialIndex,
  })  : assert(initialIndex >= 0),
        _controller = PageController(initialPage: initialIndex),
        super(key: key);

  @override
  _NewsDetailsBuilderState createState() => _NewsDetailsBuilderState();
}

class _NewsDetailsBuilderState extends State<NewsDetailsBuilder> {
  String currentURL;

  @override
  initState() {
    super.initState();

    _setURL(widget.initialIndex);
  }

  _setURL(int index) {
    setState(() {
      currentURL = widget.data[index]['url'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.share),
            tooltip: 'Compartilhar',
            onPressed: () {
              Share.share(currentURL);
            },
          ),
          IconButton(
              icon: Icon(Icons.open_in_browser),
              tooltip: 'Abrir no navegador',
              onPressed: () {
                launchURL(currentURL);
              })
        ],
      ),
      body: buildPageView(),
    );
  }

  PageView buildPageView() {
    return PageView.builder(
      controller: widget._controller,
      itemCount: widget.data.length,
      onPageChanged: (int index) {
        _setURL(index);
      },
      itemBuilder: (BuildContext context, int index) {
        return FutureBuilder(
          future: NewsApiProvider().fetchNews(widget.data[index]['url']),
          builder: (context, AsyncSnapshot<NewsModel> snapshot) {
            if (snapshot.hasError) {
              return PageError();
            }

            return AnimatedCrossFade(
              crossFadeState: !snapshot.hasData
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: Duration(milliseconds: 500),
              firstChild: LinearProgressIndicator(
                value: null,
              ),
              secondChild: DetailsPage(
                title: widget.data[index]['title'],
                data: snapshot.data,
              ),
            );
          },
        );
      },
    );
  }
}

class PageError extends StatelessWidget {
  const PageError({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.error,
            size: 50,
          ),
          Text(
            ErrorMessage,
            style: TextStyle(fontFamily: 'Lato', fontSize: 15, height: 2),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
