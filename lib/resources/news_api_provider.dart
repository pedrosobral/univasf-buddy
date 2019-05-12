import 'package:html/parser.dart';
import 'package:http/http.dart';

class NewsModel {
  final String content;
  final String publishDate;
  final Set<String> images;

  NewsModel({this.content, this.publishDate, this.images});
}

class NewsApiProvider {
  Client client = Client();

  Future<NewsModel> fetchNews(String url) async {
    try {
      Response response = await client.get(url);

      final document = parse(response.body);

      final content =
          document.querySelector("div[property='rnews:articleBody']").innerHtml;

      final publishDate =
          document.querySelector("span[property='rnews:datePublished']").text;

      final imageList =
          document.querySelectorAll("img[property='rnews:thumbnailUrl']");

      Set<String> images = {};
      for (var item in imageList) {
        images.add(item.attributes['src'].split('/@@')[0]);
      }

      return NewsModel(
          content: content, publishDate: publishDate, images: images);
    } catch (e) {
      return Future.error('error');
    }
  }
}
