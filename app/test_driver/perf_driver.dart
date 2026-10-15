import 'package:integration_test/integration_test_driver.dart';

/// Writes the performance numbers of integration_test/perf_test.dart to build/perf.json.
Future<void> main() => integrationDriver(responseDataCallback: (data) => writeResponseData(data, testOutputFilename: 'perf'));
