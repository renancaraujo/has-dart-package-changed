import 'dart:io';
import 'package:local_deps/src/local_deps.dart';


Future<void> main(List<String> args) async {
  await _flushThenExit(await LocalDepsCommandRunner().run(args));
}

/// Flushes the stdout and stderr streams, then exits the program with the given
/// status code.
///
/// This returns a Future that will never complete, since the program will have
/// exited already. This is useful to preventq Future chains from proceeding
/// after you've decided to exit.
Future _flushThenExit(int status) {
  return Future.wait<void>([stdout.close(), stderr.close()])
      .then<void>((_) => exit(status));
}
