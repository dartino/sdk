// Copyright (c) 2015, the Dartino project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

/// A low-level 'foreign function interface' library that allows Dart code to
/// call arbitrary native platform code defined outside the VM.
library dart.dartino.ffi;

import 'dart:dartino._ffi';
import 'dart:dartino._system' as dartino;
import 'dart:dartino';
import 'dart:typed_data';

part 'utf.dart';

abstract class Foreign {
  int get address;

  const Foreign();

  static const int UNKNOWN = 0;

  // These constants must be in sync with the enum OperatingSystem in
  // src/shared/platform.h.
  static const int LINUX = 1;
  static const int MACOS = 2;
  static const int ANDROID = 3;
  static const int WINDOWS = 4;
  static const int FREERTOS = 5;

  static const int IA32 = 1;
  static const int X64 = 2;
  static const int ARM = 3;

  // TODO(kasperl): Not quite sure where this fits in.
  static final int bitsPerMachineWord = _bitsPerMachineWord();
  static final int machineWordSize = bitsPerMachineWord ~/ 8;
  static final int platform = _platform();
  static final int architecture = _architecture();
  /// The bit size of doubles.
  ///
  /// With IEEE double-precision floating-point numbers returns 64. On some
  /// embedded devices [double]s are compiled to single-precision floats, in
  /// which case the size is 32.
  static final int bitsPerDouble = _bitsPerDouble();

  static int get errno => _errno();

  /**
   * Registers the foreign function [fn] to be called as finalizer for this
   * [Foreign] object.
   *
   * At finalization time, [argument] will be passed as argument to [fn].
   * [argument] may be any pointer sized value except 0.
   */
  void registerFinalizer(ForeignFunction fn, int argument) {
    if (argument == 0) throw new ArgumentError.value(argument);
    _registerFinalizer(fn.address, argument);
  }

  /**
   * Removes the foreign function [fn] from the list of finalizers for this
   * [Foreign] object.
   *
   * Returns 'true' if [fn] had previously been registered and was removed.
   * However, if [fn] has been registered multiple times, it may still be
   * called at finalization time.
   */
  bool removeFinalizer(ForeignFunction fn) {
    return _removeFinalizer(fn.address);
  }

  dynamic _convert(argument) => ForeignConversion.convert(argument);

  @dartino.native static int _bitsPerMachineWord() {
    throw new UnsupportedError('_bitsPerMachineWord');
  }
  @dartino.native static int _bitsPerDouble() {
    throw new UnsupportedError('_bitsPerDouble');
  }

  @dartino.native static int _errno() {
    throw new UnsupportedError('_errno');
  }
  @dartino.native static int _platform() {
    throw new UnsupportedError('_platform');
  }
  @dartino.native static int _architecture() {
    throw new UnsupportedError('_architecture');
  }

  @dartino.native void _registerFinalizer(int address, int argument) {
    var error = dartino.nativeError;
    if (error == dartino.illegalState) {
      throw new ArgumentError(argument);
    }
    throw error;
  }

  @dartino.native bool _removeFinalizer(int address) {
    var error = dartino.nativeError;
    if (error == dartino.illegalState) {
      throw new ArgumentError(address);
    }
    throw error;
  }
}

class ResourceExhaustedException implements Exception {
  final String message;

  ResourceExhaustedException(String this.message);

  String toString() => "Out of resources: $message.";
}

class ForeignFunction extends Foreign {
  final int address;
  final ForeignLibrary _library;

  /// Wraps the given [address] as a foreign function.
  ///
  /// The [address] must point to a function with standard C calling
  /// conventions.
  const ForeignFunction.fromAddress(this.address, [this._library = null]);

  /// Helper function for retrying functions that follow the POSIX-convention
  /// of returning `-1` and setting `errno` to `EINTR`.
  ///
  /// The function [f] will be retried as long as it is returning returning
  /// `-1` and `errno` is `EINTR`. When that is not the case the return value
  /// will be the return value of `f`.
  static int retry(Function f) {
    const EINTR = 4;
    int value;
    while ((value = f()) == -1) {
      if (Foreign.errno != EINTR) break;
    }
    return value;
  }

