import 'dart:convert';
import 'dart:io';

/// Automated update script for flutter_pas_tabler_icons.
///
/// Checks the latest version of @tabler/icons-webfont on npm,
/// compares it with the latest local git tag, and if a newer
/// version exists, downloads assets, updates pubspec.yaml,
/// CHANGELOG.md, and regenerates the icon definitions.
///
/// Outputs:
///   updated=true/false
///   version=X.Y.Z  (only when updated=true)
void main() async {
  final projectRoot = _findProjectRoot();

  // 1. Get latest version from npm registry
  final latestVersion = await _fetchLatestNpmVersion();
  print('Latest npm version: $latestVersion');

  // 2. Get current version from git tags
  final currentVersion = await _getCurrentVersionFromGitTags(projectRoot);
  print('Current local version: $currentVersion');

  // 3. Compare
  if (currentVersion == latestVersion) {
    print('Already up to date.');
    print('updated=false');
    return;
  }

  print('New version available: $currentVersion -> $latestVersion');

  // 4. Download assets from unpkg
  await _downloadAssets(latestVersion, projectRoot);

  // 5. Update pubspec.yaml
  _updatePubspec(latestVersion, projectRoot);

  // 6. Fetch changelog from Tabler GitHub releases
  final changelog = await _fetchChangelog(latestVersion);

  // 7. Update CHANGELOG.md
  _updateChangelog(latestVersion, changelog, projectRoot);

  // 8. Run generate_icons.dart
  await _runGenerateIcons(projectRoot);

  print('updated=true');
  print('version=$latestVersion');
}

// ---------------------------------------------------------------------------
// Project root detection
// ---------------------------------------------------------------------------

String _findProjectRoot() {
  // Walk up from the script location to find pubspec.yaml
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      // Fallback to current directory
      return Directory.current.path;
    }
    dir = parent;
  }
}

// ---------------------------------------------------------------------------
// NPM registry
// ---------------------------------------------------------------------------

Future<String> _fetchLatestNpmVersion() async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(
      Uri.parse('https://registry.npmjs.org/@tabler/icons-webfont/latest'),
    );
    final response = await request.close();
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch npm registry: HTTP ${response.statusCode}',
      );
    }
    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['version'] as String;
  } finally {
    client.close();
  }
}

// ---------------------------------------------------------------------------
// Git tags
// ---------------------------------------------------------------------------

Future<String> _getCurrentVersionFromGitTags(String projectRoot) async {
  // Get all tags matching v*, sort by version, pick the last one
  final result = await Process.run('git', [
    'tag',
    '--list',
    'v*',
    '--sort=version:refname',
  ], workingDirectory: projectRoot);

  if (result.exitCode != 0) {
    print('Warning: git tag failed, assuming no previous version.');
    return '0.0.0';
  }

  final tags = (result.stdout as String)
      .trim()
      .split('\n')
      .where((t) => t.isNotEmpty)
      .toList();

  if (tags.isEmpty) {
    print('No git tags found, assuming first release.');
    return '0.0.0';
  }

  // Last tag is the latest (sorted by version:refname)
  final latestTag = tags.last;
  // Strip leading 'v'
  return latestTag.startsWith('v') ? latestTag.substring(1) : latestTag;
}

// ---------------------------------------------------------------------------
// Asset download
// ---------------------------------------------------------------------------

const _unpkgBase = 'https://cdn.jsdelivr.net/npm/@tabler/icons-webfont';

final _filesToDownload = <String, String>{
  'dist/tabler-icons.css': 'assets/css/tabler-icons.css',
  'dist/tabler-icons-filled.css': 'assets/css/tabler-icons-filled.css',
  'dist/fonts/tabler-icons.ttf': 'assets/fonts/tabler-icons.ttf',
  'dist/fonts/tabler-icons-filled.ttf': 'assets/fonts/tabler-icons-filled.ttf',
};

