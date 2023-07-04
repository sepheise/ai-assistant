//
//  SettingsViewModelTests.swift
//  AIAssistantTests
//
//  Created by Patricio Sepúlveda Heise on 03-07-23.
//

import XCTest
import AIAssistant

class SettingsViewModel {
    @Published var openAIApiKey: String = ""
    private let apiKeyLoader: APIKeyLoader

    init(apiKeyLoader: APIKeyLoader) {
        self.apiKeyLoader = apiKeyLoader
    }

    func onAppear() {
        do {
            openAIApiKey = try apiKeyLoader.load()
        } catch {

        }
    }
}

class SettingsViewModelTests: XCTestCase {
    func test_onAppear_loadsAndSetOpenAIKey() {
        let apiKeyLoaderSpy = APIKeyLoaderSpy()
        let sut = SettingsViewModel(apiKeyLoader: apiKeyLoaderSpy)

        sut.onAppear()

        XCTAssertEqual(apiKeyLoaderSpy.loadCallsCount, 1)
        XCTAssertEqual(sut.openAIApiKey, "testKey")
    }
}

class APIKeyLoaderSpy: APIKeyLoader {
    var loadCallsCount: Int = 0

    func load() throws -> String {
        loadCallsCount += 1
        return "testKey"
    }
}
