//
//  Level1View.swift
//  FlowImageSampleApp
//
//  Created by Xuezheng Wang on 3/5/22.
//

import FlowImage
import SwiftUI

struct Level2View: View {
    @State var image: FlowImage = sampleImages[0]
    
    var body: some View {
        VStack {
            SampleImageView(image: image)
                .frame(height: 400)

            ForEach(sampleImages.indices, id: \.self) { idx in
                let sampleImage = sampleImages[idx]
                Button {
                    image = sampleImage
                } label: {
                    Text("Image #\(idx)")
                }
            }
        }
    }
}

struct SampleImageView: View {
    let image: FlowImage

    var body: some View {
        FlowImageView(image: image) { image, state in
            ZStack {
                if state == .displaying {
                    if let image = image {
                        // Being in here means we have a proper image to display
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)

                    } else {
                        // If the image is nil and we are displaying, it means the
                        // FlowImage that's passed in is nil.
                        Text("No Image")
                    }
                } else if state == .error {
                    // If state == .error, it means an error occurred, and image
                    // value is set to nil.
                    Text("There was an error!")

                } else if state == .loading {
                    if let image = image {
                        // If image is not nil when loading, it will be the image
                        // before we started loading.
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .colorMultiply(.init(red: 0.7, green: 0.7, blue: 0.7))

                    }

                    // We overlay a progress view if we are loading.
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
        }
    }
}

struct Level2View_Previews: PreviewProvider {
    static var previews: some View {
        Level2View()
    }
}
