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
    var canSave: Bool {
        !openAIApiKey.isEmpty
    }
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
        let (sut, loaderSpy) = makeSUT(loaderResult: .success("testKey"))

        sut.onAppear()

        XCTAssertEqual(loaderSpy.loadCallsCount, 1)
        XCTAssertEqual(sut.openAIApiKey, "testKey")
    }

    func test_onAppear_setsErrorMessageOnLoadFailure() {
        let (sut, loaderSpy) = makeSUT(loaderResult: .failure(anyError()))

        sut.onAppear()

        XCTAssertEqual(loaderSpy.loadCallsCount, 1)
        XCTAssertEqual(sut.openAIApiKey, "")
        XCTAssertEqual(sut.errorMessage, "Couldn't load API Key")
    }

    func test_cantSave_whenOpenAIKeyValueIsEmpty() {
        let (sut, _) = makeSUT()

        sut.openAIApiKey = ""

        XCTAssertFalse(sut.canSave)

        sut.openAIApiKey = "any key"

        XCTAssertTrue(sut.canSave)
    }

    // MARK: - Helpers

    func makeSUT(loaderResult: Result<String, Error> = .success("testKey")) -> (sut: SettingsViewModel, loaderSpy: APIKeyLoaderSpy) {
        
        let apiKeyLoaderSpy = APIKeyLoaderSpy(result: loaderResult)
        let sut = SettingsViewModel(apiKeyLoader: apiKeyLoaderSpy)

        return (sut, apiKeyLoaderSpy)
    }

    func anyError() -> Error {
        return NSError(domain: "any error", code: 0)
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
