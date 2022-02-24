//
//  DelayedFlowImage.swift
//  
//
//  Created by Xuezheng Wang on 2/22/22.
//

import UIKit

public class DelayedFlowImage: DownloadedFlowImage {
    private let delay: UInt64 = 1_000_000_000

    override public func prepareForDisplay() async throws -> FlowImage {
        try await Task.sleep(nanoseconds: delay)
        return try await super.prepareForDisplay()
    }

    override public func getUIImage() async throws -> UIImage {
        try await Task.sleep(nanoseconds: delay)
        return try await super.getUIImage()
    }
}

