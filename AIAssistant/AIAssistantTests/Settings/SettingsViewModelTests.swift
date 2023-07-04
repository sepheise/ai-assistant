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

    func saveAPIKey() {

    }
}

class SettingsViewModelTests: XCTestCase {
    func test_onAppear_loadsAndSetOpenAIKeyOnSuccessfulLoad() {
        let (sut, loaderSpy, _) = makeSUT(loaderResult: .success("testKey"))

        sut.onAppear()

        XCTAssertEqual(loaderSpy.loadCallsCount, 1)
        XCTAssertEqual(sut.openAIApiKey, "testKey")
    }

    func test_onAppear_setsErrorMessageOnLoadFailure() {
        let (sut, loaderSpy, _) = makeSUT(loaderResult: .failure(anyError()))

        sut.onAppear()

        XCTAssertEqual(loaderSpy.loadCallsCount, 1)
        XCTAssertEqual(sut.openAIApiKey, "")
        XCTAssertEqual(sut.errorMessage, "Couldn't load API Key")
    }

    func test_cantSave_whenOpenAIKeyValueIsEmpty() {
        let (sut, _, _) = makeSUT()

        sut.openAIApiKey = ""

        XCTAssertFalse(sut.canSave)

        sut.openAIApiKey = "any key"

        XCTAssertTrue(sut.canSave)
    }

    func test_save_doesNotSaveWhenOpenAIKeyValueIsEmpty() {
        let (sut, _, saverSpy) = makeSUT()

        sut.saveAPIKey()

        XCTAssertEqual(saverSpy.saveCallsCount, 0)
    }

    // MARK: - Helpers

    func makeSUT(loaderResult: Result<String, Error> = .success("testKey"), saverResult: Result<Void, Error> = .success(())) -> (sut: SettingsViewModel, loaderSpy: APIKeyLoaderSpy, saverSpy: APIKeySaverSpy) {
        
        let apiKeyLoaderSpy = APIKeyLoaderSpy(result: loaderResult)
        let apiKeySaverSpy = APIKeySaverSpy(result: saverResult)
        let sut = SettingsViewModel(apiKeyLoader: apiKeyLoaderSpy)

        return (sut, apiKeyLoaderSpy, apiKeySaverSpy)
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

class APIKeySaverSpy: APIKeySaver {
    var result: Result<Void, Error>
    var saveCallsCount: Int = 0

    init(result: Result<Void, Error>) {
        self.result = result
    }

    func save(_ value: String) throws {
        saveCallsCount += 1
    }
}
