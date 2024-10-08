//
//  CandlestickChart.swift
//  
//
//  Created by Lforme on 2022/3/17.
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

/// 绘制蜡烛图的图表
public final class CandlestickChart<Input: Quote>: ChartRenderer {
    public typealias Input = Input
    public typealias QuoteProcessor = NopeQuoteProcessor<Input>
    /// 最小高度
    public let minHeight: CGFloat

    private var upLayer: ShapeLayer = {
        let layer = ShapeLayer()
        return layer
    }()

    private var downLayer: ShapeLayer = {
        let layer = ShapeLayer()
        return layer
    }()
    
    private lazy var animationView: UIView = {
        let it = UIView(frame: .zero)
        it.backgroundColor = .clear
        return it
    }()
    
    /// 创建蜡烛图图表
    /// - Parameter minHeight: 最小高度，默认为 1pt
    public init(minHeight: CGFloat = 1) {
        self.minHeight = minHeight
    }

    public func setup(in view: ChartView<Input>) {
        view.layer.addSublayer(upLayer)
        view.layer.addSublayer(downLayer)
        view.addSubview(animationView)
    }

    public func updateZPosition(_ position: CGFloat) {
        upLayer.zPosition = position
        downLayer.zPosition = position
    }

    public func render(in view: ChartView<Input>, context: Context) {
        
        let data = context.contextValues[QuoteContextKey<Input>.self] ?? []
        upLayer.fillColor = context.configuration.upColor.cgColor
        downLayer.fillColor = context.configuration.downColor.cgColor
        
        let maxX = view.contentOffset.x + view.frame.width
        let _x = context.xOffsetFetchLatestQuote()
        
        animationView.isHidden = view.isInGestureZoom || view.isReload || (maxX - _x <= 0)
  
        let upPath = CGMutablePath()
        let downPath = CGMutablePath()
        for index in context.visibleRange {
            let quote = data[index]
            if quote.open > quote.close {
                if data.count - 1 == index && !view.isInGestureZoom && !view.isReload {
                    var lastRect = writePath(into: downPath, data: data, context: context, index: index)
                    animation(rect: CGRect(x: lastRect.origin.x, y: lastRect.origin.y, width: context.configuration.barWidth, height: lastRect.size.height), color: context.configuration.downColor)
                    
                    onlyWriteShadow(into: downPath, data: data, context: context, index: index, layer: downLayer)
                    
                } else {
                    writePath(into: downPath, data: data, context: context, index: index)
                    downLayer.path = downPath
                }
                
            } else {
                if data.count - 1 == index && !view.isInGestureZoom && !view.isReload {
                    var lastRect = writePath(into: upPath, data: data, context: context, index: index)
                    animation(rect: CGRect(x: lastRect.origin.x, y: lastRect.origin.y, width: context.configuration.barWidth, height: lastRect.size.height), color: context.configuration.upColor)
                    
                    onlyWriteShadow(into: upPath, data: data, context: context, index: index, layer: upLayer)
                    
                } else {
                    writePath(into: upPath, data: data, context: context, index: index)
                    upLayer.path = upPath
                }
            }
        }
    }

    public func tearDown(in view: ChartView<Input>) {
        upLayer.removeFromSuperlayer()
        downLayer.removeFromSuperlayer()
        animationView.removeFromSuperview()
    }

    public func extremePoint(contextValues: ContextValues, visibleRange: Range<Int>) -> (min: CGFloat, max: CGFloat)? {
        guard let data = contextValues[QuoteContextKey<Input>.self],
              data[visibleRange].count > 0
        else {
            return nil
        }
        let min = data[visibleRange].map { $0.low }.min()!
        let max = data[visibleRange].map { $0.high }.max()!
        return (min, max)
    }
}

private extension CandlestickChart {
    
    private func onlyWriteShadow(into path: CGMutablePath,
                                 data: [Input],
                                 context: RendererContext<Input>,
                                 index: Int, layer: ShapeLayer) {
        let barWidth = context.configuration.barWidth
        let spacing = context.configuration.spacing
        let shadowWidth = context.configuration.shadowLineWidth
        let quote = data[index]
        let barX = (barWidth + spacing) * CGFloat(index)

        let lineX = barX + (barWidth - shadowWidth) / 2

        let lineRect = rect(for: (quote.low, quote.high),
                            x: _pixelCeil(lineX),
                            width: shadowWidth,
                            context: context)
        path.addRect(lineRect)
        layer.path = path
    }
    
    @discardableResult
    private func writePath(into path: CGMutablePath,
                           data: [Input],
                           context: RendererContext<Input>,
                           index: Int) -> CGRect
    {
        let barWidth = context.configuration.barWidth
        let spacing = context.configuration.spacing
        let shadowWidth = context.configuration.shadowLineWidth
        let quote = data[index]
        let barX = (barWidth + spacing) * CGFloat(index)

        let lineX = barX + (barWidth - shadowWidth) / 2
        let barRect = rect(for: (quote.open, quote.close),
                           x: _pixelCeil(barX),
                           width: barWidth,
                           context: context)
        path.addRect(barRect)

        let lineRect = rect(for: (quote.low, quote.high),
                            x: _pixelCeil(lineX),
                            width: shadowWidth,
                            context: context)
        path.addRect(lineRect)
        return barRect
    }

    private func rect(for pricePair: (CGFloat, CGFloat), x: CGFloat, width: CGFloat, context: Context) -> CGRect {
        let y1 = yOffset(for: pricePair.0, context: context)
        let y2 = yOffset(for: pricePair.1, context: context)
        let y = _pixelCeil(min(y1, y2))
        let height = max(_pixelCeil(abs(y1 - y2)), minHeight)
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func yOffset(for price: CGFloat, context: Context) -> CGFloat {
        let height = context.contentRect.height
        let minY = context.contentRect.minY
        let peak = context.extremePoint.max - context.extremePoint.min
        return height - height * (price - context.extremePoint.min) / peak + minY
    }
    
    private func animation(rect: CGRect, color: UIColor) {
        if rect.isNull {
            return
        }
        
        if animationView.frame == rect {
            return
        }
        animationView.frame.size.width = rect.width
        animationView.frame.origin.y = rect.origin.y
        animationView.frame.origin.x = rect.origin.x
        animationView.backgroundColor = color
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut) {
            self.animationView.frame.size.height = rect.height
        }
    }
}
