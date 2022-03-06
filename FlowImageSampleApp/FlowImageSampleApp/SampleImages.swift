//
//  SampleImages.swift
//  FlowImageSampleApp
//
//  Created by Xuezheng Wang on 3/5/22.
//

import FlowImage
import Foundation
import UIKit

var sampleImages: [FlowImage] {
    var images: [FlowImage] = []
    images.append(contentsOf: imageURLs.map { URLFlowImage($0) })
    images.append(sampleDownloadedFLowImage)

    return images
}

// MARK: Two URLFlowImage
let imageURLs = [
    URL(string: "https://i.guim.co.uk/img/media/b563ac5db4b4a4e1197c586bbca3edebca9173cd/0_12_3307_1985/master/3307.jpg?width=1200&height=900&quality=85&auto=format&fit=crop&s=61a26bf43da26e4ca97e932e5ee113f7")!,
    URL(string: "https://img1.baidu.com/it/u=1667044935,2962646688&fm=253&fmt=auto&app=138&f=JPEG?w=500&h=708")!
]

// MARK: A Few local Images
let sampleUIImage1 = UIImage(named: "craig")!
let sampleDownloadedFLowImage = DownloadedFlowImage(uiImage: sampleUIImage1)