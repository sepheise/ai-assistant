//
//  SettingsViewModelTests.swift
//  AIAssistantTests
//
//  Created by Patricio Sepúlveda Heise on 03-07-23.
//

import XCTest
import AIAssistant
import Combine

@MainActor
class SettingsViewModelTests: XCTestCase {
    func test_onAppear_loadsAndSetOpenAIKeyOnSuccessfulLoad() async {
        let loaderSpy = APIKeyLoaderSpy(result: .success("testKey"))
        let sut = makeSUT(apiKeyLoaderSpy: loaderSpy)

        // when
        await sut.onAppear()

        XCTAssertEqual(loaderSpy.loadCallsCount, 1)
        XCTAssertEqual(sut.openAIApiKey, "testKey")
    }

    func test_onAppear_setsErrorMessageOnLoadFailure() async {
        let loaderSpy = APIKeyLoaderSpy(result: .failure(anyError()))
        let sut = makeSUT(apiKeyLoaderSpy: loaderSpy)

        await sut.onAppear()

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

    func test_save_doesNotSaveWhenOpenAIKeyValueIsEmpty() async {
        let saverSpy = APIKeySaverSpy()
        let sut = makeSUT(apiKeySaverSpy: saverSpy)

        await sut.saveAPIKey()

        XCTAssertEqual(saverSpy.saveCalls.count, 0)
    }

    func test_save_saveOpenAIKeyOnNonEmptyValue() async {
        let saverSpy = APIKeySaverSpy(result: .success(()))
        let sut = makeSUT(apiKeySaverSpy: saverSpy)
        sut.openAIApiKey = "testKey"

        await sut.saveAPIKey()

        XCTAssertEqual(saverSpy.saveCalls.count, 1)
        XCTAssertEqual(saverSpy.saveCalls, ["testKey"])
    }

    func test_save_setsErrorMessageOnSaveFailure() async {
        let saverSpy = APIKeySaverSpy(result: .failure(anyError()))
        let sut = makeSUT(apiKeySaverSpy: saverSpy)
        sut.openAIApiKey = "any key"

        await sut.saveAPIKey()

        XCTAssertEqual(saverSpy.saveCalls, ["any key"])
        XCTAssertEqual(sut.errorMessage, "Couldn't save API Key")
    }

    func test_delete_deletesOpenAIAPIKeyAndResetState() async {
        let deleterSpy = APIKeyDeleterSpy(result: .success(()))
        let sut = makeSUT(apiKeyDeleterSpy: deleterSpy)
        sut.openAIApiKey = "any key"

        await sut.deleteAPIKey()

        XCTAssertEqual(deleterSpy.deleteCallsCount, 1)
        XCTAssertTrue(sut.openAIApiKey.isEmpty)
    }

    func test_delete_setsErrorMessageOnDeleteFailure() async {
        let deleterSpy = APIKeyDeleterSpy(result: .failure(anyError()))
        let sut = makeSUT(apiKeyDeleterSpy: deleterSpy)
        sut.openAIApiKey = "any key"

        await sut.deleteAPIKey()

        XCTAssertEqual(deleterSpy.deleteCallsCount, 1)
        XCTAssertEqual(sut.errorMessage, "Couldn't delete API Key")
    }

    // MARK: - Helpers

    func makeSUT(
        apiKeyLoaderSpy loaderSpy: APIKeyLoaderSpy = APIKeyLoaderSpy(),
        apiKeySaverSpy saverSpy: APIKeySaverSpy = APIKeySaverSpy(),
        apiKeyDeleterSpy deleterSpy: APIKeyDeleterSpy = APIKeyDeleterSpy()
    ) -> SettingsViewModel {
        let sut = SettingsViewModel(apiKeyLoader: loaderSpy, apiKeySaver: saverSpy, apiKeyDeleter: deleterSpy)
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

class APIKeyDeleterSpy: APIKeyDeleter {
    var result: Result<Void, Error>
    var deleteCallsCount: Int = 0

    init(result: Result<Void, Error> = .success(())) {
        self.result = result
    }

    func delete() throws {
        deleteCallsCount += 1

        switch result {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}
