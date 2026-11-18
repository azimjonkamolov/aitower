import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'data_service.dart';

/// Ekranlar o'rtasida umumiy holat: tanlangan joylar va turist joylashuvi.
class AppState {
  static final selected = ValueNotifier<Set<int>>({});
  static final position = ValueNotifier<LatLng?>(null);
  static final tab = ValueNotifier<int>(0);
  /// Qo'lda tanlangan joy nomi (masalan "Shahrisabz"); GPS bo'lsa null.
  static final manualLabel = ValueNotifier<String?>(null);

  static void setManual(LatLng p, String label) {
    manualLabel.value = label;
    position.value = p;
  }

  static void toggle(int id) {
    final s = {...selected.value};
    s.contains(id) ? s.remove(id) : s.add(id);
    selected.value = s;
  }

  static Future<bool> locate() async {
    final p = await DataService().currentPosition();
    if (p != null) {
      manualLabel.value = null;
      position.value = LatLng(p.latitude, p.longitude);
    }
    return p != null;
  }
}
