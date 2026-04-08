import Foundation
import SwiftUI

@MainActor
@Observable
class CanvasState {
    var tilePositions: [String: CGPoint] = [:]
    var zoom: CGFloat = 0.8
    var panOffset: CGPoint = .zero

    // Gesture state
    var lastPanOffset: CGPoint = .zero
    var lastZoom: CGFloat = 0.8

    var zoomPercentage: Int {
        Int(zoom * 100)
    }

    func position(for projectID: String, index: Int, total: Int) -> CGPoint {
        if let existing = tilePositions[projectID] {
            return existing
        }
        // Auto-layout: arrange in a loose grid with some organic offset
        let cols = max(2, Int(ceil(sqrt(Double(total)))))
        let row = index / cols
        let col = index % cols
        let baseX = CGFloat(col) * 340 + 60
        let baseY = CGFloat(row) * 260 + 60
        // Add slight organic offset so it doesn't look like a rigid grid
        let offsetX = CGFloat((index * 37) % 30) - 15
        let offsetY = CGFloat((index * 53) % 20) - 10
        let point = CGPoint(x: baseX + offsetX, y: baseY + offsetY)
        tilePositions[projectID] = point
        return point
    }

    func updatePosition(for projectID: String, to point: CGPoint) {
        tilePositions[projectID] = point
    }

    func zoomIn() {
        zoom = min(2.0, zoom + 0.1)
        lastZoom = zoom
    }

    func zoomOut() {
        zoom = max(0.3, zoom - 0.1)
        lastZoom = zoom
    }

    func resetZoom() {
        zoom = 0.8
        lastZoom = 0.8
        panOffset = .zero
        lastPanOffset = .zero
    }
}
