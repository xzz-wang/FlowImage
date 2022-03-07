//
//  TestFlowImage.swift
//  
//
//  Created by Xuezheng Wang on 3/6/22.
//

import UIKit

/// You can use this class to test your UI. Configure the behavior of this class
/// by passing in different parameters to the constructor.
public class TestFlowImage: FlowImage {
    public let id: ID

    private let img: UIImage
    private let failPrepare: Bool
    private let failGet: Bool
    private let delayPrepare: Bool
    private let delayGet: Bool
    private let delay: UInt64


    /// Initialize the testing class object.
    /// - Parameters:
    ///  - _: The UIImage to be returned.
    ///  - id: The id of the image. Used in cache.
    ///  - failPrepare: prepareForDisplay() will throw error if this is true.
    ///  - failGet: getUIImage() will throw error if this is true.
    ///  - delayPrepare: prepareForDisplay() will wait if this is true.
    ///  - delayGet: getUIImage() will wait if this is true.
    ///  - delayInSeconds: The during that we wait.
    public init(
        _ uiimage: UIImage,
        id: ID? = nil,
        failPrepare: Bool = false,
        failGet: Bool = false,
        delayPrepare: Bool = false,
        delayGet: Bool = false,
        delayInSeconds: Double = 2
    ) {
        self.img = uiimage
        self.id = id ?? "TestImage - \(img.hashValue)"
        self.failPrepare = failPrepare
        self.failGet = failGet
        self.delayGet = delayGet
        self.delayPrepare = delayPrepare
        self.delay = UInt64(1_000_000_000 * delayInSeconds)
    }

    public func prepareForDisplay() async throws -> FlowImage {
        if failPrepare { throw FlowImageError.failedForTest }
        if delayPrepare { try? await Task.sleep(nanoseconds: delay) }
        return self
    }

    public func getUIImage() async throws -> UIImage {
        if failGet { throw FlowImageError.failedForTest }
        if delayGet { try? await Task.sleep(nanoseconds: delay) }
        return img
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(img)
    }
}
