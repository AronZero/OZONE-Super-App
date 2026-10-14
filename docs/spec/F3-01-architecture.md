# F3-01 · Architecture

Goal: a small, boring codebase that one Flutter developer can read in a day. Each tool is a self-contained module that plugs
into the shell, so new tools don't touch existing ones.

## 1. Layers

```
UI (screens, widgets)          lib/tools/<tool>/ui, lib/shell/ui
   ↓ reads/calls
State (Riverpod providers)     lib/tools/<tool>/state
   ↓ calls
Domain (pure Dart: rules, calculations, validation)   lib/tools/<tool>/domain, lib/core/domain
   ↓ uses
Data (drift tables, DAOs, repositories, workbook codec)  lib/tools/<tool>/data, lib/core/data
```

- **Domain is pure Dart.** No Flutter imports, no database. All of F1-04 (calculations) lives here and is unit-tested directly.
- **Repositories** are the only code that touches drift. Each write method keeps the search index and tombstones in step
  inside one transaction (F2-02 §1).
- **Riverpod** without code generation, so the code reads plainly. One provider per repository, plus `StreamProvider`s
  for lists that watch drift queries. Screens rebuild when data changes, with no manual refresh.
- **Navigation:** `go_router` with a `StatefulShellRoute` (one back stack per bar tab, docs/04). Every record has a deep-link
  path (`/finance/expenses/:id`), which search uses to open the exact record.

## 2. Folder layout

```
lib/
  main.dart                       app start (F2-03 §6 lifecycle)
  app.dart                        MaterialApp.router, themes, App lock gate
  core/
    data/                         database.dart (drift), migrations/, settings_repo.dart, deletions_repo.dart
    domain/                       money.dart (centavos, parsing, formatting), dates.dart, ids.dart, validation.dart
    security/                     vault_service.dart, app_lock_service.dart, secure_screen.dart
    search/                       search_index.dart, search_repo.dart, query_parser.dart
    workbook/                     workbook_codec.dart (interface), excel_codec.dart, export_service.dart, import_service.dart
    platform/                     files_channel.dart (Save to), notifications.dart
    ui/                           theme/ (tokens from docs/05), components/ (one file per component board), charts/
  shell/
    tool_registry.dart            the list of tools (below)
    ui/                           home/, dashboard/, settings/, tools_launcher/, edit_bar/, search/, welcome/, lock_gate/
  tools/
    finance/   data/ domain/ state/ ui/   (savings, gold, expenses)
    library/   data/ domain/ state/ ui/
    notes/     data/ domain/ state/ ui/
test/                             mirrors lib/
integration_test/                 end-to-end flows (F3-03)
assets/fonts/Manrope/             bundled font + OFL.txt
android/app/src/main/kotlin/…/FilesChannel.kt   "Save to" (ACTION_CREATE_DOCUMENT), about 60 lines
ios/Runner/FilesChannel.swift                    "Save to" (UIDocumentPickerViewController export), about 60 lines
```

## 3. Tool registry (how a tool plugs in)

Each tool exports one `ToolDefinition`. The shell reads `toolRegistry` and never imports tool internals.

```dart
class ToolDefinition {
  final String id;                 // 'finance' — stable, stored in settings bar.tools
  final String name;               // 'Finance'
  final ToolTint tint;             // accent + tile colours, light and dark (docs/05)
  final IconData icon;
  final String routeBase;          // '/finance'
  final List<RouteBase> routes;    // the tool's go_router routes
  final List<WidgetDefinition> widgets;          // dashboard widgets, with default order and on/off
  final List<QuickAddAction> quickAdd;           // entries for Home's add menu
  final List<SearchSource> searchSources;        // which entities it indexes and how a result opens
  final WorkbookSection workbook;                // sheets it writes and reads (F1-02)
  final List<SettingsEntry> settings;            // rows under Settings › Tools
  final List<TableInfo> Function(AppDatabase) tables;  // drift tables it owns
}

final toolRegistry = <ToolDefinition>[financeTool, libraryTool, notesTool];
```

Rules:

- The bar shows Home + up to 3 tools from `settings.bar.tools` + Tools; the launcher shows the rest (docs/03).
- A new tool's dashboard widgets start hidden (docs/04).
- A tool owns its tables and sheets. Cross-tool reads (Home widgets, search) go through the registry's interfaces only.
- Adding a tool = a new folder under `lib/tools/`, one line in `toolRegistry`, a schema migration, and a `format_version`
  check for its sheets.

## 4. Theme and components

- `core/ui/theme/tokens.dart` holds every colour, type and spacing token from docs/05, in light and dark. Widgets never
  hard-code colours.
- Tool tints come from `ToolDefinition.tint`. The shell stays neutral (docs/05 core rule).
- Each component on the Components boards becomes one widget in `core/ui/components/`, with a golden test in both themes (F3-03).
- Icons: Flutter's built-in Material icons, rounded style (`Icons.*_rounded`, Apache-2.0). No icon package.
- Charts: simple bar charts drawn with `CustomPaint` in `core/ui/charts/`. No chart package, because the needs are small
  and accessibility (table view, labels) is easier to control.

## 5. Errors

- Domain functions return results (`Ok` / `Invalid(reason)`). Messages for users are plain words in one place
  (`core/domain/messages.dart`) so they stay consistent with the States board.
- Unexpected exceptions show the W3 States error pattern with **Try again**, and keep what the user typed. Nothing is sent
  anywhere. A local, size-capped error log (no personal data) can be shared by the owner from Settings › About.

## 6. Code style

- `flutter_lints` plus the `strict-casts`, `strict-raw-types` and `prefer_final_locals` rules.
- Short files (aim under 300 lines), with names that match the canvas board titles.
- Comments explain **why**, not what. Each public domain function has a doc comment and an example from F1-04.
