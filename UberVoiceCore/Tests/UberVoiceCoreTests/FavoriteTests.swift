import XCTest
@testable import UberVoiceCore

final class FavoriteTests: XCTestCase {

    private let gym = Favorite(
        nickname: "Mi Gimnasio",
        label: "Smart Fit Miraflores",
        latitude: -12.0931,
        longitude: -77.0465,
        formattedAddress: "Av. Ejemplo 123, Lima"
    )

    // MARK: - Codable (esquema snake_case documentado)

    func test_encoding_usesSnakeCaseFormattedAddress() throws {
        let data = try JSONEncoder().encode(gym)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("\"formatted_address\""))
        XCTAssertFalse(json.contains("formattedAddress"))
    }

    func test_codable_roundTrip() throws {
        let data = try JSONEncoder().encode(gym)
        let decoded = try JSONDecoder().decode(Favorite.self, from: data)
        XCTAssertEqual(decoded, gym)
    }

    // MARK: - Proyección a Destination + integración con el deep link

    func test_destination_mapsCoordinatesNicknameAndAddress() {
        let destination = gym.destination
        XCTAssertEqual(destination.latitude, -12.0931)
        XCTAssertEqual(destination.longitude, -77.0465)
        XCTAssertEqual(destination.nickname, "Mi Gimnasio")
        XCTAssertEqual(destination.formattedAddress, "Av. Ejemplo 123, Lima")
    }

    func test_favorite_feedsDeepLinkBuilder_byteExact() {
        let url = UberDeepLinkBuilder().urlString(for: gym.destination)

        let expected = "https://m.uber.com/ul/?"
            + "action=setPickup"
            + "&pickup=my_location"
            + "&dropoff[latitude]=-12.0931"
            + "&dropoff[longitude]=-77.0465"
            + "&dropoff[nickname]=Mi%20Gimnasio"
            + "&dropoff[formatted_address]=Av.%20Ejemplo%20123%2C%20Lima"

        XCTAssertEqual(url, expected)
    }
}
