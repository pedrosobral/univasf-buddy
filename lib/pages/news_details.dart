import 'package:flutter/material.dart';
import 'package:flutter_buddy/resources/news_api_provider.dart';

import 'package:transparent_image/transparent_image.dart';

import 'package:flutter_html/flutter_html.dart';

import 'news_datails_builder.dart';

class DetailsPage extends StatefulWidget {
  final NewsModel data;
  // final String url;
  final String title;

  DetailsPage({
    Key key,
    @required this.data,
    // @required this.url,
    @required this.title,
  }) : super(key: key);

  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  int currentImage = 0;

  final PageController _pageController = PageController(viewportFraction: 0.8);

  @override
  Widget build(BuildContext context) {
    return _buildPageView(context);
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
          widget.data.images.length > 0 ? _buildImages() : Container(),
          _buildHtml()
        ],
      ),
    );
  }

  Padding _buildDatetimeInfo() {
    return Padding(
        padding: const EdgeInsets.only(left: 16, top: 16),
        child: Text(
          'Publicado ${widget.data.publishDate}',
          style: TextStyle(color: Colors.black54),
        ));
  }

  Widget _buildHtml() {
    return Html(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      defaultTextStyle: const TextStyle(
        height: 1.2,
        fontSize: 16.0,
      ),
      useRichText: true,
      data: widget.data.content,
      onLinkTap: (link) => launchURL(link),
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
            children:
                widget.data.images.map((url) => _buildImage(url)).toList(),
          ),
          widget.data.images.length > 1 ? _buildImageCounter() : Container()
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
        label: Text('${currentImage + 1}/${widget.data.images.length}'),
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
