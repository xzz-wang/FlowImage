//
//  Level1View.swift
//  FlowImageSampleApp
//
//  Created by Xuezheng Wang on 3/6/22.
//

import FlowImage
import SwiftUI

struct Level1View: View {
    let flowImage: FlowImage = sampleURLFlowImage2
    @State private var image: UIImage? = nil

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Text("Loading")
            }
        }
        .task {
            image = try? await flowImage.getUIImage()
        }
    }
}

struct Level1View_Previews: PreviewProvider {
    static var previews: some View {
        Level1View()
    }
}
