//
//  SettingsViewModelTests.swift
//  AIAssistantTests
//
//  Created by Patricio Sepúlveda Heise on 03-07-23.
//

import XCTest
import AIAssistant

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

        XCTAssertEqual(saverSpy.saveCalls.count, 0)
    }

    func test_save_saveOpenAIKeyOnNonEmptyValue() {
        let (sut, _, saverSpy) = makeSUT()

        sut.openAIApiKey = "any key"
        sut.saveAPIKey()

        XCTAssertEqual(saverSpy.saveCalls.count, 1)
        XCTAssertEqual(saverSpy.saveCalls, ["any key"])
    }

    func test_save_setsErrorMessageOnSaveFailure() {
        let (sut, _, saverSpy) = makeSUT(saverResult: .failure(anyError()))

        sut.openAIApiKey = "any key"
        sut.saveAPIKey()

        XCTAssertEqual(saverSpy.saveCalls, ["any key"])
        XCTAssertEqual(sut.errorMessage, "Couldn't save API Key")
    }

    // MARK: - Helpers

    func makeSUT(loaderResult: Result<String, Error> = .success("testKey"), saverResult: Result<Void, Error> = .success(())) -> (sut: SettingsViewModel, loaderSpy: APIKeyLoaderSpy, saverSpy: APIKeySaverSpy) {
        
        let apiKeyLoaderSpy = APIKeyLoaderSpy(result: loaderResult)
        let apiKeySaverSpy = APIKeySaverSpy(result: saverResult)
        let sut = SettingsViewModel(apiKeyLoader: apiKeyLoaderSpy, apiKeySaver: apiKeySaverSpy)

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
    var saveCalls: [String] = []

    init(result: Result<Void, Error>) {
        self.result = result
    }

    func save(_ value: String) throws {
        saveCalls.append(value)

        switch result {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}
