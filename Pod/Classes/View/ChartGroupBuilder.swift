//
//  ChartGroupBuilder.swift
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

@resultBuilder
public enum ChartGroupBuilder<I: Quote> {
    public static func buildExpression(_ expression: ChartGroup<I>) -> [ChartGroup<I>] {
        [expression]
    }

    public static func buildBlock(_ components: [ChartGroup<I>]...) -> [ChartGroup<I>] {
        components.flatMap { $0 }
    }

    public static func buildIf(_ components: ChartGroup<I>?...) -> [ChartGroup<I>] {
        components.compactMap { $0 }
    }

    public static func buildEither(first component: [ChartGroup<I>]) -> [ChartGroup<I>] {
        component
    }

    public static func buildEither(second component: [ChartGroup<I>]) -> [ChartGroup<I>] {
        component
    }

    public static func buildArray(_ components: [[ChartGroup<I>]]) -> [ChartGroup<I>] {
        components.flatMap { $0 }
    }

    public static func buildLimitedAvailability(_ component: [ChartGroup<I>]) -> [ChartGroup<I>] {
        component
    }

    public static func buildOptional(_ component: [ChartGroup<I>]?) -> [ChartGroup<I>] {
        component ?? []
    }
}
