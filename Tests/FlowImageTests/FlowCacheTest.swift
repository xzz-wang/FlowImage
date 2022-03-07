//
//  FlowCacheTest.swift
//  
//
//  Created by Xuezheng Wang on 2/22/22.
//

import XCTest
import FlowImage

@MainActor
class FlowCacheTest: XCTestCase {

    private var cache = FlowCache()

    private let img1 = UIImage(systemName: "person")!
    private let img2 = UIImage(systemName: "person.2")!
    private let img3 = UIImage(systemName: "person.3")!

    /// Test we can call reset with noting in it.
    func testClearEmpty() throws {
        cache.clear()
    }

    /// Test that we can call reset with one image.
    func testClearOnePic() async throws {
        cache.clear()
        let flow1 = TestFlowImage(img1, id: "test_one_pic")
        let flow1Fail = TestFlowImage(img1, id: "test_one_pic", failGet: true)

        _ = try await flow1.getUIImageFromCache(cache) // Add flow1 to cache
        cache.clear() // Clear flow1 out of cache

        do {
            _ = try await flow1Fail.getUIImageFromCache(cache)
            XCTFail("We should throw error")
        } catch {
            XCTAssert(error as! FlowImageError == .failedForTest)
        }
    }

    /// Make sure we can get the cached image with the same id.
    func testGet() async throws {
        cache.clear()
        let flow1 = TestFlowImage(img1, id: "test_get")
        let flow2 = TestFlowImage(img2, id: "test_get")

        _ = try await flow1.getUIImageFromCache(cache)
        let resultImg = try await flow2.getUIImageFromCache(cache)

        // Should have gotten img1 from cache instead of img2.
        XCTAssert(resultImg == img1, "Not getting the image from cache!")
    }

    /// Make sure we can get the cached image with the same id.
    func testGet2() async throws {
        cache.clear()
        let flow1 = TestFlowImage(img1, id: "test_get")
        let flow2 = TestFlowImage(img2, id: "test_get")
        let flow3 = TestFlowImage(img1, id: "test_get_notThisOne")

        _ = try await flow1.getUIImageFromCache(cache)
        _ = try await flow3.getUIImageFromCache(cache)
        let resultImg = try await cache.get(flow2)

        // Should have gotten img1 from cache instead of img2.
        XCTAssert(resultImg == img1, "Not getting the image from cache!")
    }

    /// forceRecache is doing what it's suppose to be.
    func testRecache() async throws {
        cache.clear()
        let flow1 = TestFlowImage(img1, id: "test_recache")
        let flow2 = TestFlowImage(img2, id: "test_recache")

        _ = try await flow1.getUIImageFromCache(cache)
        let resultImg = try await flow2.getUIImageFromCache(cache, forceRecache: true)

        XCTAssert(resultImg == img2, "Not force recaching!")
    }

    func testFailedPrepare() async {
        cache.clear()
        let flow1 = TestFlowImage(img1, failPrepare: true)
        do {
            _ = try await flow1.getUIImageFromCache(cache)
            XCTFail()
        } catch {
            XCTAssert(error as! FlowImageError == .failedForTest)
        }
    }

    func testFailedGet() async {
        cache.clear()
        let flow1 = TestFlowImage(img1, failGet: true)
        do {
            _ = try await flow1.getUIImageFromCache(cache)
            XCTFail()
        } catch {
            XCTAssert(error as! FlowImageError == .failedForTest)
        }
    }

    func testFailedPrepareAndRetryOnNextGet() async throws {
        cache.clear()

        let flow1 = TestFlowImage(img1, id: "pic", failPrepare: true)
        let flow1Success = TestFlowImage(img1, id: "pic")

        // First, faile the request once.
        do {
            _ = try await flow1.getUIImageFromCache(cache)
            XCTFail()
        } catch {
            XCTAssert(error as! FlowImageError == .failedForTest)
        }

        // Second request
        do {
            _ = try await flow1Success.getUIImageFromCache(cache)
        } catch {
            XCTFail("The second try shouldn't throw error")
        }
    }

    // MARK: - Combine subscriber tests
    func testObserveChange() async throws {
        cache.clear()
        let flow1 = TestFlowImage(img1, id: "pic")
        let exp = expectation(description: "We should be notified when the value chagnes.")

        // Get the publisher
        let (_, publisher) = try await cache.getAndSubscribeTo(flow1)
        let canceler = publisher
            .sink {
                exp.fulfill()
            }

        _ = try await flow1.getUIImageFromCache(cache, forceRecache: true)
        wait(for: [exp], timeout: 0.5)
        canceler.cancel()
    }

    func testObserveCompletion() async throws {
        cache.clear()
        let flow1 = TestFlowImage(img1, id: "pic")
        let exp = expectation(description: "We should be notified when the subscriber is deleted.")

        // Get the publisher
        let (_, publisher) = try await cache.getAndSubscribeTo(flow1)
        let canceler = publisher
            .sink { _ in
                exp.fulfill()
            } receiveValue: {}

        cache.clear()
        wait(for: [exp], timeout: 0.5)
        canceler.cancel()
    }

    func testMultipleSubscriber() async throws {
        cache.clear()
        let flow1 = TestFlowImage(img1, id: "pic")
        let exp1 = expectation(description: "First subscriber should be notified")
        let exp2 = expectation(description: "Second subscriber should be notified")

        // Get the first publisher
        let (_, publisher1) = try await cache.getAndSubscribeTo(flow1)
        let canceler = publisher1
            .sink { _ in
                exp1.fulfill()
            } receiveValue: {}

        // Get the second publisher
        let (_, publisher2) = try await cache.getAndSubscribeTo(flow1)
        let canceler2 = publisher2
            .sink { _ in
                exp2.fulfill()
            } receiveValue: {}

        cache.clear()
        wait(for: [exp1, exp2], timeout: 0.5)
        canceler.cancel()
        canceler2.cancel()
    }


    func testMemoryConstraint() async throws {
        cache.clear()
        let flow1 = TestFlowImage(img1, id: "pic")
        let exp = expectation(description: "We should be notified when we have memory constraint..")

        // Get the publisher
        let (_, publisher) = try await cache.getAndSubscribeTo(flow1)
        let canceler = publisher
            .sink { _ in
                exp.fulfill()
            } receiveValue: {}

        let notification = Notification(name: UIApplication.didReceiveMemoryWarningNotification)
        NotificationCenter.default.post(notification)
        wait(for: [exp], timeout: 0.5)
        canceler.cancel()
    }

}