  /// Returns a signed bit-representation of the given [float].
  ///
  /// Returns a 64-bit signed integer for double-precision numbers.
  /// Returns a 32-bit signed integer for single-precision numbers.
  ///
  /// By using signed integers, the returned number is guaranteed to fit into
  /// native words, if the floating-point size is smaller or equal to the
  /// word size.
  @dartino.native static int doubleToSignedBits(double float) {
    throw new ArgumentError();
  }

  /// Returns the double corresponding to the given signed bit-representation
  /// [bits].
  @dartino.native static double signedBitsToDouble(int bits) {
    throw new ArgumentError();
  }

  // Support for calling foreign functions that return
  // integers.
  int icall$0() => _icall$0(address);
  int icall$1(a0) => _icall$1(address, _convert(a0));
  int icall$2(a0, a1) => _icall$2(address, _convert(a0), _convert(a1));
  int icall$3(a0, a1, a2) {
    return _icall$3(address, _convert(a0), _convert(a1), _convert(a2));
  }

  int icall$4(a0, a1, a2, a3) {
    return _icall$4(
        address, _convert(a0), _convert(a1), _convert(a2), _convert(a3));
  }

  int icall$5(a0, a1, a2, a3, a4) {
    return _icall$5(address, _convert(a0), _convert(a1), _convert(a2),
        _convert(a3), _convert(a4));
  }

  int icall$6(a0, a1, a2, a3, a4, a5) {
    return _icall$6(address, _convert(a0), _convert(a1), _convert(a2),
        _convert(a3), _convert(a4), _convert(a5));
  }

  int icall$7(a0, a1, a2, a3, a4, a5, a6) {
    return _icall$7(address, _convert(a0), _convert(a1), _convert(a2),
        _convert(a3), _convert(a4), _convert(a5), _convert(a6));
  }

  int callv(int returnType, int len, args, types) {
    return _callv(address, returnType, len, args, types);
  }

  // Support for calling foreign functions that return
  // integers. The functions with the suffix `Retry` can be used for calling
  // functions that follow functions that follow the POSIX-convention
  // of returning `-1` and setting `errno` to `EINTR` when they where
  // interrupted and should be retried.
  int icall$0Retry() => retry(() => icall$0());
  int icall$1Retry(a0) => retry(() => icall$1(a0));
  int icall$2Retry(a0, a1) => retry(() => icall$2(a0, a1));
  int icall$3Retry(a0, a1, a2) => retry(() => icall$3(a0, a1, a2));
  int icall$4Retry(a0, a1, a2, a3) => retry(() => icall$4(a0, a1, a2, a3));
  int icall$5Retry(a0, a1, a2, a3, a4) {
    return retry(() => icall$5(a0, a1, a2, a3, a4));
  }
  int icall$6Retry(a0, a1, a2, a3, a4, a5) {
    return retry(() => icall$6(a0, a1, a2, a3, a4, a5));
  }
  int icall$7Retry(a0, a1, a2, a3, a4, a5, a6) {
    return retry(() => icall$7(a0, a1, a2, a3, a4, a5, a6));
  }
  // Support for calling foreign functions that return
  // machine words -- typically pointers -- encapsulated in
  // the given foreign object arguments.
  ForeignPointer pcall$0() =>
      new ForeignPointer(_pcall$0(address));

  ForeignPointer pcall$1(a0) =>
      new ForeignPointer(_pcall$1(address, _convert(a0)));

  ForeignPointer pcall$2(a0, a1) =>
      new ForeignPointer(_pcall$2(address, _convert(a0), _convert(a1)));

  ForeignPointer pcall$3(a0, a1, a2) =>
      new ForeignPointer(_pcall$3(address, _convert(a0), _convert(a1),
                                  _convert(a2)));

  ForeignPointer pcall$4(a0, a1, a2, a3) =>
      new ForeignPointer(_pcall$4(address, _convert(a0), _convert(a1),
                                  _convert(a2), _convert(a3)));

  ForeignPointer pcall$5(a0, a1, a2, a3, a4) =>
      new ForeignPointer(_pcall$5(address, _convert(a0), _convert(a1),
                                  _convert(a2), _convert(a3), _convert(a4)));

