//
//  LatestPriceIndicator.swift
//  
//
//  Created by Lforme on 2022/4/6.
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

extension LatestPriceIndicator {
    
    class DshaLine: UIView {
        
        var color: UIColor = UIColor.lightGray
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            backgroundColor = .clear
        }
 
        override class var layerClass: AnyClass {
            return CAShapeLayer.self
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            drawDashLine()
        }
        
        private func drawDashLine() {
            
            if let shapeLayer = layer as? CAShapeLayer {
                shapeLayer.fillColor = UIColor.clear.cgColor
                shapeLayer.lineDashPattern = [2, 2]
                shapeLayer.lineWidth = 1
                shapeLayer.lineJoin = .round
                shapeLayer.strokeColor = color.cgColor
                
                let path = UIBezierPath()
                path.move(to: CGPoint(x: bounds.minX, y: bounds.midY))
                path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.midY))
                shapeLayer.path = path.cgPath
                
            }
        }
    }
}


extension LatestPriceIndicator {
    
    class Label: UILabel {

        var priceDecimal: Int = 0
        
        var contentInsets: UIEdgeInsets = .zero {
            didSet {
                setNeedsLayout()
                invalidateIntrinsicContentSize()
            }
        }
        
        private var displayLink: CADisplayLink?
        private lazy var startValue: Double = 0
        private lazy var endValue: Double = 0
        private lazy var duration: TimeInterval = 0.4
        private lazy var startTime: CFTimeInterval = 0
        
        deinit {
            displayLink?.invalidate()
            displayLink = nil
        }
        
        override var text: String? {
            didSet {
                guard let value = Double(text ?? "0") else { return }
                let old = Double(oldValue ?? "0") ?? 0
                startAnimation(oldValue: old, newValue: value)
            }
        }
        
        override func draw(_ rect: CGRect) {
            let insets = contentInsets
            super.drawText(in: rect.inset(by: insets))
        }
        
        override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
            let insets = contentInsets
            let insetRect = bounds.inset(by: insets)
            let textRect = super.textRect(forBounds: insetRect, limitedToNumberOfLines: numberOfLines)
            let invertedInsets = UIEdgeInsets(top: -insets.top, left: -insets.left, bottom: -insets.bottom, right: -insets.right)
            return textRect.inset(by: invertedInsets)
        }
        
        override var intrinsicContentSize: CGSize {
            let size = super.intrinsicContentSize
            let width = size.width + contentInsets.left + contentInsets.right
            let height = size.height + contentInsets.top + contentInsets.bottom
            return CGSize(width: width, height: height)
        }
        
        private func startAnimation(oldValue: Double, newValue: Double) {
            displayLink?.invalidate()
            
            startValue = oldValue
            endValue = newValue
            startTime = CACurrentMediaTime()
            
            displayLink = CADisplayLink(target: self, selector: #selector(LatestPriceIndicator.Label.updateValue))
            displayLink?.add(to: .main, forMode: .common)
        }
        
        @objc
        private func updateValue() {
            let currentTime = CACurrentMediaTime()
            let elapsedTime = currentTime - startTime
            
            if elapsedTime >= duration {
                super.text = String(format: "%.\(priceDecimal)f", endValue)
                displayLink?.invalidate()
                displayLink = nil
                
            } else {
                let percentage = elapsedTime / duration
                let value = startValue + (endValue - startValue) * percentage
                super.text = String(format: "%.\(priceDecimal)f", value)
            }
        }
    }
    
}


/// 用于绘制最新成交价格
public class LatestPriceIndicator<Input: Quote>: ChartRenderer {
    
    public lazy var priceDecimal: Int = 0
    
    public lazy var textColor: UIColor = .black {
        didSet {
            label.textColor = textColor
        }
    }
    
    public lazy var textBackgroundColor: UIColor = .white {
        didSet {
            label.backgroundColor = textBackgroundColor
        }
    }
    
    public lazy var textBorderColor: UIColor = .white {
        didSet {
            label.layer.borderColor = textBorderColor.cgColor
        }
    }
    
    public lazy var dashLineColor: UIColor = .lightGray {
        didSet {
            lineView1.color = dashLineColor
            lineView2.color = dashLineColor
        }
    }
    
