// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import WebKit
import XCTest

@testable import webview_flutter_wkwebview

class ScriptMessageHandlerProxyAPITests: XCTestCase {
  func testPigeonDefaultConstructor() {
    let registrar = TestProxyApiRegistrar()
    let api = registrar.apiDelegate.pigeonApiWKScriptMessageHandler(registrar)

    let instance = try? api.pigeonDelegate.pigeonDefaultConstructor(pigeonApi: api)
    XCTAssertNotNil(instance)
  }

  @MainActor func testDidReceiveScriptMessage() {
    let api = TestScriptMessageHandlerApi()
    let registrar = TestProxyApiRegistrar()
    let instance = ScriptMessageHandlerImpl(api: api, registrar: registrar)
    let controller = WKUserContentController()
    let message = WKScriptMessage()

    instance.userContentController(controller, didReceive: message)

    XCTAssertEqual(api.didReceiveScriptMessageArgs, [controller, message])
  }

  @MainActor func testHandlesMessageAfterRegistrarOwnerIsReleased() {
    let api = TestScriptMessageHandlerApi()
    var registrar: TestProxyApiRegistrar? = TestProxyApiRegistrar()
    var instance: ScriptMessageHandlerImpl? = ScriptMessageHandlerImpl(
      api: api, registrar: registrar!)
    let registrarReference = WeakTestReference(registrar)
    let controller = WKUserContentController()
    let message = WKScriptMessage()

    registrar = nil
    XCTAssertNotNil(registrarReference.value)

    instance!.userContentController(controller, didReceive: message)
    XCTAssertEqual(api.didReceiveScriptMessageArgs, [controller, message])

    instance = nil
    XCTAssertNil(registrarReference.value)
  }
}

class TestScriptMessageHandlerApi: PigeonApiProtocolWKScriptMessageHandler {
  var didReceiveScriptMessageArgs: [AnyHashable?]? = nil

  func didReceiveScriptMessage(
    pigeonInstance pigeonInstanceArg: WKScriptMessageHandler,
    controller controllerArg: WKUserContentController, message messageArg: WKScriptMessage,
    completion: @escaping (Result<Void, PigeonError>) -> Void
  ) {
    didReceiveScriptMessageArgs = [controllerArg, messageArg]
  }
}