  ForeignPointer pcall$6(a0, a1, a2, a3, a4, a5) =>
      new ForeignPointer(_pcall$6(address, _convert(a0), _convert(a1),
                                  _convert(a2), _convert(a3), _convert(a4),
                                  _convert(a5)));

  // Support for calling foreign functions with no return value.
  void vcall$0() {
    _vcall$0(address);
  }

  void vcall$1(a0) {
    _vcall$1(address, _convert(a0));
  }

  void vcall$2(a0, a1) {
    _vcall$2(address, _convert(a0), _convert(a1));
  }

  void vcall$3(a0, a1, a2) {
    _vcall$3(address, _convert(a0), _convert(a1), _convert(a2));
  }

  void vcall$4(a0, a1, a2, a3) {
    _vcall$4(address, _convert(a0), _convert(a1), _convert(a2), _convert(a3));
  }

  void vcall$5(a0, a1, a2, a3, a4) {
    _vcall$5(address, _convert(a0), _convert(a1), _convert(a2), _convert(a3),
        _convert(a4));
  }

  void vcall$6(a0, a1, a2, a3, a4, a5) {
    _vcall$6(address, _convert(a0), _convert(a1), _convert(a2), _convert(a3),
        _convert(a4), _convert(a5));
  }

  void vcall$7(a0, a1, a2, a3, a4, a5, a6) {
    _vcall$7(address, _convert(a0), _convert(a1), _convert(a2), _convert(a3),
        _convert(a4), _convert(a5), _convert(a6));
  }

  // TODO(ricow): this is insanely specific and only used for rseek.
  // Support for calling foreign functions that
  //  - Returns a 64 bit integer value.
  //  - Takes:
  //    * a word,
  //    * a 64 bit int
  //    * a word
  int Lcall$wLw(a0, a1, a2) {
    return _Lcall$wLw(address, _convert(a0), _convert(a1), _convert(a2));
  }

  int Lcall$wLwRetry(a0, a1, a2) => retry(() => Lcall$wLw(a0, a1, a2));

  @dartino.native static int _callv(int address, int returnType, int len,
  args, types) {
    throw new ArgumentError();
  }

  @dartino.native static int _icall$0(int address) {
    throw new ArgumentError();
  }
  @dartino.native static int _icall$1(int address, a0) {
    throw new ArgumentError();
  }
  @dartino.native static int _icall$2(int address, a0, a1) {
    throw new ArgumentError();
  }
  @dartino.native static int _icall$3(int address, a0, a1, a2) {
    throw new ArgumentError();
  }
  @dartino.native static int _icall$4(int address, a0, a1, a2, a3) {
    throw new ArgumentError();
  }
  @dartino.native static int _icall$5(int address, a0, a1, a2, a3, a4) {
    throw new ArgumentError();
  }
  @dartino.native static int _icall$6(
      int address, a0, a1, a2, a3, a4, a5) {
    throw new ArgumentError();
  }
  @dartino.native static int _icall$7(
      int address, a0, a1, a2, a3, a4, a5, a6) {
    throw new ArgumentError();
  }

  @dartino.native static int _pcall$0(int address) {
    throw new ArgumentError();
  }
  @dartino.native static int _pcall$1(int address, a0) {
    throw new ArgumentError();
  }
  @dartino.native static int _pcall$2(int address, a0, a1) {
    throw new ArgumentError();
  }
  @dartino.native static int _pcall$3(int address, a0, a1, a2) {
    throw new ArgumentError();
  }
  @dartino.native static int _pcall$4(int address, a0, a1, a2, a3) {
    throw new ArgumentError();
  }
  @dartino.native static int _pcall$5(int address, a0, a1, a2, a3, a4) {
    throw new ArgumentError();
  }
  @dartino.native static int _pcall$6(
      int address, a0, a1, a2, a3, a4, a5) {
    throw new ArgumentError();
  }

