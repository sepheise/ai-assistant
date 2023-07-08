//
//  SettingsViewModelTests.swift
//  AIAssistantTests
//
//  Created by Patricio Sepúlveda Heise on 03-07-23.
//

import XCTest
import AIAssistant

@MainActor
class SettingsViewModelTests: XCTestCase {
    func test_onAppear_loadsAndSetOpenAIKeyOnSuccessfulLoad() {
        let loaderSpy = APIKeyLoaderSpy(result: .success("testKey"))
        let sut = makeSUT(apiKeyLoaderSpy: loaderSpy)

        sut.onAppear()

        XCTAssertEqual(loaderSpy.loadCallsCount, 1)
        XCTAssertEqual(sut.openAIApiKey, "testKey")
    }

    func test_onAppear_setsErrorMessageOnLoadFailure() {
        let loaderSpy = APIKeyLoaderSpy(result: .failure(anyError()))
        let sut = makeSUT(apiKeyLoaderSpy: loaderSpy)

        sut.onAppear()

        XCTAssertEqual(loaderSpy.loadCallsCount, 1)
        XCTAssertEqual(sut.openAIApiKey, "")
        XCTAssertEqual(sut.errorMessage, "Couldn't load API Key")
    }

    func test_cantSave_whenOpenAIKeyValueIsEmpty() {
        let sut = makeSUT()

        sut.openAIApiKey = ""

        XCTAssertFalse(sut.canSave)

        sut.openAIApiKey = "any key"

        XCTAssertTrue(sut.canSave)
    }

    func test_save_doesNotSaveWhenOpenAIKeyValueIsEmpty() {
        let saverSpy = APIKeySaverSpy()
        let sut = makeSUT(apiKeySaverSpy: saverSpy)

        sut.saveAPIKey()

        XCTAssertEqual(saverSpy.saveCalls.count, 0)
    }

    func test_save_saveOpenAIKeyOnNonEmptyValue() {
        let saverSpy = APIKeySaverSpy(result: .success(()))
        let sut = makeSUT()

        sut.openAIApiKey = "testKey"
        sut.saveAPIKey()

        XCTAssertEqual(saverSpy.saveCalls.count, 1)
        XCTAssertEqual(saverSpy.saveCalls, ["testKey"])
    }

    func test_save_setsErrorMessageOnSaveFailure() {
        let saverSpy = APIKeySaverSpy(result: .failure(anyError()))
        let sut = makeSUT(apiKeySaverSpy: saverSpy)

        sut.openAIApiKey = "any key"
        sut.saveAPIKey()

        XCTAssertEqual(saverSpy.saveCalls, ["any key"])
        XCTAssertEqual(sut.errorMessage, "Couldn't save API Key")
    }

    // MARK: - Helpers

    func makeSUT(
        apiKeyLoaderSpy loaderSpy: APIKeyLoaderSpy = APIKeyLoaderSpy(),
        apiKeySaverSpy saverSpy: APIKeySaverSpy = APIKeySaverSpy()
    ) -> SettingsViewModel {
        let sut = SettingsViewModel(apiKeyLoader: loaderSpy, apiKeySaver: saverSpy)
        return sut
    }

    func anyError() -> Error {
        return NSError(domain: "any error", code: 0)
    }
}

class APIKeyLoaderSpy: APIKeyLoader {
    var result: Result<String, Error>
    var loadCallsCount: Int = 0

    init(result: Result<String, Error> = .success("any key")) {
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

    init(result: Result<Void, Error> = .success(())) {
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
