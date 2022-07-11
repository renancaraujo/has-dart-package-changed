class PathNotFoundException implements Exception {
  const PathNotFoundException(this.targetPath);

  final String targetPath;

  String get message => 'Invalid path dependency $targetPath';
}

class PubspecNotFoundException implements Exception {}
