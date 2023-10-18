import SwiftUI
@available(macOS 12.0, *)
struct ContentView: View {
    var body: some View {
        MainUIView()
        .padding()
    }
}

@available(macOS 12.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
