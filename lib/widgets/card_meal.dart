import 'package:flutter/material.dart';
import 'package:flutter_buddy/models/data_meal.dart';
import 'package:flutter_buddy/models/meal_card_data.dart';
import 'package:flutter_buddy/pages/weekly_menu.dart';

class CardMeal extends StatelessWidget {
  final MealCardData meal;
  final DataMeal data;
  final int initialTabIndex;
  final int initialTileIndex;

  CardMeal({
    Key key,
    @required this.meal,
    @required this.data,
    @required this.initialTabIndex,
    @required this.initialTileIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        splashColor: Colors.blue.withAlpha(30),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return WeeklyMenuPage(
                  data: this.data,
                  initialTabIndex: initialTabIndex,
                  initialTileIndex: initialTileIndex,
                );
              },
              settings: RouteSettings(name: 'WeeklyMenuPage'),
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: Text(
                meal.location,
                maxLines: 1,
                style: TextStyle(fontFamily: 'Montserrat'),
              ),
              subtitle: Text(
                meal.time,
                maxLines: 1,
              ),
            ),
            ListTile(
              leading: Image.asset(
                'asset/images/${meal.image}',
                width: 40,
                height: 40,
              ),
              title: Text(
                meal.meal,
              ),
              subtitle: Text(meal.description),
            )
          ],
        ),
      ),
    );
  }
}
