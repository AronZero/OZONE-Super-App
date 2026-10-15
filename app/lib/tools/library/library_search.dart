import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shell/tool_registry.dart';
import 'domain/library.dart';
import 'state/library_providers.dart';
import '../../core/ui/theme/oz_icons.dart';

/// Books in global search (F2-02 §1).
const List<SearchSource> librarySearch = [
  SearchSource(entity: 'book', group: 'Books', chip: 'Books', open: _open, describe: _book),
];

void _open(BuildContext context, WidgetRef ref, String id) => context.push('/library/books/$id');

SearchRowInfo? _book(BuildContext context, WidgetRef ref, String id) {
  final b = ref.watch(booksDataProvider).value?.byId(id);
  if (b == null) return null;
  return SearchRowInfo([?b.author, BookStatus.of(b.status).label].join(' · '));
}

/// Library's entry in Home's quick-add menu.
const List<QuickAddAction> libraryQuickAdd = [
  QuickAddAction(label: 'Add book', icon: OzIcons.menuBook, run: _addBook),
];

void _addBook(BuildContext context) => context.push('/library/add');
