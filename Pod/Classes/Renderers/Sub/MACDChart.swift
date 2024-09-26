//
//  MACDChart.swift
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

/// MACD 配置信息
public struct MACDConfiguration: ContextKey {
    public typealias Value = ReadonlyOffsetArray<MACDIndicator>
    public var shorterPeroid: Int
    public var longerPeroid: Int
    public var deaPeroid: Int
    public var diffColor: UIColor
    public var deaColor: UIColor
    public var minBarHeight: CGFloat
    public var diffLineWidth: CGFloat
    public var deaLineWidth: CGFloat
    public var longIncreasingIsHollow: Bool
    public var longDecreasingIsHollow: Bool
    public var shortIncreasingIsHollow: Bool
    public var shortDecreasingIsHollow: Bool
    public var showDIF: Bool
    public var showDEA: Bool
    
    /// 创建一个 MACD 配置信息，默认为 MACD(12, 26, 9)
    /// - Parameters:
    ///   - shorterPeroid: 短期周期
    ///   - longerPeroid: 长期周期
    ///   - deaPeroid: EMA(Diff) 周期
    ///   - diffColor: Diff 折线图的颜色
    ///   - deaColor: DEA 折线图的颜色
    ///   - minBarHeight: 柱状图最小高度，默认 1pt
    public init(shorterPeroid: Int = 12,
                longerPeroid: Int = 26,
                deaPeroid: Int = 9,
                diffColor: UIColor,
                deaColor: UIColor,
                minBarHeight: CGFloat = 1,
                diffLineWidth: CGFloat = 1,
                deaLineWidth: CGFloat = 1,
                longIncreasingIsHollow: Bool = false,
                longDecreasingIsHollow: Bool = false,
                shortIncreasingIsHollow: Bool = false,
                shortDecreasingIsHollow: Bool = false,
                showDIF: Bool = true,
                showDEA: Bool = true)
    {
        self.shorterPeroid = shorterPeroid
        self.longerPeroid = longerPeroid
        self.deaPeroid = deaPeroid
        self.diffColor = diffColor
        self.deaColor = deaColor
        self.minBarHeight = minBarHeight
        self.diffLineWidth = diffLineWidth
        self.deaLineWidth = deaLineWidth
        self.longIncreasingIsHollow = longIncreasingIsHollow
        self.longDecreasingIsHollow = longDecreasingIsHollow
        self.shortIncreasingIsHollow = shortIncreasingIsHollow
        self.shortDecreasingIsHollow = shortDecreasingIsHollow
        self.showDEA = showDEA
        self.showDIF = showDIF
    }
}

/// MACD 图表
public class MACDChart<Input: Quote>: ChartRenderer {
 
    public typealias Input = Input
    public typealias QuoteProcessor = IndicatorQuoteProcessor<Input, MACDIndicator, MACDConfiguration, MACDAlgorithm<Input>>
    public let quoteProcessor: QuoteProcessor?

    private let configuration: MACDConfiguration
    
    private lazy var upLayer: ShapeLayer = {
        let it = ShapeLayer()
        return it
    }()
    
    private var downLayer: ShapeLayer = {
        let it = ShapeLayer()
        return it
    }()
    
    private lazy var upHollowLayer: ShapeLayer = {
        let it = ShapeLayer()
        it.lineWidth = 1
        return it
    }()
    
    private var downHollowLayer: ShapeLayer = {
        let it = ShapeLayer()
        it.lineWidth = 1
        return it
    }()
    
    
    private let diffLayer = LineChartLayer()
    private let deaLayer = LineChartLayer()

    private let upColor: UIColor
    private let downColor: UIColor
    private let macdLegendColor: UIColor
    
    /// 创建 MACD 图表
    /// - Parameter configuration: 配置信息
    public init(configuration: MACDConfiguration, macdLegendColor: UIColor, upColor: UIColor, downColor: UIColor) {
        self.macdLegendColor = macdLegendColor
        self.upColor = upColor
        self.downColor = downColor
        self.configuration = configuration
        self.quoteProcessor = .init(id: configuration,
                                    algorithm: .init(
                                        shorterPeroid: configuration.shorterPeroid,
                                        longerPeroid: configuration.longerPeroid,
                                        deaPeroid: configuration.deaPeroid))
        diffLayer.strokeColor = configuration.diffColor.cgColor
        deaLayer.strokeColor = configuration.deaColor.cgColor
    }

