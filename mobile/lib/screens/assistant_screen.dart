import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../services/app_state.dart';
import '../services/assistant.dart';
import '../services/data_service.dart';
import '../services/local_store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// "Virtual turistik yordamchi": chat ko'rinishidagi savol-javob.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});
  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final ctrl = TextEditingController();
  final scroll = ScrollController();
  final msgs = <(bool, String)>[]; // (foydalanuvchimi, matn)

  Future<void> _ask(String q) async {
    if (q.trim().isEmpty) return;
    final places = await DataService().attractions();
    final pos = AppState.position.value;
    final a = Assistant(places, lat: pos?.latitude, lon: pos?.longitude).answer(q);
    LocalStore.i.recordQuestion();
    setState(() {
      msgs.add((true, q.trim()));
      msgs.add((false, a));
    });
    ctrl.clear();
    await Future.delayed(const Duration(milliseconds: 50));
    if (scroll.hasClients) scroll.animateTo(scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  Widget _bubble(bool mine, String text) => Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!mine)
            Container(
              margin: const EdgeInsets.only(right: 8, top: 2),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.smart_toy_outlined, size: 18, color: AppColors.stone900),
            ),
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: mine ? AppColors.stone900 : AppColors.stone100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(text, style: TextStyle(color: mine ? Colors.white : AppColors.stone900, height: 1.35)),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final suggestions = [for (var i = 1; i <= 6; i++) tr('sugg$i')];
    return maxWidth(Column(children: [
      PageHeader(icon: Icons.chat_bubble_outline, title: tr('as_title'), subtitle: tr('as_sub')),
      Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.stone200)),
          child: ListView(controller: scroll, children: [
            _bubble(false, tr('as_greeting')),
            for (final m in msgs) _bubble(m.$1, m.$2),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(children: [
          const Icon(Icons.auto_awesome, size: 14, color: AppColors.amber600),
          const SizedBox(width: 4),
          Text(tr('suggested'), style: const TextStyle(fontSize: 12, color: AppColors.stone500)),
        ]),
      ),
      SizedBox(
        height: 44,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), children: [
          for (final s in suggestions)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                backgroundColor: AppColors.amber50,
                side: const BorderSide(color: Color(0xFFFDE68A)),
                label: Text(s, style: const TextStyle(fontSize: 12, color: AppColors.amber600)),
                onPressed: () => _ask(s),
              ),
            ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              textInputAction: TextInputAction.send,
              onSubmitted: _ask,
              decoration: InputDecoration(hintText: tr('type_message')),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            style: IconButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: AppColors.stone900),
            onPressed: () => _ask(ctrl.text),
            icon: const Icon(Icons.send),
          ),
        ]),
      ),
    ]), 900);
  }
}