  @dartino.native static int _vcall$0(int address) {
    throw new ArgumentError();
  }
  @dartino.native static int _vcall$1(int address, a0) {
    throw new ArgumentError();
  }
  @dartino.native static int _vcall$2(int address, a0, a1) {
    throw new ArgumentError();
  }
  @dartino.native static int _vcall$3(int address, a0, a1, a2) {
    throw new ArgumentError();
  }
  @dartino.native static int _vcall$4(int address, a0, a1, a2, a3) {
    throw new ArgumentError();
  }
  @dartino.native static int _vcall$5(int address, a0, a1, a2, a3, a4) {
    throw new ArgumentError();
  }
  @dartino.native static int _vcall$6(
      int address, a0, a1, a2, a3, a4, a5) {
    throw new ArgumentError();
  }
  @dartino.native static int _vcall$7(
      int address, a0, a1, a2, a3, a4, a5, a6) {
    throw new ArgumentError();
  }

  @dartino.native static int _Lcall$wLw(int address, a0, a1, a2) {
    throw new ArgumentError();
  }
}

class ForeignDartFunction extends ForeignFunction {
  bool _hasBeenFreed = false;

  /// Creates a foreign function from the given [dartFunction].
  ///
  /// The [dartFunction] is linked to a native function, and can then be
  /// invoked as callback from native functions. The arity of the native
  /// function is the same as the one from Dart, but is currently limited to
  /// at most 3 arguments.
  ///
  /// The [errorReturnObject] is returned to the native caller, when this
  /// function is used as a callback from native code, but the invocation isn't
  /// successful. For example, this may happen, when the [dartFunction] throws
  /// an uncaught exception, or the callback is invoked with the wrong number of
  /// arguments.
  ///
  /// Once the callback is not needed anymore, one *must* free the backing
  /// native function by invoking [free]. There is a limited number of wrappers
  /// that can be used to implement callbacks in Dart.
  ///
  /// Throws an [ResourceExhaustedException] if no native wrapper function is
  /// available.
  ///
  /// Wrapped Dart functions may only be used as a callback from native code
  /// that has been invoked from Dart code. That is, the callback must not be
  /// stored in native memory, and be used at a later time.
  ///
  /// Example:
  ///
  ///     int dartCallback1(int x) {
  ///       print("callback from native with: $x");
  ///       return x + 1;
  ///     }
  ///
  ///     main() {
  ///       var libPath = ForeignLibrary.bundleLibraryName('native_library');
  ///       ForeignLibrary fl = new ForeignLibrary.fromName(libPath);
  ///       var trampoline = fl.lookup('trampoline1');
  ///       // Invoke the native 'trampoline1' function and pass it the
  ///       // wrapped Dart function. The trampoline function returns the result
  ///       // of calling the given argument (see below).
  ///       var foreign = new ForeignFunction.fromDart(dartCallback1);
  ///       Expect.equals(2, trampoline.icall$2(foreign, 1));
  ///       foreign.free();
  ///     }
  ///
  /// The native function could be implemented as a C function, as follows:
  ///
  ///     typedef void* (*Arity1)(void* x);
  ///
  ///     __attribute__((visibility("default")))
  ///     void* trampoline1(void* f, void* x) {
  ///       return ((Arity1)f)(x);
  ///     }
  ForeignDartFunction(Function dartFunction, [errorReturnObject = -1])
      : super.fromAddress(ForeignCallback.registerDartCallback(
           dartFunction, errorReturnObject));

  /// Frees the native wrapper function.
  ///
  /// This function must only be called for foreign functions that have been
  /// allocated with [ForeignFunction.fromDart].
  ///
  /// It is an error to free the same wrapper function multiple times.
  void free() {
    if (_hasBeenFreed) {
      throw new StateError("Foreign Dart function has already been freed.");
    }
    _hasBeenFreed = true;
    ForeignCallback.freeFunctionPointer(address);
  }
}

class ForeignPointer extends Foreign {
  final int address;
  const ForeignPointer(this.address);

  static const ForeignPointer NULL = const ForeignPointer(0);
}

class _ForeignValue extends ForeignPointer {
  final ForeignLibrary _library;

  const _ForeignValue(int address, [this._library = null]) : super(address);
}

