//
//  AnyFlowImage.swift
//  
//
//  Created by Xuezheng Wang on 2/21/22.
//

import UIKit

// Type Erasing reference: [https://khawerkhaliq.com/blog/swift-protocols-equatable-part-two/]
public struct AnyFlowImage: FlowImage, Equatable, Hashable, Identifiable {
    private let picture: FlowImage

    public var id: ID {
        picture.id
    }

    init(_ picture: FlowImage) {
        self.picture = picture
    }

    public func prepareForDisplay() async throws -> FlowImage {
        try await picture.prepareForDisplay()
    }

    public func getUIImage() async throws -> UIImage {
        try await picture.getUIImage()
    }

    public func hash(into hasher: inout Hasher) {
        picture.hash(into: &hasher)
    }

    public static func == (lhs: AnyFlowImage, rhs: AnyFlowImage) -> Bool {
        return lhs.id == rhs.id
    }
}
