import 'dart:io';
import 'package:logger/logger.dart';

Future<void> main() async {
  final logger = Logger();
  final result = await Process.run(
    'git',
    ['rev-parse', '--short', 'HEAD'],
    runInShell: true,
  );

  if (result.exitCode != 0) {
    // ignore: avoid_print
    logger.e('❌ Error getting git commit: ${result.stderr}');
    exit(1);
  }

  final gitCommit = (result.stdout as String).trim();
  logger.i('🌀 Current git commit: $gitCommit');

  final file = File('lib/build_version.dart');
  final content = '''
/// Auto-generated file. Do not edit manually.
const String buildVersion = '$gitCommit';
''';

  await file.writeAsString(content, flush: true);
  logger.i('✅ Wrote lib/build_version.dart');

  final process = await Process.start(
    'flutter',
    ['build', 'web'],
    runInShell: true,
  );

  await stdout.addStream(process.stdout);
  await stderr.addStream(process.stderr);

  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    stderr.writeln('❌ Flutter build failed ($exitCode)');
    exit(exitCode);
  }

  final indexFile = File('build/web/index.html');
  var html = await indexFile.readAsString();

  html = html.replaceAll(
    'flutter_bootstrap.js',
    'flutter_bootstrap.js?v=$gitCommit',
  );

  await indexFile.writeAsString(html);
  logger.i('🔄 index.html updated with version: $gitCommit');

  logger.i('🚀 Flutter web build complete.');
}