class ForeignLibrary extends ForeignPointer {
  /// The ForeignLibrary main is used for looking up functions in the libraries
  /// linked in to the main Dartino binary.
  static ForeignLibrary main = new ForeignLibrary.fromName(null);

  const ForeignLibrary.fromAddress(int address) : super(address);

  /// Looks up a foreign library by name. If the global flag is set we use
  /// RTLD_GLOBAL that will enable later lookups to use code from this library.
  factory ForeignLibrary.fromName(String name, {bool global: false}) {
    return new ForeignLibrary.fromAddress(_lookupLibrary(name, global));
  }

  ForeignFunction lookup(String name) {
    return new ForeignFunction.fromAddress(_lookupFunction(address, name),
        this);
  }

  ForeignPointer lookupVariable(String name) {
    return new _ForeignValue(_lookupFunction(address, name), this);
  }

  /// Provides a platform specific location for a library relative to the
  /// location of the Dartino vm. Takes the name without lib in front and
  /// returns a platform specific path. Example, on linux, foobar_hash
  /// become PATH_TO_EXECUTABLE/lib/libfoobar_hash.so.
  @dartino.native static String bundleLibraryName(String libraryName) {
    throw new ArgumentError();
  }

  @dartino.native static int _lookupLibrary(String name, bool global) {
    var error = dartino.nativeError;
    throw (error != dartino.indexOutOfBounds) ? error : new ArgumentError();
  }

  @dartino.native static int _lookupFunction(int address, String name) {
    var error = dartino.nativeError;
    throw (error != dartino.indexOutOfBounds) ? error : new ArgumentError();
  }
}

/// Foreign Function return types definition, prefer to use shorthands in Ffi.
// The order of members here has to match the C++ version inside of the VM.
enum ForeignFunctionReturnType {
  pointer,
  int32,
  int64,
  float32,
  float64,
  void_
}

/// Foreign Function argument types defintion, prefer to use shorthands in Ffi.
// The order of members here has to match the C++ version inside of the VM.
enum ForeignFunctionArgumentType {
  pointer,
  int32,
  int64,
  float32,
  float64
}

/// A wrapper for type-safe invocation of Foreign Function.
class Ffi {
  final ForeignFunction func;
  final ForeignFunctionReturnType returnType;
  final List<ForeignFunctionArgumentType> argTypes;

  /// Shorthand for pointer return type enum
  static const returnsPointer = ForeignFunctionReturnType.pointer;
  /// Shorthand for int32 return type enum
  static const returnsInt32 = ForeignFunctionReturnType.int32;
  /// Shorthand for int64 return type enum
  static const returnsInt64 = ForeignFunctionReturnType.int64;
  /// Shorthand for float32 return type enum
  static const returnsFloat32 = ForeignFunctionReturnType.float32;
  /// Shorthand for float64 return type enum
  static const returnsFloat64 = ForeignFunctionReturnType.float64;
  /// Shorthand for void return type enum
  static const returnsVoid = ForeignFunctionReturnType.void_;

  /// Shorthand for pointer argument type enum
  static const pointer = ForeignFunctionArgumentType.pointer;
  /// Shorthand for int32 argument type enum
  static const int32 = ForeignFunctionArgumentType.int32;
  /// Shorthand for int64 argument type enum
  static const int64 = ForeignFunctionArgumentType.int64;
  /// Shorthand for float32 argument type enum
  static const float32 = ForeignFunctionArgumentType.float32;
  /// Shorthand for float64 argument type enum
  static const float64 = ForeignFunctionArgumentType.float64;

  Ffi(String name, this.returnType, this.argTypes, [ForeignLibrary lib])
      :
      func = lib == null ? ForeignLibrary.main.lookup(name) : lib.lookup(name);

