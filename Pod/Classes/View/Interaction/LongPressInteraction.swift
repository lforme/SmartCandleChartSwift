//
//  LongPressInteraction.swift
//  
//
//  Created by Lforme on 2022/3/22.
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

final class LongPressInteraction: NSObject, UIInteraction {
    weak var view: UIView?
    private lazy var gesture: UILongPressGestureRecognizer = .init(target: self, action: #selector(handleLongPress(gesture:)))

    private var binding: Binding<CGPoint>

    init(binding: Binding<CGPoint>) {
        self.binding = binding
        super.init()
        gesture.delegate = self
    }

    func willMove(to view: UIView?) {
        self.view?.removeGestureRecognizer(gesture)
        self.view = nil
    }

    func didMove(to view: UIView?) {
        self.view = view
        view?.addGestureRecognizer(gesture)
    }

    @objc private func handleLongPress(gesture: UILongPressGestureRecognizer) {
        guard let view = view else { return }
        switch gesture.state {
        case .began, .changed:
            binding.wrappedValue = gesture.location(in: view)
        default:
            break
        }
    }
}

extension LongPressInteraction: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer is UIPanGestureRecognizer {
            return false
        }
        return otherGestureRecognizer.view !== view
    }
}
