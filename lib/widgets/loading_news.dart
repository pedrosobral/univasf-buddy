import 'package:flutter/material.dart';

class LoadingNews extends StatelessWidget {
  final Widget child;

  LoadingNews({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Container(
          height: 15,
          decoration: BoxDecoration(
              color: Colors.grey,
              gradient: LinearGradient(
                colors: [
                  Color.fromRGBO(224, 224, 224, 1),
                  Color.fromRGBO(224, 224, 224, .2)
                ],
              )),
        ),
        subtitle: SizedBox(
          height: 15.0,
          width: 10.0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey,
              gradient: LinearGradient(
                colors: [
                  Color.fromRGBO(224, 224, 224, 1),
                  Color.fromRGBO(224, 224, 224, .2),
                  Colors.grey[50],
                  Colors.grey[50],
                  Colors.grey[50],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