  _doCall(int len, dartino.FixedList args) {
    var converted = new List(args.length); // is a FixedList
    if (len != argTypes.length) {
      throw new ArgumentError("Ffi wrong number of arguments");
    }
    for (var i = 0; i < len; i++) {
      switch (argTypes[i]) {
        case Ffi.pointer:
          if (!(args[i] is Foreign)) {
            throw new ArgumentError("Ffi expected pointer");
          }
          converted[i] = args[i].address;
          break;
        case Ffi.int32:
        case Ffi.int64:
          if (args[i] is double) {
            converted[i] = args[i].toInt();
          } else if (args[i] is int) {
            converted[i] = args[i];
          } else {
            throw new ArgumentError("Ffi expected int");
          }
          break;
        case Ffi.float32:
        case Ffi.float64:
          if (args[i] is int) {
            converted[i] = args[i].toDouble();
          } else if (args[i] is double) {
            converted[i] = args[i];
          } else {
            throw new ArgumentError("Ffi expected double");
          }
          break;
      }
    }
    var argTypesFixed = dartino.extractFixedList(argTypes);
    switch (returnType) {
      case Ffi.returnsVoid:
        func.callv(returnType.index, len, converted, argTypesFixed);
        break;
      case Ffi.returnsInt32:
      case Ffi.returnsInt64:
      case Ffi.returnsFloat32:
      case Ffi.returnsFloat64:
        return func.callv(returnType.index, len, converted, argTypesFixed);
      case Ffi.returnsPointer:
        return new ForeignPointer(func.callv(returnType.index, len,
          converted, argTypesFixed));
      default:
        throw new ArgumentError("Unsupported return type");
    }
  }

  call(args) {
    if (args is dartino.FixedListBase || args is dartino.GrowableList) {
      return _doCall(args.length, args);
    } else {
      throw new ArgumentError("Ffi expects List");
    }
  }
}

abstract class UnsafeMemory extends Foreign {
  int get length;
  const UnsafeMemory();

  int getInt8(int offset) => _getInt8(_computeAddress(offset, 1));
  int getInt16(int offset) => _getInt16(_computeAddress(offset, 2));
  int getInt32(int offset) => _getInt32(_computeAddress(offset, 4));
  int getInt64(int offset) => _getInt64(_computeAddress(offset, 8));

  int setInt8(int offset, int value) =>
      _setInt8(_computeAddress(offset, 1), value);
  int setInt16(int offset, int value) =>
      _setInt16(_computeAddress(offset, 2), value);
  int setInt32(int offset, int value) =>
      _setInt32(_computeAddress(offset, 4), value);
  int setInt64(int offset, int value) =>
      _setInt64(_computeAddress(offset, 8), value);

  int getUint8(int offset) => _getUint8(_computeAddress(offset, 1));
  int getUint16(int offset) => _getUint16(_computeAddress(offset, 2));
  int getUint32(int offset) => _getUint32(_computeAddress(offset, 4));
  int getUint64(int offset) => _getUint64(_computeAddress(offset, 8));

  int setUint8(int offset, int value) =>
      _setUint8(_computeAddress(offset, 1), value);
  int setUint16(int offset, int value) =>
      _setUint16(_computeAddress(offset, 2), value);
  int setUint32(int offset, int value) =>
      _setUint32(_computeAddress(offset, 4), value);
  int setUint64(int offset, int value) =>
      _setUint64(_computeAddress(offset, 8), value);

  double getFloat32(int offset) => _getFloat32(_computeAddress(offset, 4));
  double getFloat64(int offset) => _getFloat64(_computeAddress(offset, 8));

  double setFloat32(int offset, double value) =>
      _setFloat32(_computeAddress(offset, 4), value);
  double setFloat64(int offset, double value) =>
      _setFloat64(_computeAddress(offset, 8), value);

  // Helper for checking bounds and computing derived
  // addresses for memory address functionality.
  int _computeAddress(int offset, int n) {
    if (offset < 0 || offset + n > length) throw new IndexError(offset, this);
    return address + offset;
  }

  void copyBytesToList(List<int> list, int from, int to, int listOffset) {
    int length = to - from;
    for (int i = 0; i < length; i++) {
      list[listOffset + i] = getUint8(from + i);
    }
  }

  void copyBytesFromList(List<int> list, int from, int to, int listOffset) {
    int length = to - from;
    for (int i = 0; i < length; i++) {
      setUint8(from + i, list[listOffset + i]);
    }
  }

