//
//  Patch.swift
//  
//
//  Created by Lforme on 2022/3/18.
//
//  Copyright (c) 2022 Lforme
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

public struct Patch<V: Hashable> {
    public var deletions: Set<V> = []
    public var insertions: Set<V> = []
}

public extension Set {
    func patches(to another: Set<Element>) -> Patch<Element> {
        var path = Patch<Element>()
        union(another)
            .forEach { x in
                switch (self.contains(x), another.contains(x)) {
                case (false, true):
                    path.insertions.insert(x)
                case (true, false):
                    path.deletions.insert(x)
                default:
                    break
                }
            }
        return path
    }

    func patches(from another: Set<Element>) -> Patch<Element> {
        another.patches(to: self)
    }
}