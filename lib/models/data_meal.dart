class DataMeal {
  Map<String, Meals> data;

  DataMeal({
    this.data,
  });

  DataMeal.fromFirestore(Map<String, dynamic> obj) {
    Map<String, dynamic> _data = new Map<String, dynamic>.from(obj['data']);

    this.data = new Map();
    _data.forEach((day, values) {
      this.data[day] = Meals.fromJson(new Map<String, dynamic>.from(values));
    });
  }
}

class Meals {
  String day;
  String tabDayLabel;
  MealItem breakfast;
  MealItem lunch;
  MealItem dinner;

  Meals({
    this.day,
    this.breakfast,
    this.lunch,
    this.dinner,
  });

  Meals.fromJson(Map<String, dynamic> json)
      : day = json['day'],
        tabDayLabel = json['tabDayLabel'],
        breakfast =
            MealItem.fromJson(new Map<String, dynamic>.from(json['breakfast'])),
        lunch = MealItem.fromJson(new Map<String, dynamic>.from(json['lunch'])),
        dinner =
            MealItem.fromJson(new Map<String, dynamic>.from(json['dinner']));

  MealItem operator [](String index) {
    if (index == 'breakfast') {
      return this.breakfast;
    }

    if (index == 'lunch') {
      return this.lunch;
    }

    if (index == 'dinner') {
      return this.dinner;
    }

    return null;
  }
}

class MealItem {
  List<MealData> data;
  String location;
  String time;

  MealItem({
    this.data,
    this.location,
    this.time,
  });

  factory MealItem.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List;
    List<MealData> dataList = list
        .map((i) => MealData.fromJson(new Map<String, dynamic>.from(i)))
        .toList();

    return MealItem(
        data: dataList, location: json['location'], time: json['time']);
  }
}

class MealData {
  String meal;
  String description;
  String image;

  MealData({
    this.meal,
    this.description,
    this.image,
  });

  MealData.fromJson(Map<String, dynamic> json)
      : meal = json['meal'],
        description = json['description'],
        image = json['image'] + '.png';
}