    public func updateZPosition(_ position: CGFloat) {
        upHollowLayer.zPosition = position
        downHollowLayer.zPosition = position
        upLayer.zPosition = position
        downLayer.zPosition = position
        diffLayer.zPosition = position + 0.1
        deaLayer.zPosition = position + 0.2
    }

    public func setup(in view: ChartView<Input>) {
        view.layer.addSublayer(upLayer)
        view.layer.addSublayer(downLayer)
        view.layer.addSublayer(upHollowLayer)
        view.layer.addSublayer(downHollowLayer)
        view.layer.addSublayer(diffLayer)
        view.layer.addSublayer(deaLayer)
    }

    public func render(in view: ChartView<Input>, context: Context) {
        guard let values = context.contextValues[configuration] else {
            clear()
            return
        }
        if configuration.showDEA {
            deaLayer.update(with: context,
                            indicatorValues: values,
                            keyPath: \.dea,
                            color: configuration.deaColor, lineWidth: configuration.deaLineWidth)
            
        }
   
        if configuration.showDIF {
            diffLayer.update(with: context,
                             indicatorValues: values,
                             keyPath: \.diff,
                             color: configuration.diffColor, lineWidth: configuration.diffLineWidth)
        }
     
        rendererHistogram(context: context, values: values)
    }

    private func clear() {
        upLayer.clear()
        upLayer.clear()
        upHollowLayer.clear()
        downHollowLayer.clear()
        diffLayer.clear()
        deaLayer.clear()
    }

    public func tearDown(in view: ChartView<Input>) {
        upLayer.removeFromSuperlayer()
        downLayer.removeFromSuperlayer()
        upHollowLayer.removeFromSuperlayer()
        downHollowLayer.removeFromSuperlayer()
        diffLayer.removeFromSuperlayer()
        deaLayer.removeFromSuperlayer()
    }

    public func captions(quoteIndex: Int, context: Context) -> [NSAttributedString] {
        let value = context.contextValues[configuration]?[quoteIndex]
        let font = context.configuration.captionFont
        let macd = "MACD(\(configuration.shorterPeroid),\(configuration.longerPeroid),\(configuration.deaPeroid))"
        
        let macdDes = NSMutableAttributedString(attributedString: NSAttributedString.init(string: macd, attributes: [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: context.configuration.captionColor]))
        
        let formatter = context.preferredFormatter

        return [
            macdDes,
            captionText(value: value?.histogram, title: "MACD", formatter: formatter, color: macdLegendColor, font: font),
            captionText(value: value?.diff, title: "DIF", formatter: formatter, color: configuration.diffColor, font: font),
            captionText(value: value?.dea, title: "DEA", formatter: formatter, color: configuration.deaColor, font: font)
        ]
    }

    private func captionText(value: CGFloat?,
                             title: String,
                             formatter: NumberFormatting,
                             color: UIColor,
                             font: UIFont) -> NSAttributedString
    {
        let text = value.flatMap { formatter.format($0) } ?? "--"
        return NSAttributedString(string: "\(title):\(text)",
                                  attributes: [
                                      .foregroundColor: color,
                                      .font: font
                                  ])
    }
}

// MARK: - Renderer Histogram

