import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'exceptions.dart';

const _kLocalDepsExecutableName = 'local_deps';

const _kLocalDepsDescription = 'Get local path dependencies for a dart package';

class LocalDepsCommandRunner extends CommandRunner<int> {
  final Logger _logger = Logger();

  LocalDepsCommandRunner()
      : super(
          _kLocalDepsExecutableName,
          _kLocalDepsDescription,
        ) {
    argParser
      ..addOption(
        'separator',
        defaultsTo: ' ',
      )
      ..addFlag(
        'list',
        help: 'Breaks a new line for each local dependency found',
      );
  }

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final argResults = parse(args);
      final targetPath = _getPackagePath(argResults);

      final pathDependencies =
          await _getPathDependencies(targetPath, <String>{});

      final isList = argResults['list'] == true;

      final String message;
      if (isList) {
        message = pathDependencies
            .fold<StringBuffer>(
              StringBuffer(),
              (previousValue, element) => previousValue..writeln('- $element'),
            )
            .toString();
      } else {
        message = pathDependencies.join(' ');
      }

      _logger.info(message);
      return ExitCode.success.code;
    } on UsageException catch (e) {
      _logger
        ..err(e.message)
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    } on PathNotFoundException catch (e) {
      _logger.err(e.message);
      return ExitCode.unavailable.code;
    } on PubspecNotFoundException {
      _logger.err(
        'No pubspec.yaml file found.\n'
        'This command should receive a path to a dart package.',
      );
      return ExitCode.unavailable.code;
    }
  }

  String _getPackagePath(ArgResults argResults) {
    final rest = argResults.rest;

    if (rest.length > 1) {
      throw UsageException('Multiple output directories specified.', usage);
    }

    if (rest.isEmpty) {
      return '.';
    } else {
      return path.normalize(rest.single);
    }
  }
}

Future<Set<String>> _getPathDependencies(
  String targetPath,
  Set<String> collectedPaths,
) async {
  final targetDir = Directory(targetPath);
  if (!targetDir.existsSync()) {
    throw PathNotFoundException(targetPath);
  }

  final pubspecFile = File(path.join(targetPath, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    throw PubspecNotFoundException();
  }

  final dynamic yamlMap = loadYaml(pubspecFile.readAsStringSync());
  final pubspecMap = jsonDecode(jsonEncode(yamlMap)) as Map<String, dynamic>;

  final overrideDepPaths =
      _getPathDependenciesFromField(pubspecMap['dependency_overrides']);

  final devDepPaths =
      _getPathDependenciesFromField(pubspecMap['dev_dependencies']);

  final depPaths = _getPathDependenciesFromField(pubspecMap['dependencies']);

  final paths = [
    depPaths,
    devDepPaths,
    overrideDepPaths,
  ].expand((element) => element);

  final targetPathAbsolute = path.normalize(path.absolute(targetPath));
  for (final localPath in paths) {
    final joinedPath = path.relative(path.join(targetPathAbsolute, localPath));
    if (collectedPaths.contains(joinedPath)) {
      continue;
    }

    collectedPaths.add(joinedPath);
    await _getPathDependencies(joinedPath, collectedPaths);
  }

  return collectedPaths;
}

Iterable<String> _getPathDependenciesFromField(
  final dynamic packagesMap,
) sync* {
  if (packagesMap is! Map<String, dynamic>) {
    return;
  }
  for (final value in packagesMap.values) {
    if (value is! Map<String, dynamic>) {
      continue;
    }
    if (!value.containsKey('path')) {
      continue;
    }
    yield value['path'] as String;
  }
}

