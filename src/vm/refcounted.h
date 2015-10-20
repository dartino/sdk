// Copyright (c) 2015, the Fletch project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

#ifndef SRC_VM_REFCOUNTED_H_
#define SRC_VM_REFCOUNTED_H_

#include "src/shared/globals.h"
#include "src/shared/atomic.h"

namespace fletch {

template<typename T>
class Refcounted {
 public:
  Refcounted() : ref_count_(1) { }
  ~Refcounted() {
    ASSERT(ref_count_ == 0);
  }

  void IncrementRef() {
    ASSERT(ref_count_ > 0);
    ref_count_++;
  }

  static void DecrementRef(T* object) {
    ASSERT(object->ref_count_ > 0);
    if (--object->ref_count_ == 0) {
      delete reinterpret_cast<T*>(object);
    }
  }

 protected:
  bool DecrementRefWithoutDelete() {
    ASSERT(ref_count_ > 0);
    return --ref_count_ == 0;
  }

 private:
  Atomic<int> ref_count_;
};

}  // namespace fletch

#endif  // SRC_VM_REFCOUNTED_H_