extension MACDChart {
    private func rendererHistogram(context: Context, values: ReadonlyOffsetArray<MACDIndicator>) {
        let upPath = CGMutablePath()
        let upHollowPath = CGMutablePath()
        let downPath = CGMutablePath()
        let downHollowPath = CGMutablePath()
        let peak = context.extremePoint.max - context.extremePoint.min
        guard peak > 0 else { return }
        let zeroY = yOffset(for: 0, context: context)
        let (slice, range) = values.sliceAndRange(for: context.visibleRange)
        
        var res = values.storage
        let count = range.upperBound - res.count
        if count > 0 {
            let alignment = (0..<count).map { _ in
                return MACDIndicator.init(diff: 0, dea: 0, histogram: 0)
            }
            res.insert(contentsOf: alignment, at: 0)
        }
        
        zip(range, slice).forEach { index, macd in
     
            let macd = macd.histogram ?? 0
            if let preMacd = res.safeObjec(index)?.histogram  {
                
                if (preMacd > 0 && macd > 0) { // 多
                    if macd > preMacd { // 显示空心
                        if configuration.longIncreasingIsHollow {
                            writePath(into: upHollowPath, macd: macd, context: context, index: index, zeroY: zeroY)
                            upHollowLayer.path = upHollowPath
                            upHollowLayer.strokeColor = upColor.cgColor
                            upHollowLayer.fillColor = UIColor.clear.cgColor
                            
                        } else {
                            writePath(into: upPath, macd: macd, context: context, index: index, zeroY: zeroY)
                            upLayer.path = upPath
                            upLayer.strokeColor = UIColor.clear.cgColor
                            upLayer.fillColor = upColor.cgColor
                        }
                        
                    } else { // 显示实心
                        if configuration.longDecreasingIsHollow {
                            writePath(into: upHollowPath, macd: macd, context: context, index: index, zeroY: zeroY)
                            upHollowLayer.path = upHollowPath
                            upHollowLayer.strokeColor = upColor.cgColor
                            upHollowLayer.fillColor = UIColor.clear.cgColor
                            
                        } else {
                            writePath(into: upPath, macd: macd, context: context, index: index, zeroY: zeroY)
                            upLayer.path = upPath
                            upLayer.strokeColor = UIColor.clear.cgColor
                            upLayer.fillColor = upColor.cgColor
                        }
                    }
                    
                    
                } else if (preMacd < 0 && macd < 0) { // 空
                    if macd > preMacd { // 显示空心
                        if configuration.longIncreasingIsHollow {
                            writePath(into: downHollowPath, macd: macd, context: context, index: index, zeroY: zeroY)
                            downHollowLayer.path = downHollowPath
                            downHollowLayer.strokeColor = downColor.cgColor
                            downHollowLayer.fillColor = UIColor.clear.cgColor
                            
                        } else {
                            writePath(into: downPath, macd: macd, context: context, index: index, zeroY: zeroY)
                            downLayer.path = downPath
                            downLayer.strokeColor = UIColor.clear.cgColor
                            downLayer.fillColor = downColor.cgColor
                        }
                     
                        
                    } else { // 显示实心
                        if configuration.longDecreasingIsHollow {
                            writePath(into: downHollowPath, macd: macd, context: context, index: index, zeroY: zeroY)
                            downHollowLayer.path = downHollowPath
                            downHollowLayer.strokeColor = downColor.cgColor
                            downHollowLayer.fillColor = UIColor.clear.cgColor
                            
                        } else {
                            writePath(into: downPath, macd: macd, context: context, index: index, zeroY: zeroY)
                            downLayer.path = downPath
                            downLayer.strokeColor = UIColor.clear.cgColor
                            downLayer.fillColor = downColor.cgColor
                        }
                    }
                    
                } else { // 显示实心
                    if (macd > 0) { // 多
                        if configuration.longIncreasingIsHollow {
                            writePath(into: upHollowPath, macd: macd, context: context, index: index, zeroY: zeroY)
                            upHollowLayer.path = upHollowPath
                            upHollowLayer.strokeColor = upColor.cgColor
                            upHollowLayer.fillColor = UIColor.clear.cgColor
                            
                        } else {
                            writePath(into: upPath, macd: macd, context: context, index: index, zeroY: zeroY)
                            upLayer.path = upPath
                            upLayer.strokeColor = UIColor.clear.cgColor
                            upLayer.fillColor = upColor.cgColor
                        }
                        
                        if configuration.longDecreasingIsHollow {
                            writePath(into: upHollowPath, macd: macd, context: context, index: index, zeroY: zeroY)
                            upHollowLayer.path = upHollowPath
                            upHollowLayer.strokeColor = upColor.cgColor
                            upHollowLayer.fillColor = UIColor.clear.cgColor
                            
                        } else {
                            writePath(into: upPath, macd: macd, context: context, index: index, zeroY: zeroY)
                            upLayer.path = upPath
                            upLayer.strokeColor = UIColor.clear.cgColor
                            upLayer.fillColor = upColor.cgColor
                        }
     
                    } else {
                        if configuration.shortIncreasingIsHollow {
                            writePath(into: downHollowPath, macd: macd, context: context, index: index, zeroY: zeroY)
                            downHollowLayer.path = downHollowPath
                            downHollowLayer.strokeColor = downColor.cgColor
                            downHollowLayer.fillColor = UIColor.clear.cgColor
                            
                        } else {
                            writePath(into: downPath, macd: macd, context: context, index: index, zeroY: zeroY)
                            downLayer.path = downPath
                            downLayer.strokeColor = UIColor.clear.cgColor
                            downLayer.fillColor = downColor.cgColor
                        }
                        
                        if configuration.shortDecreasingIsHollow {
                            writePath(into: downHollowPath, macd: macd, context: context, index: index, zeroY: zeroY)
                            downHollowLayer.path = downHollowPath
                            downHollowLayer.strokeColor = downColor.cgColor
                            downHollowLayer.fillColor = UIColor.clear.cgColor
                            
                        } else {
                            writePath(into: downPath, macd: macd, context: context, index: index, zeroY: zeroY)
                            downLayer.path = downPath
                            downLayer.strokeColor = UIColor.clear.cgColor
                            downLayer.fillColor = downColor.cgColor
                        }
                    }
                }
                
            } else { // 显示实心
                if (macd > 0) { // 多
                    if configuration.longIncreasingIsHollow {
                        writePath(into: upHollowPath, macd: macd, context: context, index: index, zeroY: zeroY)
                        upHollowLayer.path = upHollowPath
                        upHollowLayer.strokeColor = upColor.cgColor
                        upHollowLayer.fillColor = UIColor.clear.cgColor
                        
                    } else {
                        writePath(into: upPath, macd: macd, context: context, index: index, zeroY: zeroY)
                        upLayer.path = upPath
                        upLayer.strokeColor = UIColor.clear.cgColor
                        upLayer.fillColor = upColor.cgColor
                    }
                    
                    if configuration.longDecreasingIsHollow {
                        writePath(into: upHollowPath, macd: macd, context: context, index: index, zeroY: zeroY)
                        upHollowLayer.path = upHollowPath
                        upHollowLayer.strokeColor = upColor.cgColor
                        upHollowLayer.fillColor = UIColor.clear.cgColor
                        
                    } else {
                        writePath(into: upPath, macd: macd, context: context, index: index, zeroY: zeroY)
                        upLayer.path = upPath
                        upLayer.strokeColor = UIColor.clear.cgColor
                        upLayer.fillColor = upColor.cgColor
                    }
 
                } else {
                    if configuration.shortIncreasingIsHollow {
                        writePath(into: downHollowPath, macd: macd, context: context, index: index, zeroY: zeroY)
                        downHollowLayer.path = downHollowPath
                        downHollowLayer.strokeColor = downColor.cgColor
                        downHollowLayer.fillColor = UIColor.clear.cgColor
                        
                    } else {
                        writePath(into: downPath, macd: macd, context: context, index: index, zeroY: zeroY)
                        downLayer.path = downPath
                        downLayer.strokeColor = UIColor.clear.cgColor
                        downLayer.fillColor = downColor.cgColor
                    }
                    
                    if configuration.shortDecreasingIsHollow {
                        writePath(into: downHollowPath, macd: macd, context: context, index: index, zeroY: zeroY)
                        downHollowLayer.path = downHollowPath
                        downHollowLayer.strokeColor = downColor.cgColor
                        downHollowLayer.fillColor = UIColor.clear.cgColor
                        
                    } else {
                        writePath(into: downPath, macd: macd, context: context, index: index, zeroY: zeroY)
                        downLayer.path = downPath
                        downLayer.strokeColor = UIColor.clear.cgColor
                        downLayer.fillColor = downColor.cgColor
                    }
                }
            }
        }
    }


