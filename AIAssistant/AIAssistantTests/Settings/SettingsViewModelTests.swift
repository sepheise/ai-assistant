//
//  SettingsViewModelTests.swift
//  AIAssistantTests
//
//  Created by Patricio Sepúlveda Heise on 03-07-23.
//

import XCTest
import AIAssistant

class SettingsViewModel {
    var openAIApiKey: String = ""
    var errorMessage: String = ""
    private let apiKeyLoader: APIKeyLoader

    init(apiKeyLoader: APIKeyLoader) {
        self.apiKeyLoader = apiKeyLoader
    }

    func onAppear() {
        do {
            openAIApiKey = try apiKeyLoader.load()
        } catch {
            errorMessage = "Couldn't load API Key"
        }
    }
}

class SettingsViewModelTests: XCTestCase {
    func test_onAppear_loadsAndSetOpenAIKeyOnSuccessfulLoad() {
        let apiKeyLoaderSpy = APIKeyLoaderSpy(result: .success("testKey"))
        let sut = SettingsViewModel(apiKeyLoader: apiKeyLoaderSpy)

        sut.onAppear()

        XCTAssertEqual(apiKeyLoaderSpy.loadCallsCount, 1)
        XCTAssertEqual(sut.openAIApiKey, "testKey")
    }

    func test_onAppear_setsErrorMessageOnLoadFailure() {
        let apiKeyLoaderSpy = APIKeyLoaderSpy(result: .failure(NSError(domain: "any error", code: 0)))
        let sut = SettingsViewModel(apiKeyLoader: apiKeyLoaderSpy)

        sut.onAppear()

        XCTAssertEqual(apiKeyLoaderSpy.loadCallsCount, 1)
        XCTAssertEqual(sut.openAIApiKey, "")
        XCTAssertEqual(sut.errorMessage, "Couldn't load API Key")
    }
}

class APIKeyLoaderSpy: APIKeyLoader {
    var result: Result<String, Error>
    var loadCallsCount: Int = 0

    init(result: Result<String, Error>) {
        self.result = result
    }

    func load() throws -> String {
        loadCallsCount += 1
        return try result.get()
    }
}
