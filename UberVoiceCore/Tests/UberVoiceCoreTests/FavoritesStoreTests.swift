import XCTest
@testable import UberVoiceCore

final class FavoritesStoreTests: XCTestCase {

    private func makeStore() -> (DefaultFavoritesStore, InMemorySecureStore) {
        let backend = InMemorySecureStore()
        return (DefaultFavoritesStore(secureStore: backend), backend)
    }

    private let gym = Favorite(
        nickname: "gimnasio",
        label: "Smart Fit Miraflores",
        latitude: -12.1191,
        longitude: -77.0291,
        formattedAddress: "Av. Larco 345, Miraflores, Lima"
    )

    private let school = Favorite(
        nickname: "escuela",
        label: "Mi Universidad",
        latitude: -12.0464,
        longitude: -77.0428,
        formattedAddress: "Av. Universitaria 1801, Lima"
    )

    // MARK: - Estado inicial

    func test_all_isEmpty_whenNothingSaved() throws {
        let (store, _) = makeStore()
        XCTAssertEqual(try store.all(), [])
    }

    // MARK: - save / all

    func test_save_thenAll_returnsFavorite() throws {
        let (store, _) = makeStore()
        try store.save(gym)
        XCTAssertEqual(try store.all(), [gym])
    }

    func test_save_twoDistinct_keepsBoth() throws {
        let (store, _) = makeStore()
        try store.save(gym)
        try store.save(school)
        XCTAssertEqual(try store.all().count, 2)
        XCTAssertEqual(Set(try store.all()), [gym, school])
    }

    func test_save_sameNickname_updatesInPlace_noDuplicate() throws {
        let (store, _) = makeStore()
        try store.save(gym)

        let movedGym = Favorite(
            nickname: "gimnasio",                 // mismo apodo
            label: "Smart Fit San Isidro",        // datos nuevos
            latitude: -12.0970,
            longitude: -77.0270,
            formattedAddress: "Av. Camino Real 100, San Isidro, Lima"
        )
        try store.save(movedGym)

        XCTAssertEqual(try store.all(), [movedGym])
    }

    // MARK: - delete

    func test_delete_removesMatchingNickname() throws {
        let (store, _) = makeStore()
        try store.save(gym)
        try store.save(school)

        try store.delete(nickname: "gimnasio")

        XCTAssertEqual(try store.all(), [school])
    }

    func test_delete_missingNickname_isNoOp() throws {
        let (store, _) = makeStore()
        try store.save(gym)

        XCTAssertNoThrow(try store.delete(nickname: "noexiste"))
        XCTAssertEqual(try store.all(), [gym])
    }

    // MARK: - Persistencia real a través del SecureStore

    func test_data_persistsThroughSecureStore_notInMemoryInLogic() throws {
        let backend = InMemorySecureStore()
        let store1 = DefaultFavoritesStore(secureStore: backend)
        try store1.save(gym)

        // Un store nuevo sobre el MISMO backend ve los datos: la lógica no
        // guarda estado propio, todo pasa por el SecureStore.
        let store2 = DefaultFavoritesStore(secureStore: backend)
        XCTAssertEqual(try store2.all(), [gym])
    }

    func test_save_roundTripsAllFieldsExactly() throws {
        let (store, _) = makeStore()
        try store.save(gym)

        let restored = try XCTUnwrap(try store.all().first)
        XCTAssertEqual(restored.nickname, "gimnasio")
        XCTAssertEqual(restored.label, "Smart Fit Miraflores")
        XCTAssertEqual(restored.latitude, -12.1191)
        XCTAssertEqual(restored.longitude, -77.0291)
        XCTAssertEqual(restored.formattedAddress, "Av. Larco 345, Miraflores, Lima")
    }
}
