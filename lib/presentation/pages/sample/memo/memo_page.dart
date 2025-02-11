import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../extensions/context_extension.dart';
import 'memo_async_notifier_page.dart';
import 'memo_state_notifier_page.dart';

class MemoPage extends HookConsumerWidget {
  const MemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'メモ',
          style: context.subtitleStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          child: Column(
            children: [
              ListTile(
                title: Text(
                  'StateNotifierのサンプル',
                  style:
                      context.bodyStyle.copyWith(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                ),
                onTap: () {
                  MemoStateNotifierPage.show(context);
                },
              ),
              const Divider(height: 1),
              ListTile(
                title: Text(
                  'AsyncNotifierのサンプル',
                  style:
                      context.bodyStyle.copyWith(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                ),
                onTap: () {
                  MemoAsyncNotifierPage.show(context);
                },
              ),
              const Divider(height: 1),
            ],
          ),
        ),
      ),
    );
  }
}
