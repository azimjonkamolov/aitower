import '../algorithms/optimizer.dart';

/// Tayyor marshrut (assets/tours.json): bir bosishda to'liq reja.
class Tour {
  final String id, icon;
  final Map<String, String> name, desc;
  final List<int> places;
  final Transport transport;
  final int days;

  Tour.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        icon = j['icon'],
        name = Map<String, String>.from(j['name']),
        desc = Map<String, String>.from(j['desc']),
        places = List<int>.from(j['places']),
        transport = Transport.values.byName(j['transport']),
        days = j['days'];

  String nameIn(String l) => name[l] ?? name['uz']!;
  String descIn(String l) => desc[l] ?? desc['uz']!;
}
