// Copyright (c) 2015, the Fletch project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library dart.system;

import 'dart:_internal';
import 'dart:collection';
import 'dart:math';

part 'list.dart';
part 'map.dart';

const native = "native";

const wrongArgumentType = "Wrong argument type.";
const indexOutOfBounds = "Index out of bounds.";
const illegalState = "Illegal state.";

/// This is a magic method recognized by the compiler, and references to it
/// will be substituted for the actual main method.
/// [arguments] is supposed to be a List<String> with command line arguments.
/// [isolateArgument] is an extra argument that can be passed via
/// [Isolate.spawnUri].
external invokeMain([arguments, isolateArgument]);

/// Trivial wrapper around invokeMain to make it easy to patch changes to main
/// (since invokeMain is handled specially by the compiler).
// TODO(ahe): Remove this.
callMain(arguments) => invokeMain(arguments);

/// This is the main entry point for a Fletch program, and it takes care of
/// calling "main" and exiting the VM when "main" is done.
void entry(int mainArity) {
  var result;
  do {
    result = callMain([]);
  } while (!isMainDone);
  Thread.exit(result);
}

/// No-op method used for testing of incremental compiler. The compiler will
/// set a break point here, to get notified that main is done.
bool get isMainDone => mainIsDone;

const bool mainIsDone = true;

runToEnd(entry) {
  Thread.exit(entry());
}

unresolved(name) {
  throw new NoSuchMethodError(
      null,
      name,
      null,
      null);
}

compileError() {
  print("Compile error");
  halt(254);
}

@native halt(int code) {
  yield(true);
}

@native external printString(String s);

/// Exits the VM cleanly.
external yield(bool halt);

external get nativeError;

// Change execution to [coroutine], passing along [argument].
external coroutineChange(coroutine, argument);
