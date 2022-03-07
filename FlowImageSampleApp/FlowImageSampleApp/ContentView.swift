//
//  ContentView.swift
//  FlowImageSampleApp
//
//  Created by Xuezheng Wang on 2/23/22.
//

import SwiftUI

struct ContentView: View {
    @State var image = sampleImages[0]
    var body: some View {
        NavigationView {
            List {
                NavigationLink("Level 1: Using URLFlowImage") {
                    Level1View()
                }

                NavigationLink("Level 2: Using URLFlowImage with FlowImageView") {
                    Level2View()
                }
            }
        }
        .navigationTitle("FlowImage Sample App")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
