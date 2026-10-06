// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import XCTest

@testable import webview_flutter_wkwebview

#if os(iOS)
  import Flutter
  import UIKit
#endif

class WebViewFlutterPluginTests: XCTestCase {
  #if os(iOS)
    func testInstanceManagerIsDeallocatedInApplicationWillTerminate() {
      let plugin = WebViewFlutterPlugin(binaryMessenger: TestBinaryMessenger())
      plugin.proxyApiRegistrar!.setUp()

      let view = UIView()
      _ = plugin.proxyApiRegistrar!.instanceManager.addHostCreatedInstance(view)

      // Attaches an associated object to the InstanceManager to listen for when it is deallocated.
      var finalizer: TestFinalizer? = TestFinalizer()

      let key = malloc(1)!
      defer {
        free(key)
      }
      objc_setAssociatedObject(
        plugin.proxyApiRegistrar!.instanceManager, key, finalizer, .OBJC_ASSOCIATION_RETAIN)
      let expectation = self.expectation(description: "Wait for InstanceManager to be deallocated.")
      TestFinalizer.onDeinit = {
        expectation.fulfill()
      }

      // Ensure method is from `FlutterApplicationLifeCycleDelegate`.
      (plugin as FlutterApplicationLifeCycleDelegate).applicationWillTerminate!(
        UIApplication.shared)
      XCTAssertNil(plugin.proxyApiRegistrar)

      finalizer = nil
      waitForExpectations(timeout: 5.0)
    }

    func testInstanceManagerIsDeallocatedInSceneDidDisconnect() {
      let plugin = WebViewFlutterPlugin(binaryMessenger: TestBinaryMessenger())
      plugin.proxyApiRegistrar!.setUp()

      let view = UIView()
      _ = plugin.proxyApiRegistrar!.instanceManager.addHostCreatedInstance(view)

      // Attaches an associated object to the InstanceManager to listen for when it is deallocated.
      var finalizer: TestFinalizer? = TestFinalizer()

      let key = malloc(1)!
      defer {
        free(key)
      }
      objc_setAssociatedObject(
        plugin.proxyApiRegistrar!.instanceManager, key, finalizer, .OBJC_ASSOCIATION_RETAIN)
      let expectation = self.expectation(description: "Wait for InstanceManager to be deallocated.")
      TestFinalizer.onDeinit = {
        expectation.fulfill()
      }

      let scene = UIApplication.shared.connectedScenes.first!

      // Ensure method is from `FlutterSceneLifeCycleDelegate`.
      (plugin as FlutterSceneLifeCycleDelegate).sceneDidDisconnect?(scene)
      XCTAssertNil(plugin.proxyApiRegistrar)

      finalizer = nil
      waitForExpectations(timeout: 5.0)
    }

    func testCodecRetainsRegistrarUntilEncodingCompletesAfterTeardown() {
      let plugin = WebViewFlutterPlugin(binaryMessenger: TestBinaryMessenger())
      let registrarReference = WeakTestReference(plugin.proxyApiRegistrar)
      var codec: FlutterStandardMessageCodec? = plugin.proxyApiRegistrar!.codec

      (plugin as FlutterApplicationLifeCycleDelegate).applicationWillTerminate!(
        UIApplication.shared)

      XCTAssertNil(plugin.proxyApiRegistrar)
      XCTAssertNotNil(registrarReference.value)

      let encodedValue = codec!.encode(UIView())
      XCTAssertNil(codec!.decode(encodedValue))

      codec = nil
      XCTAssertNil(registrarReference.value)
    }

    func testCallbackRegistrarCycleIsReleasedOnTeardown() {
      let plugin = WebViewFlutterPlugin(binaryMessenger: TestBinaryMessenger())
      let registrarReference = WeakTestReference(plugin.proxyApiRegistrar)
      autoreleasepool {
        let handler = ScriptMessageHandlerImpl(
          api: plugin.proxyApiRegistrar!.apiDelegate.pigeonApiWKScriptMessageHandler(
            plugin.proxyApiRegistrar!),
          registrar: plugin.proxyApiRegistrar!)
        _ = plugin.proxyApiRegistrar!.instanceManager.addHostCreatedInstance(handler)
        XCTAssertNotNil(registrarReference.value)

        (plugin as FlutterApplicationLifeCycleDelegate).applicationWillTerminate!(
          UIApplication.shared)
      }

      XCTAssertNil(plugin.proxyApiRegistrar)
      XCTAssertNil(registrarReference.value)
    }
  #endif
}

class TestFinalizer {
  static var onDeinit: (() -> Void)?

  deinit {
    Self.onDeinit?()
  }
}

final class WeakTestReference<Value: AnyObject> {
  weak var value: Value?

  init(_ value: Value?) {
    self.value = value
  }
}
