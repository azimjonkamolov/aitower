import 'package:flutter/material.dart';
import '../../l10n/strings.dart';
import '../../models/attraction.dart';
import '../../services/data_service.dart';
import '../../services/local_store.dart';
import '../../theme.dart';

/// Obyektni qo'shish / tahrirlash / o'chirish formasi.
class PlaceEditor extends StatefulWidget {
  final Attraction? place;
  final Iterable<int> usedIds;
  const PlaceEditor({super.key, this.place, required this.usedIds});
  @override
  State<PlaceEditor> createState() => _PlaceEditorState();
}

class _PlaceEditorState extends State<PlaceEditor> {
  static const cities = ['shahrisabz', 'qarshi', 'kitob', 'qamashi', 'kasbi', 'guzor', 'yakkabog', 'chiroqchi', 'mirishkor', 'dehqonobod'];
  static const cats = ['ziyorat', 'tarix', 'tabiat', 'mehmonxona', 'taom', 'dam'];
  final form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> c;
  late String city, category;
  late Set<int> closed;

  @override
  void initState() {
    super.initState();
    final a = widget.place;
    TextEditingController t(String? v) => TextEditingController(text: v ?? '');
    c = {
      for (final l in ['uz', 'ru', 'en']) 'name_$l': t(a?.name[l]),
      for (final l in ['uz', 'ru', 'en']) 'desc_$l': t(a?.description[l]),
      'lat': t(a?.lat.toString()),
      'lon': t(a?.lon.toString()),
      'rating': t((a?.rating ?? 4.5).toString()),
      'visit': t((a?.visitMinutes ?? 60).toString()),
      'cost': t((a?.costUsd ?? 0).toString()),
      'hours': t(a?.hours ?? '09:00-18:00'),
      'tags': t(a?.tags.join(', ')),
    };
    city = a?.city ?? 'shahrisabz';
    category = a?.category ?? 'tarix';
    closed = {...?a?.closedDays};
  }

  void _save() {
    if (!form.currentState!.validate()) return;
    final id = widget.place?.id ?? LocalStore.i.nextId(widget.usedIds);
    final a = Attraction.fromJson({
      'id': id,
      'city': city,
      'category': category,
      'tags': c['tags']!.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      'name': {for (final l in ['uz', 'ru', 'en']) l: c['name_$l']!.text.trim()},
      'description': {for (final l in ['uz', 'ru', 'en']) l: c['desc_$l']!.text.trim()},
      'lat': double.parse(c['lat']!.text),
      'lon': double.parse(c['lon']!.text),
      'rating': double.parse(c['rating']!.text),
      'visit_minutes': int.parse(c['visit']!.text),
      'cost_usd': double.parse(c['cost']!.text),
      'hours': c['hours']!.text.trim(),
      'closed_days': closed.toList()..sort(),
    });
    LocalStore.i.savePlace(a);
    DataService.invalidate();
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(tr('delete_q')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(tr('cancel'))),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(d, true),
              child: Text(tr('delete'))),
        ],
      ),
    );
    if (ok == true && mounted) {
      LocalStore.i.deletePlace(widget.place!.id);
      DataService.invalidate();
      Navigator.pop(context, true);
    }
  }

  Widget _field(String key, String label, {bool required = false, String? Function(String)? check, int lines = 1, TextInputType? kb}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: c[key],
          maxLines: lines,
          keyboardType: kb,
          decoration: InputDecoration(labelText: label),
          validator: (v) {
            v = v?.trim() ?? '';
            if (required && v.isEmpty) return tr('required');
            return v.isEmpty ? null : check?.call(v);
          },
        ),
      );

  String? _num(String v) => double.tryParse(v) == null ? tr('bad_number') : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.place == null ? tr('add_object') : tr('edit_object')),
        actions: [if (widget.place != null) IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline))],
      ),
      body: Form(
        key: form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _field('name_uz', '${tr('name')} (UZ)', required: true),
          _field('name_ru', '${tr('name')} (RU)'),
          _field('name_en', '${tr('name')} (EN)'),
          _field('desc_uz', '${tr('description')} (UZ)', lines: 3),
          _field('desc_ru', '${tr('description')} (RU)', lines: 3),
          _field('desc_en', '${tr('description')} (EN)', lines: 3),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: category,
                decoration: InputDecoration(labelText: tr('category')),
                items: [for (final k in cats) DropdownMenuItem(value: k, child: Text(tr('cat_$k')))],
                onChanged: (v) => setState(() => category = v!),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: cities.contains(city) ? city : cities.first,
                decoration: InputDecoration(labelText: tr('district')),
                items: [for (final k in cities) DropdownMenuItem(value: k, child: Text(tr('city_$k')))],
                onChanged: (v) => setState(() => city = v!),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _field('lat', tr('latitude'), required: true, check: _num, kb: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _field('lon', tr('longitude'), required: true, check: _num, kb: TextInputType.number)),
          ]),
          Row(children: [
            Expanded(child: _field('rating', tr('rating'), required: true, check: _num, kb: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _field('visit', '${tr('visit_time')} (${tr('min')})', required: true, check: (v) => int.tryParse(v) == null ? tr('bad_number') : null, kb: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _field('cost', '\$', required: true, check: _num, kb: TextInputType.number)),
          ]),
          _field('hours', '${tr('hours')} (09:00-18:00)', required: true, check: (v) => Attraction.validHours(v) ? null : tr('bad_hours')),
          Text(tr('closed_days'), style: const TextStyle(color: AppColors.stone500)),
          Wrap(spacing: 6, children: [
            for (var d = 1; d <= 7; d++)
              FilterChip(
                label: Text(tr('wd$d')),
                selected: closed.contains(d),
                onSelected: (v) => setState(() => v ? closed.add(d) : closed.remove(d)),
              ),
          ]),
          const SizedBox(height: 10),
          _field('tags', tr('tags_hint')),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: Text(tr('save'))),
        ]),
      ),
    );
  }
}
