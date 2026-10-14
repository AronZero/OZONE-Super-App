import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Manrope is bundled, so its SIL OFL licence is registered for Settings › About › Licences.
  LicenseRegistry.addLicense(() async* {
    final ofl = await rootBundle.loadString('assets/fonts/Manrope/OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Manrope (font)'], ofl);
  });

  runApp(const ProviderScope(child: OzoneApp()));
}
