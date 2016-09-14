//
//  Mutex.swift
//  MockHTTP
//
//  Created by Christopher Liscio on 2/9/16.
//  Copyright © 2016 Rachel Brindle. All rights reserved.
//

import Foundation

/// A simple mutex class based on `pthread_mutex_t`
final class Mutex {
    private var mutex = pthread_mutex_t()
    private var mutexAttr = pthread_mutexattr_t()

    /// Initializes a `Mutex` instance.
    ///
    /// - parameter recursive: Specify true to allow for recursive calls to `inCriticalSection`.
    ///
    /// - note: Recursive mutexes are slightly less performant, so if you know you don't require that functionality, don't specify it.
    init(recursive: Bool) {
        pthread_mutexattr_init(&mutexAttr)
        if recursive {
            pthread_mutexattr_settype(&mutexAttr, PTHREAD_MUTEX_RECURSIVE)
        } else {
            pthread_mutexattr_settype(&mutexAttr, PTHREAD_MUTEX_NORMAL)
        }
        pthread_mutex_init(&mutex, &mutexAttr)
    }

    deinit {
        pthread_mutexattr_destroy(&mutexAttr)
        pthread_mutex_destroy(&mutex)
    }

    /// Perform the work in the function specified by `f`, protected by this mutex.
    ///
    /// - parameter f: A function that performs the critical work. Can optionally return a value of generic type `U`
    ///
    /// - returns: the value that was returned by `f`.
    func inCriticalSection<U>( _ f: (Void) -> U) -> U {
        pthread_mutex_lock(&mutex)
        let returned = f()
        pthread_mutex_unlock(&mutex)

        return returned
    }
}
