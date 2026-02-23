import 'dart:io';

void main() {
  final outlineCss = File('assets/css/tabler-icons.css');
  final filledCss = File('assets/css/tabler-icons-filled.css');
  final outputFile = File('lib/flutter_pas_tabler_icons.dart');

  final icons = <String, IconDefinition>{};

  if (outlineCss.existsSync()) {
    parseCss(outlineCss, icons, false);
  }

  if (filledCss.existsSync()) {
    parseCss(filledCss, icons, true);
  }

  final buffer = StringBuffer();
  buffer.writeln("// GENERATED CODE - DO NOT MODIFY BY HAND");
  buffer.writeln("import 'package:flutter/widgets.dart';");
  buffer.writeln();
  buffer.writeln('class TablerIcons {');
  buffer.writeln('  TablerIcons._();');
  buffer.writeln();
  buffer.writeln("  static const String _kFontFam = 'tabler-icons';");
  buffer.writeln("  static const String _kFontPkg = 'tabler_icons';");
  buffer.writeln(
    "  static const String _kFontFamFilled = 'tabler-icons-filled';",
  );
  buffer.writeln();

  final sortedKeys = icons.keys.toList()..sort();

  for (final name in sortedKeys) {
    final def = icons[name]!;
    final validName = sanitizeName(name);
    final familyVar = def.isFilled ? '_kFontFamFilled' : '_kFontFam';

    buffer.writeln(
      '  static const IconData $validName = IconData(0x${def.code}, fontFamily: $familyVar, fontPackage: _kFontPkg);',
    );
  }

  buffer.writeln('}');

  outputFile.writeAsStringSync(buffer.toString());
  print('Generated ${icons.length} icons in ${outputFile.path}.');
}

class IconDefinition {
  final String code;
  final bool isFilled;
  IconDefinition(this.code, this.isFilled);
}

void parseCss(File file, Map<String, IconDefinition> icons, bool isFilled) {
  final content = file.readAsStringSync();
  // Regex to match .ti-icon-name:before { content: "\e001"; }
  final regex = RegExp(
    r'\.ti-([\w-]+):before\s*\{\s*content:\s*"\\([0-9a-fA-F]+)";\s*\}',
  );

  for (final match in regex.allMatches(content)) {
    var name = match.group(1)!.replaceAll('-', '_');
    final code = match.group(2)!;

    if (isFilled) {
      name = '${name}_filled';
    }

    icons[name] = IconDefinition(code, isFilled);
  }
}

String sanitizeName(String name) {
  const keywords = {
    'abstract',
    'as',
    'assert',
    'async',
    'await',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'covariant',
    'default',
    'deferred',
    'do',
    'dynamic',
    'else',
    'enum',
    'export',
    'extends',
    'extension',
    'external',
    'factory',
    'false',
    'final',
    'finally',
    'for',
    'function',
    'get',
    'hide',
    'if',
    'implements',
    'import',
    'in',
    'interface',
    'is',
    'late',
    'library',
    'mixin',
    'new',
    'null',
    'on',
    'operator',
    'part',
    'rethrow',
    'return',
    'set',
    'show',
    'static',
    'super',
    'switch',
    'sync',
    'this',
    'throw',
    'true',
    'try',
    'typedef',
    'var',
    'void',
    'while',
    'with',
    'yield',
    'int',
    'double',
    'String',
    'bool',
    'List',
    'Map',
    'Set',
    'Function',
  };

  if (name.startsWith(RegExp(r'\d'))) {
    return 'icon_$name';
  }

  if (keywords.contains(name)) {
    return 'icon_$name';
  }

  return name;
}
