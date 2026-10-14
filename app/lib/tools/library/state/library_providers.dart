import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/providers.dart';
import '../data/books_repo.dart';

final booksRepoProvider = Provider<BooksRepo>((ref) => BooksRepo(ref.watch(databaseProvider), ref.watch(deletionsRepoProvider)));

/// All books; screens rebuild whenever one changes.
final booksDataProvider = StreamProvider<BooksData>((ref) => ref.watch(booksRepoProvider).watch());
