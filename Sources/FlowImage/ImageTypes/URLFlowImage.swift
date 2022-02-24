//
//  URLFlowImage.swift
//  
//
//  Created by Xuezheng Wang on 2/23/22.
//

import UIKit

public class URLFlowImage: FlowImage {
    public var id: ID

    internal let url: URL

    public init(_ url: URL) {
        self.url = url
        self.id = "URLFlowImage - " + url.absoluteString
    }

    public func prepareForDisplay() async throws -> FlowImage {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = DownloadedFlowImage(data: data) else {
            throw FlowImageError.dataToImageConvertionFailed
        }
        return try await image.prepareForDisplay()
    }

    public func getUIImage() async throws -> UIImage {
        let image = try await self.prepareForDisplay()
        return try await image.getUIImage()
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }


}
