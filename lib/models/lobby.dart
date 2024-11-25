import 'package:uuid/uuid.dart';

const uuid = Uuid();

enum Category { black, white}

const categoryIcons = {
  //Category.rapid: Icons.lunch_dining,
};

class Lobby {
  Lobby({
    required this.name,
    required this.time,
    required this.category,
  }): id = uuid.v4();

  final String id;
  final String name;
  final Duration time;
  final Category category;
}
