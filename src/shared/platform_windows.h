// Copyright (c) 2015, the Dartino project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

#ifndef SRC_SHARED_PLATFORM_WINDOWS_H_
#define SRC_SHARED_PLATFORM_WINDOWS_H_

#ifndef SRC_SHARED_PLATFORM_H_
#error Do not include platform_win.h directly; use platform.h instead.
#endif

#if defined(DARTINO_TARGET_OS_WIN)

// Prevent the windows.h header from including winsock.h and others.
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif

#if _WIN32_WINNT < _WIN32_WINNT_WIN7
#error "Required version of windows headers is at least Windows 7."
#endif

#include <windows.h>

#include "src/shared/globals.h"

#define snprintf _snprintf
#define MAXPATHLEN MAX_PATH

namespace dartino {

// Forward declare [Platform::GetMicroseconds].
namespace Platform {
uint64 GetMicroseconds();
}  // namespace Platform

class MutexImpl {
 public:
  MutexImpl() : srwlock_(SRWLOCK_INIT) { }
  ~MutexImpl() { }

  int Lock() {
    AcquireSRWLockExclusive(&srwlock_);
    return 0;
  }

  int TryLock() {
    return TryAcquireSRWLockExclusive(&srwlock_) ? 0 : 1;
  }

  int Unlock() {
    ReleaseSRWLockExclusive(&srwlock_);
    return 0;
  }

 private:
  SRWLOCK srwlock_;
};

class MonitorImpl {
 public:
  MonitorImpl() {
    InitializeSRWLock(&srwlock_);
    InitializeConditionVariable(&cond_);
  }

  ~MonitorImpl() { }

  int Lock() {
    AcquireSRWLockExclusive(&srwlock_);
    return 0;
  }

  int Unlock() {
    ReleaseSRWLockExclusive(&srwlock_);
    return 0;
  }

  int Wait() {
    SleepConditionVariableSRW(&cond_, &srwlock_, INFINITE, 0);
    return 0;
  }

  bool Wait(uint64 microseconds) {
    DWORD miliseconds = microseconds / 1000;
    SleepConditionVariableSRW(&cond_, &srwlock_, miliseconds, 0);
    // TODO(erikcorry): Should return true on successful wait, false if the wait
    // was interrupted.
    return false;
  }

  bool WaitUntil(uint64 microseconds_since_epoch) {
    int64 us = microseconds_since_epoch - Platform::GetMicroseconds();
    if (us < 0) us == 0;
    return Wait(us);
  }

  int Notify() {
    WakeConditionVariable(&cond_);
    return 0;
  }

  int NotifyAll() {
    WakeAllConditionVariable(&cond_);
    return 0;
  }

 private:
  SRWLOCK srwlock_;
  CONDITION_VARIABLE cond_;
};

}  // namespace dartino

#endif  // defined(DARTINO_TARGET_OS_WIN)

#endif  // SRC_SHARED_PLATFORM_WINDOWS_H_
