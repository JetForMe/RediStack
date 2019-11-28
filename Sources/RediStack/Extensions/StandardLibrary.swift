//===----------------------------------------------------------------------===//
//
// This source file is part of the RediStack open source project
//
// Copyright (c) 2019 RediStack project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of RediStack project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import CNIOSHA1

extension Array where Element == RESPValue {
    /// Converts the collection of `RESPValueConvertible` elements and appends them to the end of the array.
    /// - Note: This method guarantees that only one storage expansion will happen to copy the elements.
    /// - Parameters elementsToCopy: The collection of elements to convert to `RESPValue` and append to the array.
    public mutating func append<ValueCollection>(convertingContentsOf elementsToCopy: ValueCollection)
        where
        ValueCollection: Collection,
        ValueCollection.Element: RESPValueConvertible
    {
        guard elementsToCopy.count > 0 else { return }
        
        self.reserveCapacity(self.count + elementsToCopy.count)
        elementsToCopy.forEach { self.append($0.convertedToRESPValue()) }
    }
    
    /// Adds the elements of a collection to this array, delegating the details of how they are added to the given closure.
    ///
    /// When your closure will be doing more than a simple transform of the element value, such as when you're adding both the key _and_ value from a `KeyValuePair`,
    /// you should set the `overestimatedCountBeingAdded` to a value you do not expect to exceed in order to prevent multiple allocations from the increasing
    /// element count.
    ///
    /// For example:
    ///
    ///     let pairs = [
    ///         "MyID": 30,
    ///         "YourID": 31
    ///     ]
    ///     var values: [RESPValue] = []
    ///     values.add(contentsOf: pairs, overestimatedCountBeingAdded: pairs.count * 2) { (array, element) in
    ///         // element is a (key, value) tuple
    ///         array.append(element.0.convertedToRESPValue())
    ///         array.append(element.1.convertedToRESPValue())
    ///     }
    ///
    /// However, if you just want to apply a transform, you can do that more similarly to a call to the `reduce` methods:
    ///
    ///     let valuesToConvert = [...] // some collection of non-`RESPValueConvertible` elements, such as third-party types
    ///     let values: [RESPValue] = []
    ///     values.add(contentsOf: valuesToConvert) { (array, element) in
    ///         // your transform and insert/append implementation
    ///     }
    ///
    /// If the `elementsToCopy` has no elements, the `closure` is never called.
    ///
    /// - Parameters:
    ///     - elementsToCopy: The collection of elements that will be added to the array in the closure.
    ///     - overestimatedCountBeingAdded: The number of elements that will be added to the array.
    ///         If no value is provided, the size of the collection being copied will be used.
    ///     - closure: A closure left to define how the collection's element should be added into the array.
    public mutating func add<ValueCollection: Collection>(
        contentsOf elementsToCopy: ValueCollection,
        overestimatedCountBeingAdded: Int? = nil,
        _ closure: (inout [RESPValue], ValueCollection.Element) -> Void
    ) {
        guard elementsToCopy.count > 0 else { return }
        
        let sizeToAdd = overestimatedCountBeingAdded ?? elementsToCopy.count
        self.reserveCapacity(self.count + sizeToAdd)
        
        elementsToCopy.forEach { closure(&self, $0) }
    }
}

extension Array {
    /// Initializes an empty array, reserving the desired `initialCapacity`.
    /// - Parameter initialCapacity: The desired element size the array should start with.
    internal init(initialCapacity: Int) {
        self = []
        self.reserveCapacity(initialCapacity)
    }
}

extension String {
    /// Return a sha1 hash for this string.
    /// Mirrors the internal C-based implementation used by NIO websockets.
    public var sha1: String? {

        var sha1Ctx = SHA1_CTX()
        c_nio_sha1_init(&sha1Ctx)

        let buffer = Array(self.utf8)
        buffer.withUnsafeBufferPointer { (bytes: UnsafeBufferPointer<UInt8>) in
            c_nio_sha1_loop(&sha1Ctx, bytes.baseAddress!, bytes.count)
        }

        var hashResult: [UInt8] = Array(repeating: 0, count: 20)
        hashResult.withUnsafeMutableBufferPointer {
            $0.baseAddress!.withMemoryRebound(to: Int8.self, capacity: 20) {
                c_nio_sha1_result(&sha1Ctx, $0)
            }
        }

        return hashResult.map { String(format: "%02x", $0) }.joined()
    }
}
