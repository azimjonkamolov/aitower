import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/attraction.dart';
import '../theme.dart';

String hm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
String hmMin(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
String money(double usd) => usd == 0 ? tr('free') : '\$${usd.toStringAsFixed(usd < 10 ? 1 : 0)}';

/// "Kun bo'yi ochiq" / "Hozir ochiq · 18:00 gacha" / "Hozir yopiq · 09:00 da ochiladi".
(String, bool) openStatus(Attraction a, [DateTime? at]) {
  final t = at ?? DateTime.now();
  if (a.alwaysOpen) return (tr('open_24h'), true);
  if (a.isOpenAt(t)) return (tr('open_until').replaceAll('{t}', hmMin(a.closeMin % 1440)), true);
  if (!a.openOnDay(t)) return (tr('closed_today'), false);
  final m = t.hour * 60 + t.minute;
  return (m < a.openMin ? tr('opens_at').replaceAll('{t}', hmMin(a.openMin)) : tr('closed_now'), false);
}

class CategoryBadge extends StatelessWidget {
  final String category;
  const CategoryBadge(this.category, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = CatStyle.of(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(20)),
      child: Text(tr('cat_$category'), style: TextStyle(color: s.fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class RatingPill extends StatelessWidget {
  final double rating;
  const RatingPill(this.rating, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.star_rounded, size: 16, color: AppColors.amber),
          const SizedBox(width: 2),
          Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      );
}

class OpenDot extends StatelessWidget {
  final Attraction a;
  const OpenDot(this.a, {super.key});
  @override
  Widget build(BuildContext context) {
    final (text, open) = openStatus(a);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.schedule, size: 14, color: open ? AppColors.green : AppColors.red),
      const SizedBox(width: 4),
      Flexible(
          child: Text(text,
              style: TextStyle(fontSize: 12, color: open ? AppColors.green : AppColors.red, fontWeight: FontWeight.w500))),
    ]);
  }
}

/// Saytdagidek sarlavha: katta qalin sarlavha + kulrang izoh.
class PageHeader extends StatelessWidget {
  final IconData? icon;
  final String title, subtitle;
  const PageHeader({super.key, this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (icon != null) ...[Icon(icon, color: AppColors.amber, size: 26), const SizedBox(width: 8)],
            Expanded(
                child: Text(title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.stone900))),
          ]),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.stone500)),
        ]),
      );
}

class SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  const SectionCard({super.key, this.title, required this.child});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (title != null) ...[
              Text(title!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 12),
            ],
            child,
          ]),
        ),
      );
}

/// UZ / RU / EN tugmasi (saytning yuqori o'ng burchagidagidek).
class LangSwitch extends StatelessWidget {
  const LangSwitch({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: AppColors.stone800, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final c in ['uz', 'ru', 'en'])
            GestureDetector(
              onTap: () => Lang.set(c),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                    color: Lang.current.value == c ? AppColors.amber : Colors.transparent,
                    borderRadius: BorderRadius.circular(16)),
                child: Text(c.toUpperCase(),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Lang.current.value == c ? AppColors.stone900 : AppColors.stone400)),
              ),
            ),
        ]),
      );
}

class LogoTitle extends StatelessWidget {
  const LogoTitle({super.key});
  @override
  Widget build(BuildContext context) => Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(9), child: Image.asset('assets/logo.png', width: 36, height: 36)),
        const SizedBox(width: 10),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('AI Smart Tourism', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          Text('Qashqadaryo', style: TextStyle(fontSize: 12, color: AppColors.amber400, fontWeight: FontWeight.w600)),
        ]),
      ]);
}

/// Kartalarni ekran kengligiga qarab 1–4 ustunda joylaydi (telefon: 1, planshet: 2–3).
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth, spacing;
  const ResponsiveGrid({super.key, required this.children, this.minItemWidth = 340, this.spacing = 12});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final cols = (c.maxWidth / minItemWidth).floor().clamp(1, 4);
        final w = (c.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [for (final ch in children) SizedBox(width: w, child: ch)],
        );
      });
}

/// Planshetda sahifa mazmunini qulay kenglikda markazga qo'yadi.
Widget maxWidth(Widget child, [double width = 860]) =>
    Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: BoxConstraints(maxWidth: width), child: child));
