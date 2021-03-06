// Copyright (c) 2015, the Dartino project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>

FILE* fopen$UNIX2003(const char* filename, const char* mode) {
  return fopen(filename, mode);
}

size_t fwrite$UNIX2003(const void* a, size_t b, size_t c, FILE* d) {
  return fwrite(a, b, c, d);
}

int fputs$UNIX2003(const char* restrict str, FILE* restrict stream) {
  return fputs(str, stream);
}

pid_t waitpid$UNIX2003(pid_t pid, int* status, int options) {
  return waitpid(pid, status, options);
}

char* strerror$UNIX2003(int errnum) {
  return strerror(errnum);
}
