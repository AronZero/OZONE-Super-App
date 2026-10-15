import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/settings_repo.dart';
import '../../../core/state/providers.dart';
import '../data/notes_repo.dart';

final notesRepoProvider = Provider<NotesRepo>((ref) => NotesRepo(ref.watch(databaseProvider), ref.watch(deletionsRepoProvider)));

/// Notes, folders and tags; screens rebuild whenever one changes.
final notesDataProvider = StreamProvider<NotesData>((ref) => ref.watch(notesRepoProvider).watch());

/// Notes home layout: grid (default) or list.
final notesViewProvider = StreamProvider<NotesView>((ref) => ref.watch(settingsRepoProvider).watch(SettingKeys.notesView));