    public typealias Input = Input
    public typealias QuoteProcessor = NopeQuoteProcessor<Input>
    
    private lazy var label: Label = {
        let it = Label(frame: .zero)
        it.font = UIFont.systemFont(ofSize: 10)
        it.textColor = textColor
        it.contentInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
        it.layer.cornerRadius = 4
        it.clipsToBounds = true
        it.layer.borderWidth = 1
        it.layer.borderColor = textBorderColor.cgColor
        it.textAlignment = .center
        it.backgroundColor = textBackgroundColor
        return it
    }()
    
    private lazy var lineView1: DshaLine = {
        let it = DshaLine(frame: .zero)
        return it
    }()
    
    private let lineView2: DshaLine = {
        let it = DshaLine(frame: .zero)
        return it
    }()
    
    private var height: CGFloat
    private var minWidth: CGFloat
    private var maxWidth: CGFloat
    
    /// 最新成交价的指示器
    /// - Parameters:
    ///   - height: Label 高度
    ///   - minWidth: 最小宽度
    ///   - maxWidth: Label 最大宽度
    ///   - textColor: 文字颜色，默认白色
    public init(height: CGFloat = 18,
                minWidth: CGFloat = 36,
                maxWidth: CGFloat = 80) {
        self.height = height
        self.minWidth = minWidth
        self.maxWidth = maxWidth
    }
    
    public func updateZPosition(_ position: CGFloat) {
        label.layer.zPosition = position
        lineView1.layer.zPosition = position
        lineView2.layer.zPosition = position
    }
    
    public func setup(in view: ChartView<Input>) {
        lineView1.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        lineView2.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        
        view.addSubview(lineView1)
        view.addSubview(lineView2)
        view.addSubview(label)
    }
    
    public func render(in view: ChartView<Input>, context: Context) {
        guard let last = context.data.last else {
            label.isHidden = true
            lineView1.isHidden = true
            lineView2.isHidden = true
            return
        }
        
        label.isHidden = false
        label.text = context.preferredFormatter.format(last.close)
        label.priceDecimal = priceDecimal
        
        let y = context.yOffset(for: last.close)
        var size = label.sizeThatFits(.init(width: maxWidth, height: height))
        size.width = min(maxWidth, max(size.width, minWidth))
        size.height = height
        let maxX = view.contentOffset.x + view.frame.width
        let minY = context.contentRect.minY
        let maxY = context.groupContentRect.maxY
        var frame = CGRect(origin: CGPoint(x: maxX - size.width, y: y - height / 2),
                           size: size)
        let _y = min(max(frame.origin.y, minY), maxY - height)
        frame.origin.y = _y
        label.frame.origin.x = frame.origin.x
        label.frame.size.width = frame.size.width
        label.frame.size.height = frame.size.height
    
        if label.frame.origin.y != frame.origin.y && !view.isInGestureZoom && !view.isReload {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut) {
                self.label.frame.origin.y = frame.origin.y
                self.lineView2.frame.origin.y = frame.midY
                self.lineView1.frame.origin.y = frame.midY
            }
            
        } else {
            self.label.frame.origin.y = frame.origin.y
            self.lineView2.frame.origin.y = frame.midY
            self.lineView1.frame.origin.y = frame.midY
        }

        let _x = context.xOffsetFetchLatestQuote()
        
        if maxX - _x <= 0 {
            lineView2.isHidden = false
            lineView1.isHidden = true
            
        } else {
            lineView2.isHidden = true
            lineView1.isHidden = false
        }
        
        lineView2.frame.size.width = view.frame.size.width
        lineView2.frame.origin.x = view.contentOffset.x
     
        lineView1.frame.size.width = view.frame.size.width
        lineView1.frame.origin.x = _x + (6 * view.chartZoomScale)
        
    }
    
    public func tearDown(in view: ChartView<Input>) {
        label.removeFromSuperview()
        lineView1.removeFromSuperview()
        lineView2.removeFromSuperview()
    }
    
    public func extremePoint(contextValues: ContextValues, visibleRange: Range<Int>) -> (min: CGFloat, max: CGFloat)? {
        return nil
    }
}
