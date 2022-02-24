//
//  ContentView.swift
//  FlowImageSampleApp
//
//  Created by Xuezheng Wang on 2/23/22.
//

import SwiftUI
import FlowImage

struct ContentView: View {
    @State var image = URLFlowImage(URL(string: "https://i.guim.co.uk/img/media/b563ac5db4b4a4e1197c586bbca3edebca9173cd/0_12_3307_1985/master/3307.jpg?width=1200&height=900&quality=85&auto=format&fit=crop&s=61a26bf43da26e4ca97e932e5ee113f7")!)
    var body: some View {
        VStack {
            ImageView(image: image)
            ImageView(image: image)
            ImageView(image: image)

            Button {
                image = URLFlowImage(URL(string: "https://img1.baidu.com/it/u=1667044935,2962646688&fm=253&fmt=auto&app=138&f=JPEG?w=500&h=708")!)
            } label: {
                Text("Change")
            }
        }
    }

    private struct ImageView: View {
        let image: FlowImage

        var body: some View {
            FlowImageView(image: image) { image, state in
                VStack {
                    Text("Yayy")
                    if state == .displaying, let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else if state == .error {
                        Text("There was an error!")
                    } else if state == .loading {
                        Text("Loading!")
                    } else {
                        Text("No image")
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