    private func writePath(into path: CGMutablePath,
                           macd: CGFloat,
                           context: RendererContext<Input>,
                           index: Int,
                           zeroY: CGFloat)
    {
        let barWidth = context.configuration.barWidth
        let spacing = context.configuration.spacing
        let barX = (barWidth + spacing) * CGFloat(index)
        let barRect = rect(for: macd,
                           x: _pixelCeil(barX),
                           width: barWidth,
                           zeroY: zeroY,
                           context: context)
        path.addRect(barRect)
    }

    private func rect(for macd: CGFloat,
                      x: CGFloat,
                      width: CGFloat,
                      zeroY: CGFloat,
                      context: Context) -> CGRect
    {
        let y = yOffset(for: macd, context: context)
        let (minY, maxY) = y > zeroY ? (zeroY, y) : (y, zeroY)
        let height = max(configuration.minBarHeight, maxY - minY)
        return CGRect(x: x, y: minY, width: width, height: height)
    }

    private func yOffset(for price: CGFloat, context: Context) -> CGFloat {
        let height = context.contentRect.height
        let minY = context.contentRect.minY
        let peak = context.extremePoint.max - context.extremePoint.min
        return height - height * (price - context.extremePoint.min) / peak + minY
    }
}

private extension Array {
    
    func safeObjec(_ index: Int) -> Element? {
        return (0..<count).contains(index) ? self[index] : nil
    }
    
    mutating func safeRemove(_ index: Int) {
        if (0..<count).contains(index) {
            remove(at: index)
        }
    }
}
