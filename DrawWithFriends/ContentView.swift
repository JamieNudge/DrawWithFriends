import SwiftUI

struct ContentView: View {
    @State private var currentDrawing = Drawing()
    @State private var drawings: [Drawing] = []
    
    var body: some View {
        VStack {
            Text("Draw With Friends")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            DrawingCanvas(currentDrawing: $currentDrawing, drawings: $drawings)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .border(Color.gray, width: 2)
                .padding()
            
            HStack {
                Button("Clear") {
                    drawings.removeAll()
                    currentDrawing = Drawing()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Spacer()
                
                Text("Tap and drag to draw")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
        }
    }
}

struct Drawing: Identifiable {
    var id = UUID()
    var points: [CGPoint] = []
}

struct DrawingCanvas: View {
    @Binding var currentDrawing: Drawing
    @Binding var drawings: [Drawing]
    
    var body: some View {
        Canvas { context, size in
            for drawing in drawings {
                var path = Path()
                if let firstPoint = drawing.points.first {
                    path.move(to: firstPoint)
                    for point in drawing.points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                context.stroke(path, with: .color(.blue), lineWidth: 3)
            }
            
            var path = Path()
            if let firstPoint = currentDrawing.points.first {
                path.move(to: firstPoint)
                for point in currentDrawing.points.dropFirst() {
                    path.addLine(to: point)
                }
            }
            context.stroke(path, with: .color(.blue), lineWidth: 3)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    currentDrawing.points.append(value.location)
                }
                .onEnded { _ in
                    drawings.append(currentDrawing)
                    currentDrawing = Drawing()
                }
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
