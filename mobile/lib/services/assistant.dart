import 'dart:math';
import '../l10n/strings.dart';
import '../models/attraction.dart';
import '../algorithms/haversine.dart';
import '../widgets/common.dart';

/// Virtual turistik yordamchi: oflayn savol-javob tizimi (o'zbek, rus, ingliz).
/// Savoldan niyat (ish vaqti, narx, yaqin joylar, tavsiya...), toifa, shahar va joy nomi aniqlanadi.
class Assistant {
  final List<Attraction> places;
  final double? lat, lon;
  Assistant(this.places, {this.lat, this.lon});

  static String norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp("[‘’ʻʼ`'\"]"), '')
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ');

  static const _intents = <String, List<String>>{
    'hours': ['qachon', 'ochiq', 'ochil', 'yopil', 'ish vaqt', 'soat', 'open', 'close', 'hours', 'when', 'когда', 'открыт', 'закрыт', 'часы', 'работает', 'время работы'],
    'price': ['narx', 'qancha', 'bilet', 'chipta', 'pul', 'price', 'cost', 'ticket', 'how much', 'fee', 'цена', 'стоит', 'билет', 'сколько стоит'],
    'near': ['yaqin', 'atrof', 'qayerda', 'qaerda', 'near', 'close to me', 'around', 'where', 'рядом', 'ближ', 'где', 'поблизости'],
    'recommend': ['tavsiya', 'maslahat', 'nima kor', 'qayerga bor', 'eng yaxshi', 'recommend', 'suggest', 'best', 'what to see', 'посовет', 'рекоменд', 'лучш', 'что посмотреть', 'куда пойти'],
    'route': ['marshrut', 'yol', 'sayohat reja', 'route', 'trip', 'plan', 'itinerary', 'маршрут', 'путь', 'план'],
    'about': ['haqida', 'malumot', 'nima', 'about', 'tell me', 'info', 'what is', 'расскаж', 'о ', 'информац', 'что такое'],
    'food': ['taom', 'oshxona', 'milliy taom', 'nima yeyish', 'tandir', 'jiz', 'somsa', 'shorva', 'yaxna', 'gilvindi', 'cuisine', 'dish', 'what to eat', 'local food', 'кухня', 'блюд', 'что поесть', 'тандыр', 'самс', 'шурп'],
    'transport': ['poyezd', 'poezd', 'avtobus', 'qanday bor', 'qanday yet', 'toshkentdan', 'transport', 'train', 'bus', 'how to get', 'get there', 'from tashkent', 'поезд', 'автобус', 'как добраться', 'из ташкента', 'такси до'],
    'festival': ['festival', 'bayram', 'forum', 'tadbir', 'event', 'фестивал', 'праздник', 'форум'],
    'hello': ['salom', 'assalom', 'hello', 'hi ', 'hey', 'привет', 'здравств'],
  };

  static const _categories = <String, List<String>>{
    'ziyorat': ['ziyorat', 'masjid', 'maqbara', 'mozor', 'shrine', 'mosque', 'pilgrim', 'holy', 'зиярат', 'святын', 'мечет', 'мавзоле', 'паломн'],
    'tarix': ['tarix', 'obida', 'madrasa', 'saroy', 'qadimiy', 'histor', 'monument', 'palace', 'ancient', 'museum', 'muzey', 'истор', 'памятник', 'дворец', 'древн', 'медресе', 'музей'],
    'tabiat': ['tabiat', 'tog', 'gor', 'suv ombori', 'kol', 'qoriqxona', 'nature', 'mountain', 'cave', 'lake', 'reservoir', 'природ', 'гор', 'пещер', 'озер', 'водохран', 'заповед'],
    'mehmonxona': ['mehmonxona', 'yotoq', 'tunash', 'hotel', 'stay', 'sleep', 'guest', 'гостиниц', 'отел', 'ночев', 'жиль'],
    'taom': ['restoran', 'ovqat', 'taom', 'osh', 'choyxona', 'kafe', 'restaurant', 'food', 'eat', 'cafe', 'lunch', 'dinner', 'ресторан', 'поесть', 'еда', 'кафе', 'чайхан', 'плов'],
    'dam': ['dam ol', 'park', 'bog', 'leisure', 'relax', 'отдых', 'парк'],
  };

  static const _cities = <String, List<String>>{
    'shahrisabz': ['shahrisabz', 'shakhrisabz', 'kesh', 'шахрисабз'],
    'qarshi': ['qarshi', 'karshi', 'nasaf', 'карши'],
    'kitob': ['kitob', 'kitab', 'китаб'],
  };

  String? _find(Map<String, List<String>> m, String q) {
    for (final e in m.entries) {
      if (e.value.any(q.contains)) return e.key;
    }
    return null;
  }

  static const _stop = {
    'majmuasi', 'maqbarasi', 'masjidi', 'madrasasi', 'saroyi', 'mehmonxonasi', 'restorani', 'complex', 'mosque', 'madrasa',
    'palace', 'hotel', 'restaurant', 'reservoir', 'комплекс', 'мечеть', 'медресе', 'дворец', 'отель', 'гостиница',
    'ресторан', 'водохранилище', 'ziyoratgohi', 'shrine', 'святыня', 'ombori', 'park', 'парк', 'bogi', 'amir', 'temur',
    // shahar nomlari joy nomi hisoblanmaydi ("Qarshida nima bor?" -> shahar bo'yicha ro'yxat)
    'qarshi', 'karshi', 'shahrisabz', 'shakhrisabz', 'kitob', 'kitab', 'карши', 'шахрисабз', 'шахрисабза', 'китаб',
    'kashkadarya', 'qashqadaryo', 'кашкадарьи', 'кашкадарья',
  };

  Attraction? _place(String q) {
    Attraction? best;
    var bestScore = 0;
    for (final a in places) {
      var s = 0;
      for (final n in a.name.values) {
        final words = norm(n).split(RegExp(r'\s+')).where((w) => w.length >= 4 && !_stop.contains(w));
        for (final w in words) {
          if (q.contains(w.substring(0, min(w.length, 6)))) s += 2;
        }
      }
      if (s > bestScore) {
        bestScore = s;
        best = a;
      }
    }
    return best;
  }

  String _fmt(String key, Map<String, String> v) {
    var s = tr(key);
    v.forEach((k, val) => s = s.replaceAll('{$k}', val));
    return s;
  }

  String _list(List<Attraction> l, String lang) => l
      .map((a) => '• ${a.nameIn(lang)} (${tr('city_${a.city}')}, ★${a.rating}'
          '${a.distanceKm != null ? ', ${a.distanceKm!.toStringAsFixed(1)} ${tr('km')}' : ''})')
      .join('\n');

  String answer(String question) {
    final lang = Lang.current.value;
    final q = ' ${norm(question)} ';
    final intent = _find(_intents, q);
    final cat = _find(_categories, q);
    final city = _find(_cities, q);
    final place = _place(q);
    for (final a in places) {
      a.distanceKm = (lat != null && lon != null) ? haversineKm(lat!, lon!, a.lat, a.lon) : null;
    }

    if (place != null && (intent == 'hours')) {
      final (status, _) = openStatus(place);
      return _fmt('as_hours', {
        'name': place.nameIn(lang),
        'hours': place.alwaysOpen ? tr('open_24h') : place.hours.replaceAll('-', '–'),
        'status': status,
        'closed': place.closedDays.isEmpty ? '' : '\n${tr('closed_days')}: ${place.closedDays.map((d) => tr('wd$d')).join(', ')}',
      });
    }
    if (place != null && intent == 'price') {
      return _fmt('as_price', {'name': place.nameIn(lang), 'price': money(place.costUsd), 'what': tr(place.isHotel ? 'per_night' : 'ticket')});
    }
    if (place != null && intent != 'near' && intent != 'recommend') {
      final (status, _) = openStatus(place);
      return '${place.nameIn(lang)} — ${tr('city_${place.city}')}\n\n${place.descriptionIn(lang)}\n\n'
          '★ ${place.rating} • ${tr('visit_time')}: ${place.visitMinutes} ${tr('min')} • ${money(place.costUsd)}\n🕘 $status';
    }

    // "Qanday milliy taomlar bor?" -> taomlar haqida; "restoran bormi?" -> restoranlar ro'yxati
    final wantsPlace = ['restoran', 'restaurant', 'ресторан', 'kafe', 'cafe', 'кафе', 'choyxona', 'чайхан'].any(q.contains);
    if (intent == 'food' && place == null && !wantsPlace) return tr('as_food');
    if (intent == 'transport' || intent == 'festival') return tr('as_$intent');
    var pool = places.where((a) => (cat == null || a.category == cat) && (city == null || a.city == city)).toList();
    if (q.contains('ochiq') || q.contains('open now') || q.contains('открыт')) {
      pool = pool.where((a) => a.isOpenAt(DateTime.now())).toList();
    }
    if (intent == 'near' || (intent == null && cat != null)) {
      if (lat == null) {
        pool.sort((a, b) => b.rating.compareTo(a.rating));
        return '${tr('as_no_gps')}\n\n${_list(pool.take(5).toList(), lang)}';
      }
      pool.sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));
      return '${tr('as_nearest')}\n\n${_list(pool.take(5).toList(), lang)}';
    }
    if (intent == 'recommend' || cat != null || city != null) {
      pool.sort((a, b) => b.rating.compareTo(a.rating));
      if (pool.isEmpty) return tr('as_nothing');
      return '${tr('as_top')}\n\n${_list(pool.take(5).toList(), lang)}';
    }
    if (intent == 'food' && place == null) return tr('as_food');
    if (intent == 'transport') return tr('as_transport');
    if (intent == 'festival') return tr('as_festival');
    if (intent == 'route') return tr('as_route');
    if (intent == 'hello') return tr('as_hello');
    if (q.contains('qashqadaryo') || q.contains('kashkadar') || q.contains('кашкадар')) return tr('as_region');
    return tr('as_fallback');
  }
}
