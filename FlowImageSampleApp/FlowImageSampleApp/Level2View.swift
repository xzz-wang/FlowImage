//
//  Level1View.swift
//  FlowImageSampleApp
//
//  Created by Xuezheng Wang on 3/5/22.
//

import FlowImage
import SwiftUI

struct Level2View: View {
    @State var image: FlowImage? = nil
    
    var body: some View {
        VStack {
            SampleImageView(image: image)
                .frame(height: 300)

            List {
                Section("Tap to change the image") {
                    changeButton(imgName: "URLFlowImage1", sampleURLFlowImage1)
                    changeButton(imgName: "URLFlowImage2", sampleURLFlowImage2)
                    changeButton(imgName: "Normal DownloadedFlowImage", sampleDownloadedFLowImage)
                    changeButton(imgName: "Async wait for 5 seconds", sampleWaitGetImage)
                    changeButton(imgName: "Fail right away", sampleFailGetImage)
                    changeButton(imgName: "Wait then fail", sampleWaitAndFailGetImage)
                    changeButton(imgName: "No Image", nil)
                }
            }
        }
    }

    @ViewBuilder
    func changeButton(imgName: String, _ flowImage: FlowImage?) -> some View {
        Button {
            image = flowImage
        } label: {
            Text(imgName)
        }
    }
}

struct SampleImageView: View {
    let image: FlowImage?

    var body: some View {
        FlowImageView(image: image) { uiimage, state in
            ZStack {
                if state == .displaying {
                    if let image = uiimage {
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
                    if let image = uiimage {
                        // If image is not nil when loading, it will be the image
                        // before we started loading.
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .colorMultiply(.init(red: 0.5, green: 0.5, blue: 0.5))

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