Future<void> _downloadAssets(String version, String projectRoot) async {
  final client = HttpClient();
  try {
    for (final entry in _filesToDownload.entries) {
      final url = '$_unpkgBase@$version/${entry.key}';
      final destPath = '$projectRoot/${entry.value}';

      print('Downloading $url ...');

      const maxRetries = 3;
      for (var attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          final request = await client.getUrl(Uri.parse(url));
          final response = await request.close();

          if (response.statusCode != 200) {
            // Drain the response body to free the connection
            await response.drain<void>();
            if (attempt < maxRetries) {
              print(
                '  HTTP ${response.statusCode}, retrying ($attempt/$maxRetries)...',
              );
              await Future<void>.delayed(Duration(seconds: 2 * attempt));
              continue;
            }
            throw Exception(
              'Failed to download $url: HTTP ${response.statusCode}',
            );
          }

          final file = File(destPath);
          await file.parent.create(recursive: true);
          final sink = file.openWrite();
          await response.pipe(sink);

          final size = await file.length();
          print('  -> $destPath (${_formatBytes(size)})');
          break; // Success
        } catch (e) {
          if (e is Exception &&
              e.toString().contains('Failed to download') &&
              attempt == maxRetries) {
            rethrow;
          }
          if (attempt < maxRetries) {
            print('  Error: $e, retrying ($attempt/$maxRetries)...');
            await Future<void>.delayed(Duration(seconds: 2 * attempt));
          } else {
            rethrow;
          }
        }
      }
    }
  } finally {
    client.close();
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

// ---------------------------------------------------------------------------
// pubspec.yaml update
// ---------------------------------------------------------------------------

void _updatePubspec(String newVersion, String projectRoot) {
  final file = File('$projectRoot/pubspec.yaml');
  var content = file.readAsStringSync();

  // Replace version line (handles both placeholder and real versions)
  final versionRegex = RegExp(r'^version:\s*.+$', multiLine: true);
  if (!versionRegex.hasMatch(content)) {
    throw Exception('Could not find version: line in pubspec.yaml');
  }

  content = content.replaceFirst(versionRegex, 'version: $newVersion');
  file.writeAsStringSync(content);
  print('Updated pubspec.yaml to version $newVersion');
}

// ---------------------------------------------------------------------------
// Changelog from Tabler GitHub releases
// ---------------------------------------------------------------------------

Future<String> _fetchChangelog(String version) async {
  final client = HttpClient();
  try {
    final url =
        'https://api.github.com/repos/tabler/tabler-icons/releases/tags/v$version';
    final request = await client.getUrl(Uri.parse(url));
    request.headers.set('Accept', 'application/vnd.github.v3+json');
    request.headers.set('User-Agent', 'flutter_pas_tabler_icons-updater');

    final response = await request.close();
    if (response.statusCode != 200) {
      print(
        'Warning: Could not fetch release notes (HTTP ${response.statusCode})',
      );
      return 'Updated to Tabler Icons v$version.';
    }

    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body) as Map<String, dynamic>;
    final releaseBody = (json['body'] as String?) ?? '';

    if (releaseBody.trim().isEmpty) {
      return 'Updated to Tabler Icons v$version.';
    }

    // Clean up: remove \r\n -> \n, strip HTML image tags
    return releaseBody
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'<img[^>]*/?>', caseSensitive: false), '')
        .trim();
  } finally {
    client.close();
  }
}

// ---------------------------------------------------------------------------
// CHANGELOG.md update
// ---------------------------------------------------------------------------

void _updateChangelog(
  String version,
  String changelogBody,
  String projectRoot,
) {
  final file = File('$projectRoot/CHANGELOG.md');
  final existingContent = file.existsSync() ? file.readAsStringSync() : '';

  final newEntry = StringBuffer();
  newEntry.writeln('## $version');
  newEntry.writeln();
  newEntry.writeln(changelogBody);
  newEntry.writeln();

  file.writeAsStringSync('${newEntry}$existingContent');
  print('Updated CHANGELOG.md with version $version');
}

// ---------------------------------------------------------------------------
// Run generate_icons.dart
// ---------------------------------------------------------------------------

Future<void> _runGenerateIcons(String projectRoot) async {
  print('Running generate_icons.dart ...');
  final result = await Process.run('dart', [
    'run',
    'tool/generate_icons.dart',
  ], workingDirectory: projectRoot);

  stdout.write(result.stdout);
  stderr.write(result.stderr);

  if (result.exitCode != 0) {
    throw Exception(
      'generate_icons.dart failed with exit code ${result.exitCode}',
    );
  }
}
