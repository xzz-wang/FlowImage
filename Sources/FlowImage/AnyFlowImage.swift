//
//  AnyFlowImage.swift
//  
//
//  Created by Xuezheng Wang on 2/21/22.
//

import UIKit

// Type Erasing reference: [https://khawerkhaliq.com/blog/swift-protocols-equatable-part-two/]
struct AnyFlowImage: FlowImage, Equatable, Hashable, Identifiable {
    private let picture: FlowImage

    var id: ID {
        picture.id
    }

    init(_ picture: FlowImage) {
        self.picture = picture
    }

    func prepareForDisplay() async throws -> FlowImage {
        try await picture.prepareForDisplay()
    }

    func getUIImage() async throws -> UIImage {
        try await picture.getUIImage()
    }

    func hash(into hasher: inout Hasher) {
        picture.hash(into: &hasher)
    }

    static func == (lhs: AnyFlowImage, rhs: AnyFlowImage) -> Bool {
        return lhs.id == rhs.id
    }
}
