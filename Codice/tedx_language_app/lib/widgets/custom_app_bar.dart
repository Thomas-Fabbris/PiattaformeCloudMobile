// lib/widgets/custom_app_bar.dart

import 'package:flutter/material.dart';
import '../screens/talk_search_delegate.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showSearchAction;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showSearchAction = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE62B1E), Color(0xFFB71C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
      actions: [
        if (showSearchAction)
          IconButton(
            onPressed: () {
              showSearch(context: context, delegate: TalkSearchDelegate());
            },
            icon: const Icon(Icons.search),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
