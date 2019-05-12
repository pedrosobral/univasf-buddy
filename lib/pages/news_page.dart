import 'package:flutter/material.dart';

import 'package:flutter_buddy/widgets/news_card.dart';

class NewsPage extends StatelessWidget {
  final List<dynamic> data;

  const NewsPage({
    Key key,
    @required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Últimas notícias'),
      ),
      body: ListView.builder(
        itemCount: 20,
        itemBuilder: (context, index) {
          var time = DateTime.parse('${data[index]['datetime']}');
          return NewsCard(news: data[index], time: time);
        },
      ),
    );
  }
}
