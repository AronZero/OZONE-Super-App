import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/platform/external_activity.dart';
import '../../../core/state/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../../core/ui/theme/oz_icons.dart';
import '../../../core/ui/motion.dart';

/// Settings › Data & backup › Safety exports: the copies saved before each
/// import (newest 3), to import back ("To go back…", F1-03 §2) or share.
class SafetyExportsScreen extends ConsumerStatefulWidget {
  const SafetyExportsScreen({super.key});

  @override
  ConsumerState<SafetyExportsScreen> createState() => _SafetyExportsScreenState();
}

class _SafetyExportsScreenState extends ConsumerState<SafetyExportsScreen> {
  late Future<List<File>> _files = ref.read(backupServiceProvider).safetyExports();

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xxxl),
          children: staggered([
            const DetailTopBar(title: 'Safety exports', overline: 'Data & backup'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.screen),
              child: FutureBuilder<List<File>>(
                future: _files,
                builder: (context, snap) {
                  final files = snap.data;
                  if (files == null) return const SizedBox.shrink();
                  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Space.xs, 0, Space.xs, Space.m),
                      child: Text('OZONE saves a full copy here before each import, and keeps the newest 3. They stay inside the app.',
                          style: text.bodyMedium!.copyWith(fontSize: 13.5, height: 1.5, color: c.inkMuted)),
                    ),
                    if (files.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(Space.xl),
                        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
                        child: Text('No safety exports yet. One is made before your first import.', style: text.bodyLarge!.copyWith(color: c.inkMuted)),
                      )
                    else
                      GroupCard(children: [
                        for (final f in files)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.s, Space.m),
                            child: Row(children: [
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(f.uri.pathSegments.last, style: text.bodyLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                                  Text('${(f.lengthSync() / 1024).ceil()} KB', style: text.bodyMedium!.copyWith(fontSize: 12.5, color: c.inkMuted)),
                                ]),
                              ),
                              IconButton(
                                tooltip: 'Share ${f.uri.pathSegments.last}',
                                onPressed: () => ExternalActivity.run(() => SharePlus.instance.share(ShareParams(files: [XFile(f.path)]))),
                                icon: Icon(OzIcons.iosShare, color: c.ink),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await context.push('/settings/data/import', extra: f);
                                  if (mounted) setState(() => _files = ref.read(backupServiceProvider).safetyExports());
                                },
                                style: TextButton.styleFrom(foregroundColor: c.ink, minimumSize: const Size(48, 48)),
                                child: const Text('Import', style: TextStyle(fontWeight: FontWeight.w800)),
                              ),
                            ]),
                          ),
                      ]),
                  ]);
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
