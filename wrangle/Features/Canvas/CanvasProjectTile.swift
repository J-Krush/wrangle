import SwiftUI

struct CanvasProjectTile: View {
    let project: ProjectInfo
    let position: CGPoint
    let onDragEnd: (CGPoint) -> Void
    let onDoubleTap: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    private let tileWidth: CGFloat = 300
    private let tileHeight: CGFloat = 180

    var body: some View {
        ProjectCardView(project: project)
            .frame(width: tileWidth, height: tileHeight)
            .shadow(
                color: project.hasRunningAgent
                    ? project.agentStatus.dotColor.opacity(0.2)
                    : .black.opacity(0.3),
                radius: project.hasRunningAgent ? 12 : 6,
                y: 2
            )
            .scaleEffect(isDragging ? 1.03 : 1.0)
            .position(
                x: position.x + dragOffset.width,
                y: position.y + dragOffset.height
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        isDragging = false
                        let newPosition = CGPoint(
                            x: position.x + value.translation.width,
                            y: position.y + value.translation.height
                        )
                        dragOffset = .zero
                        onDragEnd(newPosition)
                    }
            )
            .simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded { onDoubleTap() }
            )
            .animation(.spring(response: 0.3), value: isDragging)
    }
}
