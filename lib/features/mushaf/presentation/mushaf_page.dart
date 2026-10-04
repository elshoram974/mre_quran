import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';

class MushafPage extends StatelessWidget {
  const MushafPage({super.key});

  @override
  Widget build(BuildContext context) => const EmptyState(
    icon: Icons.menu_book_outlined,
    title: 'المصحف',
    message: 'لم تتم إضافة بيانات المصحف بعد. ستتوفر القراءة بعد ربط مصدر النص المعتمد.',
  );
}