  @dartino.native static int _allocate(int length) {
    throw new ArgumentError();
  }
  @dartino.native void _markForFinalization(int length) {
    throw new ArgumentError();
  }

  @dartino.native static int _getInt8(int address) {
    throw new ArgumentError();
  }
  @dartino.native static int _getInt16(int address) {
    throw new ArgumentError();
  }
  @dartino.native static int _getInt32(int address) {
    throw new ArgumentError();
  }
  @dartino.native static int _getInt64(int address) {
    throw new ArgumentError();
  }

  @dartino.native static int _setInt8(int address, int value) {
    throw new ArgumentError();
  }
  @dartino.native static int _setInt16(int address, int value) {
    throw new ArgumentError();
  }
  @dartino.native static int _setInt32(int address, int value) {
    throw new ArgumentError();
  }
  @dartino.native static int _setInt64(int address, int value) {
    throw new ArgumentError();
  }

  @dartino.native static int _getUint8(int address) {
    throw new ArgumentError();
  }
  @dartino.native static int _getUint16(int address) {
    throw new ArgumentError();
  }
  @dartino.native static int _getUint32(int address) {
    throw new ArgumentError();
  }
  @dartino.native static int _getUint64(int address) {
    throw new ArgumentError();
  }

  @dartino.native static int _setUint8(int address, int value) {
    throw new ArgumentError();
  }
  @dartino.native static int _setUint16(int address, int value) {
    throw new ArgumentError();
  }
  @dartino.native static int _setUint32(int address, int value) {
    throw new ArgumentError();
  }
  @dartino.native static int _setUint64(int address, int value) {
    throw new ArgumentError();
  }

  @dartino.native static double _getFloat32(int address) {
    throw new ArgumentError();
  }
  @dartino.native static double _getFloat64(int address) {
    throw new ArgumentError();
  }

  @dartino.native static double _setFloat32(int address, double value) {
    throw new ArgumentError();
  }
  @dartino.native static double _setFloat64(int address, double value) {
    throw new ArgumentError();
  }
}

class ImmutableForeignMemory extends UnsafeMemory {
  // Address is split into two Smis instead of using one int that might be a
  // heap number. This makes allocation simpler and ensures that objects can be
  // finalized individually in the GC without imposing ordering constraints on
  // the GC.
  final int _address0;
  final int _address1;
  final int length;

  int get address => (_address0 << 2) + _address1;

  const ImmutableForeignMemory.fromAddress(int address, this.length)
      : _address0 = address >> 2,
        _address1 = address & 3;

  factory ImmutableForeignMemory.fromAddressFinalized(int address, int length) {
    var memory = new ImmutableForeignMemory.fromAddress(address, length);
    memory._markForFinalization(length);
    return memory;
  }

  factory ImmutableForeignMemory.allocatedFinalized(int length) {
    var memory = new ImmutableForeignMemory.fromAddress(
        UnsafeMemory._allocate(length), length);
    memory._markForFinalization(length);
    return memory;
  }

  factory ImmutableForeignMemory.allocated(int length) {
    var memory = new ImmutableForeignMemory.fromAddress(
        UnsafeMemory._allocate(length), length);
    return memory;
  }

  // We utf8 encode the string first to support non-ascii characters.
  // NOTE: This is not the correct string encoding for Windows.
  factory ImmutableForeignMemory.fromStringAsUTF8(String str) {
    List<int> encodedString = _encodeUtf8(str);
    var memory = new ImmutableForeignMemory.allocated(encodedString.length + 1);
    for (int i = 0; i < encodedString.length; i++) {
      memory.setUint8(i, encodedString[i]);
    }
    memory.setUint8(encodedString.length, 0); // '\0' terminate string
    return memory;
  }
}

// We can't delegate to a constructor in the same class, so we insert a class
// between UnsafeMemory and ForeignMemory, which has the constructor we need.
// We can't use factories because subclasses (ie Struct) want to be able to
// call our constructors
class _ForeignMemoryHelper extends UnsafeMemory {
  int _address0;
  int _address1;
  int length;

  int get address => (_address0 << 2) + _address1;

  int set address(int addr) {
    _address0 = addr >> 2;
    _address1 = addr & 3;
    return addr;
  }

