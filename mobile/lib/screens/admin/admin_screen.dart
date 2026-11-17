import 'package:flutter/material.dart';
import '../../l10n/strings.dart';
import '../../models/attraction.dart';
import '../../services/data_service.dart';
import '../../services/local_store.dart';
import '../../theme.dart';
import 'analytics_tab.dart';
import 'place_editor.dart';

/// PIN so'rab administrator paneliga kiritadi (standart PIN: 1234).
Future<void> openAdmin(BuildContext context) async {
  final ctrl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(tr('admin_login')),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(hintText: tr('pin')),
        onSubmitted: (_) => Navigator.pop(c, ctrl.text == LocalStore.i.pin),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('cancel'))),
        FilledButton(onPressed: () => Navigator.pop(c, ctrl.text == LocalStore.i.pin), child: Text(tr('login'))),
      ],
    ),
  );
  if (!context.mounted || ok == null) return;
  if (!ok) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('wrong_pin'))));
    return;
  }
  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
}

/// Administrator va analitika moduli: obyektlarni boshqarish + statistika va hisobotlar.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Attraction> all = [];
  String q = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    DataService.invalidate();
    all = await DataService().attractions();
    if (mounted) setState(() {});
  }

  Future<void> _edit(Attraction? a) async {
    final changed = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => PlaceEditor(place: a, usedIds: all.map((e) => e.id))));
    if (changed == true) _load();
  }

  Future<void> _changePin() async {
    final ctrl = TextEditingController();
    final v = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('change_pin')),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: tr('new_pin'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(tr('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: Text(tr('save'))),
        ],
      ),
    );
    if (v != null && v.length >= 4) {
      LocalStore.i.pin = v;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('saved'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Lang.current.value;
    final shown = all.where((a) => q.isEmpty || a.nameIn(lang).toLowerCase().contains(q.toLowerCase())).toList();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('nav_admin')),
          actions: [IconButton(tooltip: tr('change_pin'), onPressed: _changePin, icon: const Icon(Icons.password))],
          bottom: TabBar(
            labelColor: AppColors.amber400,
            unselectedLabelColor: AppColors.stone400,
            indicatorColor: AppColors.amber,
            tabs: [Tab(text: tr('adm_objects')), Tab(text: tr('adm_analytics'))],
          ),
        ),
        body: TabBarView(children: [
          Scaffold(
            floatingActionButton: FloatingActionButton.extended(
                heroTag: 'add', onPressed: () => _edit(null), icon: const Icon(Icons.add), label: Text(tr('add_object'))),
            body: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 96), children: [
              TextField(
                  decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: tr('search')),
                  onChanged: (v) => setState(() => q = v)),
              const SizedBox(height: 8),
              Text('${all.length} ${tr('objects')}', style: const TextStyle(color: AppColors.stone500)),
              for (final a in shown)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                      backgroundColor: CatStyle.of(a.category).bg,
                      child: Icon(CatStyle.of(a.category).icon, color: CatStyle.of(a.category).fg, size: 20)),
                  title: Text(a.nameIn(lang)),
                  subtitle: Text('${tr('city_${a.city}')} • ${a.hours} • ★${a.rating}'),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _edit(a),
                ),
            ]),
          ),
          const AnalyticsTab(),
        ]),
      ),
    );
  }
}
