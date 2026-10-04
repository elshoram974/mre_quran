import 'package:flutter/material.dart';
import '../../../core/widgets/empty_state.dart';

class BookmarksPage extends StatelessWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context) => const EmptyState(
    icon: Icons.bookmark_border,
    title: 'لا توجد علامات محفوظة',
    message: 'ستتمكن من حفظ موضع القراءة بعد إضافة بيانات المصحف.',
  );
}
