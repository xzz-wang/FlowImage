//
//  DownloadedFlowImage.swift
//
//  Created by Xuezheng Wang on 1/16/22.
//

import UIKit

public class DownloadedFlowImage: FlowImage {
    public var id: ID {
        "DownloadedPicture: \(rendered) - \(uiImage.hashValue)"
    }

    internal var uiImage: UIImage
    internal var rendered: Bool

    public init(uiImage: UIImage, rendered: Bool = false) {
        self.uiImage = uiImage
        self.rendered = rendered
    }

    /// Returns nil if we can not create UIImage from Data
    public init?(data: Data) {
        guard let uiImage = UIImage(data: data) else {
            return nil
        }

        self.uiImage = uiImage
        self.rendered = false
    }

    public func prepareForDisplay() async throws -> FlowImage {
        if rendered {
            return self
        }

        if let newImg = await uiImage.byPreparingForDisplay() {
            return DownloadedFlowImage(uiImage: newImg, rendered: true)
        } else {
            throw FlowImageError.uiImageDecodeFailed
        }
    }

    public func getUIImage() async throws -> UIImage {
        if !rendered {
            let newPic = try await prepareForDisplay()
            uiImage = try await newPic.getUIImage()
            rendered = true
        }
        return uiImage
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(uiImage)
        hasher.combine(rendered)
    }
}
