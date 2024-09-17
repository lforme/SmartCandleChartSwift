//
//  EMAChart.swift
//  
//
//  Created by Lforme on 2022/3/21.
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

import UIKit

/// EMA 图表配置信息
public struct EMAConfiguration: ContextKey {
    public typealias Value = ReadonlyOffsetArray<CGFloat>

    public var lineWidth: CGFloat
    /// 观察周期
    public var period: Int
    /// 颜色
    public var color: UIColor

    /// 创建 EMA 图表配置信息
    /// - Parameters:
    ///   - period: 观察周期
    ///   - color: 颜色
    public init(period: Int, color: UIColor, lineWidth: CGFloat) {
        self.lineWidth = lineWidth
        self.period = period
        self.color = color
    }
}

/// EMA 指标绘制
public class EMAChart<Input: Quote>: ChartRenderer {
    public typealias Input = Input
    public typealias QuoteProcessor = IndicatorQuoteProcessor<Input, CGFloat, EMAConfiguration, ExponentialMovingAverageAlgorithm<Input>>
    public let quoteProcessor: IndicatorQuoteProcessor<Input, CGFloat, EMAConfiguration, ExponentialMovingAverageAlgorithm<Input>>?

    private let configuration: EMAConfiguration
    private let layer = LineChartLayer()

    /// EMA 指标图表
    /// - Parameter configuration: 配置信息
    public init(configuration: EMAConfiguration) {
        self.configuration = configuration
        self.quoteProcessor = .init(id: configuration,
                                    algorithm: .init(period: configuration.period))
    }

    public func updateZPosition(_ position: CGFloat) {
        layer.zPosition = position
    }

    public func setup(in view: ChartView<Input>) {
        view.layer.addSublayer(layer)
    }

    public func render(in view: ChartView<Input>, context: Context) {
        guard let values = context.contextValues[configuration] else {
            layer.clear()
            return
        }
        layer.update(with: context,
                     indicatorValues: values,
                     color: configuration.color, lineWidth: configuration.lineWidth)
    }

    public func tearDown(in view: ChartView<Input>) {
        layer.removeFromSuperlayer()
    }

    public func captions(quoteIndex: Int, context: Context) -> [NSAttributedString] {
        let value = context.contextValues[configuration]?[quoteIndex].flatMap {
            context.preferredFormatter.format($0)
        } ?? "--"
        let text = "EMA\(configuration.period):\(value)"
        return [
            .init(string: text, attributes: [
                .font: context.configuration.captionFont,
                .foregroundColor: configuration.color
            ])
        ]
    }
}
