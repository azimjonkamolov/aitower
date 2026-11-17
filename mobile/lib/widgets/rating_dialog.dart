import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/attraction.dart';
import '../services/local_store.dart';
import '../theme.dart';

class StarPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;
  const StarPicker({super.key, required this.value, required this.onChanged, this.size = 34});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(i),
            icon: Icon(i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                color: AppColors.amber, size: size),
          ),
      ]);
}

/// Baho + izoh qoldirish oynasi (detal sahifasi, sharhlar va sayohat rejimi uchun).
Future<bool> showRatingDialog(BuildContext context, Attraction a) async {
  var stars = LocalStore.i.ratingOf(a.id) ?? 0;
  final ctrl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, set) => AlertDialog(
        title: Text(a.nameIn(Lang.current.value)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('your_rating')),
          StarPicker(value: stars, onChanged: (v) => set(() => stars = v)),
          const SizedBox(height: 8),
          TextField(controller: ctrl, maxLines: 3, decoration: InputDecoration(hintText: tr('comment_hint'))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('cancel'))),
          FilledButton(onPressed: stars == 0 ? null : () => Navigator.pop(c, true), child: Text(tr('save'))),
        ],
      ),
    ),
  );
  if (ok == true) {
    LocalStore.i.rate(a.id, stars);
    if (ctrl.text.trim().isNotEmpty) LocalStore.i.addComment(a.id, ctrl.text.trim());
  }
  return ok == true;
}
