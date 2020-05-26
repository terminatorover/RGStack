//
//  Helpers.swift
//  UI
//
//  Created by ROBERA GELETA on 4/23/20.
//  Copyright © 2020 ROBERA GELETA. All rights reserved.
//

import UIKit
// swiftlint:disable identifier_name
extension Array {
    func mapIndex<T>(_ closure: (Int, Element) -> T) -> [T] {
        var mapped: [T] = []
        for (index, item) in enumerated() {
            mapped.append(closure(index, item))
        }
        return mapped
    }

    func rightShift() -> Array {
        var new = self
        guard let lastElement = last else { return [] }
        for index in indices where index > 0 {
            new[index] = self[index - 1]
        }
        new[0] = lastElement
        return new
    }

    func leftShift() -> Array {
        var new = self
        guard let firstElement = first else { return [] }
        for index in indices where index - 1 >= 0 {
            let toIndex = index - 1
            new[toIndex] = self[index]
        }
        new[count - 1] = firstElement
        return new
    }

    func get(index: Int) -> Element? {
        guard
            index >= 0,
            index <= (count - 1) else { return nil }
        return self[index]
    }
}

extension CGFloat {
    static func interpolate(from: CGFloat, to: CGFloat, progress: CGFloat) -> CGFloat {
        let diff = to - from
        guard progress != 0 else { return from }
        return (diff * progress) + from
    }

    func interpolate(to: CGFloat, progress: CGFloat) -> CGFloat {
        return CGFloat.interpolate(from: self, to: to, progress: progress)
    }
}

extension Double {
    func interpolate(to: Double, progress: Double) -> Double {
        let diff = to - self
        guard progress != 0 else { return self }
        return (diff * progress) + self
    }
}

extension CGPoint {
    func interpolate(to: CGPoint, progress: CGFloat) -> CGPoint {
        return CGPoint(x: x.interpolate(to: to.x, progress: progress),
                       y: y.interpolate(to: to.y, progress: progress))
    }
}

extension CGSize {
    func interpolate(to: CGSize, progress: CGFloat) -> CGSize {
        return CGSize(width: width.interpolate(to: to.width, progress: progress),
                      height: height.interpolate(to: to.height, progress: progress))
    }
}
