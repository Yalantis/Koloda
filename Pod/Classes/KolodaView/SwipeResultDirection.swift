//
//  SwipeDirection.swift
//  Pods
//
//  Created by Felix Dumit on 2/25/16.
//
//

import Foundation
import CoreGraphics

public enum SwipeResultDirection: String {
    
    case left
    case right
    case up
    case down
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

extension SwipeResultDirection {
    
    private var swipeDirection: Direction {
        switch self {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return  .right
        case .topLeft: return .topLeft
        case .topRight: return .topRight
        case .bottomLeft: return .bottomLeft
        case .bottomRight: return .bottomRight
        }
    }
    
    var point: CGPoint {
        return self.swipeDirection.point
    }
    
    var bearing: Double {
        return self.swipeDirection.bearing
    }
    
    static var boundsRect: CGRect {
        let w = HorizontalPosition.right.rawValue - HorizontalPosition.left.rawValue
        let h = VerticalPosition.bottom.rawValue - VerticalPosition.top.rawValue
        return CGRect(x: HorizontalPosition.left.rawValue, y: VerticalPosition.top.rawValue, width: w, height: h)
    }
}


private enum VerticalPosition: CGFloat {
    
    case top = -1
    case middle = 0
    case bottom = 1
}

private enum HorizontalPosition: CGFloat {
    
    case left = -1
    case middle = 0
    case right = 1
}


private struct Direction {
    
    let horizontalPosition:HorizontalPosition
    let verticalPosition:VerticalPosition
    
    var point: CGPoint {
        return CGPoint(x:horizontalPosition.rawValue, y: verticalPosition.rawValue)
    }
    
    var bearing: Double {
        return self.point.bearingTo(Direction.none.point)
    }
    
    static let none = Direction(horizontalPosition: .middle, verticalPosition: .middle)
    static let up = Direction(horizontalPosition: .middle, verticalPosition: .top)
    static let down = Direction(horizontalPosition: .middle, verticalPosition: .bottom)
    static let left = Direction(horizontalPosition: .left, verticalPosition: .middle)
    static let right = Direction(horizontalPosition: .right, verticalPosition: .middle)
    
    static let topLeft = Direction(horizontalPosition: .left, verticalPosition: .top)
    static let topRight = Direction(horizontalPosition: .right, verticalPosition: .top)
    static let bottomLeft = Direction(horizontalPosition: .left, verticalPosition: .bottom)
    static let bottomRight = Direction(horizontalPosition: .right, verticalPosition: .bottom)
}


//MARK: Geometry

extension CGPoint {
    func distanceTo(_ point: CGPoint) -> CGFloat {
        return sqrt(pow(point.x - self.x, 2) + pow(point.y - self.y, 2))
    }
    
    func bearingTo(_ point: CGPoint) -> Double {
        return atan2(Double(point.y - self.y), Double(point.x - self.x))
    }
    
    func scalarProjectionWith(_ point: CGPoint) -> CGFloat {
        return dotProductWith(point) / point.modulo
    }
    
    func scalarProjectionPointWith(_ point: CGPoint) -> CGPoint {
        let r = scalarProjectionWith(point) / point.modulo
        return CGPoint(x: point.x * r, y: point.y * r)
    }
    
    func dotProductWith(_ point: CGPoint) -> CGFloat {
        return (self.x * point.x) + (self.y * point.y)
    }
    
    var modulo: CGFloat {
        return sqrt(self.x*self.x + self.y*self.y)
    }
    
    func distanceToRect(_ rect: CGRect) -> CGFloat {
        if rect.contains(self) {
            return distanceTo(CGPoint(x: rect.midX, y: rect.midY))
        }
        let dx = max(rect.minX - self.x, self.x - rect.maxX, 0)
        let dy = max(rect.minY - self.y, self.y - rect.maxY, 0)
        if dx * dy == 0 {
            return max(dx, dy)
        } else {
            return hypot(dx, dy)
        }
    }
    
    func normalizedDistanceForSize(_ size: CGSize) -> CGPoint {
        // multiplies by 2 because coordinate system is (-1,1)
        let x = 2 * (self.x / size.width)
        let y = 2 * (self.y / size.height)
        return CGPoint(x: x, y: y)
    }
    
    func normalizedPointForSize(_ size:CGSize) -> CGPoint {
        let x = (self.x / (size.width * 0.5)) - 1
        let y = (self.y / (size.height * 0.5)) - 1
        return CGPoint(x: x, y: y)
    }
    
    func screenPointForSize(_ screenSize: CGSize) -> CGPoint {
        let x = 0.5 * (1 + self.x) * screenSize.width
        let y = 0.5 * (1 + self.y) * screenSize.height
        return CGPoint(x: x, y: y)
    }
    
    static func intersectionBetweenLines(_ line1: CGLine, line2: CGLine) -> CGPoint? {
        let (p1,p2) = line1
        let (p3,p4) = line2
        
        var d = (p4.y - p3.y) * (p2.x - p1.x) - (p4.x - p3.x) * (p2.y - p1.y)
        var ua = (p4.x - p3.x) * (p1.y - p4.y) - (p4.y - p3.y) * (p1.x - p3.x)
        var ub = (p2.x - p1.x) * (p1.y - p3.y) - (p2.y - p1.y) * (p1.x - p3.x)
        if (d < 0) {
            ua = -ua; ub = -ub; d = -d
        }
        
        if d != 0 {
            return CGPoint(x: p1.x + ua / d * (p2.x - p1.x), y: p1.y + ua / d * (p2.y - p1.y))
        }
        return nil
    }
}

typealias CGLine = (start: CGPoint, end: CGPoint)

extension CGRect {
    
    var topLine: CGLine {
        return (Direction.topLeft.point, Direction.topRight.point)
    }
    var leftLine: CGLine {
        return (Direction.topLeft.point, Direction.bottomLeft.point)
    }
    var bottomLine: CGLine {
        return (Direction.bottomLeft.point, Direction.bottomRight.point)
    }
    var rightLine: CGLine {
        return (Direction.topRight.point, Direction.bottomRight.point)
    }
    
    var perimeterLines: [CGLine] {
        return [topLine, leftLine, bottomLine, rightLine]
    }
}
