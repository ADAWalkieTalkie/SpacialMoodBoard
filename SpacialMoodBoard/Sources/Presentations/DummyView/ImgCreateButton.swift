import SwiftUI

struct ImgCreateButton: View {
    let title: String
    let imageName: String
    
    var body: some View {
        Button(title) {
            // appModel.requestSpawnImage(imageName: "goldfish")
        }
        .buttonStyle(.borderedProminent)
    }
}