  _ForeignMemoryHelper.fromAddress(int address, this.length)
      : _address0 = address >> 2,
        _address1 = address & 3;
}

class ForeignMemory extends _ForeignMemoryHelper {
  bool _markedForFinalization = false;

  ForeignMemory.fromAddress(int address, int length)
      : super.fromAddress(address, length);

  ForeignMemory.fromAddressFinalized(int address, int length)
      : super.fromAddress(address, length),
        _markedForFinalization = true {
    _markForFinalization(length);
  }

  ForeignMemory.allocated(int length)
      : super.fromAddress(UnsafeMemory._allocate(length), length);

  ForeignMemory.allocatedFinalized(int length)
      : super.fromAddress(UnsafeMemory._allocate(length), length),
        _markedForFinalization = true {
    _markForFinalization(length);
  }

  // We utf8 encode the string first to support non-ascii characters.
  // NOTE: This is not the correct string encoding for Windows.
  factory ForeignMemory.fromStringAsUTF8(String str) {
    List<int> encodedString = _encodeUtf8(str);
    var memory = new ForeignMemory.allocated(encodedString.length + 1);
    for (int i = 0; i < encodedString.length; i++) {
      memory.setUint8(i, encodedString[i]);
    }
    memory.setUint8(encodedString.length, 0); // '\0' terminate string
    return memory;
  }

  void free() {
    if (length > 0) {
      if (_markedForFinalization) {
        _decreaseMemoryUsage(length);
      }
      _free();
    }
    address = 0;
    length = 0;
  }

  @dartino.native void _decreaseMemoryUsage(int length) {
    throw new ArgumentError();
  }
  @dartino.native void _free() {
    throw new ArgumentError();
  }
}

// NOTE We could make this a view on a memory object instead.
class Struct extends ForeignMemory {
  final wordSize;
  int get numFields => length ~/ wordSize;

  Struct(int fields)
      : this.wordSize = Foreign.machineWordSize,
        super.allocated(fields * Foreign.machineWordSize);

  Struct.finalized(int fields)
      : this.wordSize = Foreign.machineWordSize,
        super.allocatedFinalized(fields * Foreign.machineWordSize);

  Struct.fromAddress(int address, int fields)
      : this.wordSize = Foreign.machineWordSize,
        super.fromAddress(address, fields * Foreign.machineWordSize);

  Struct.withWordSize(int fields, wordSize)
      : this.wordSize = wordSize,
        super.allocated(fields * wordSize);

  Struct.withWordSizeFinalized(int fields, wordSize)
      : this.wordSize = wordSize,
        super.allocatedFinalized(fields * wordSize);

  Struct.fromAddressWithWordSize(int address, int fields, wordSize)
      : this.wordSize = wordSize,
        super.fromAddress(address, fields * wordSize);

  int getWord(int byteOffset) {
    switch (wordSize) {
      case 4:
        return getInt32(byteOffset);
      case 8:
        return getInt64(byteOffset);
      default:
        throw "Unsupported machine word size.";
    }
  }

  int setWord(int byteOffset, int value) {
    switch (wordSize) {
      case 4:
        return setInt32(byteOffset, value);
      case 8:
        return setInt64(byteOffset, value);
      default:
        throw "Unsupported machine word size.";
    }
  }

  int getField(int fieldOffset) => getWord(fieldOffset * wordSize);

  void setField(int fieldOffset, int value) {
    setWord(fieldOffset * wordSize, value);
  }
}

class Struct32 extends Struct {
  Struct32(int fields) : super.withWordSize(fields, 4);
  Struct32.finalized(int fields) : super.withWordSizeFinalized(fields, 4);
  Struct32.fromAddress(int address, int fields)
      : super.fromAddressWithWordSize(address, fields, 4);
}

class Struct64 extends Struct {
  Struct64(int fields) : super.withWordSize(fields, 8);
  Struct64.finalized(int fields) : super.withWordSizeFinalized(fields, 8);
  Struct64.fromAddress(int address, int fields)
      : super.fromAddressWithWordSize(address, fields, 8);
}
