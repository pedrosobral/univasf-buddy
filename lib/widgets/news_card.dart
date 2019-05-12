import 'package:flutter/material.dart';
import 'package:flutter_buddy/pages/news_datails_builder.dart';

import 'package:timeago/timeago.dart' as timeago;

class NewsCard extends StatelessWidget {
  final news;
  final DateTime time;
  final List<dynamic> data;
  final int initialIndex;

  const NewsCard({
    Key key,
    @required this.news,
    @required this.time,
    @required this.data,
    @required this.initialIndex,
  }) : super(key: key);

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
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return NewsDetailsBuilder(
                    data: data,
                    initialIndex: initialIndex,
                  );
                },
                settings: RouteSettings(name: 'NewsDetailsPage'),
              ),
            );
          },
        ),
      ),
    );
  }
}
