import XCTest
@testable import UberVoiceCore

final class UberDeepLinkBuilderTests: XCTestCase {

    // Destino de referencia (tomado del PDF técnico): un gimnasio en Lima.
    // Espacios → %20, coma → %2C, punto se conserva.
    private let gym = Destination(
        latitude: -12.0931,
        longitude: -77.0465,
        nickname: "Mi Gimnasio",
        formattedAddress: "Av. Ejemplo 123, Lima"
    )

    // MARK: - URL byte por byte

    func test_urlString_isByteExact_withoutClientID() {
        let builder = UberDeepLinkBuilder()

        let expected = "https://m.uber.com/ul/?"
            + "action=setPickup"
            + "&pickup=my_location"
            + "&dropoff[latitude]=-12.0931"
            + "&dropoff[longitude]=-77.0465"
            + "&dropoff[nickname]=Mi%20Gimnasio"
            + "&dropoff[formatted_address]=Av.%20Ejemplo%20123%2C%20Lima"

        XCTAssertEqual(builder.urlString(for: gym), expected)
    }

    func test_urlString_isByteExact_withClientID() {
        let builder = UberDeepLinkBuilder(clientID: "ABC123")

        let expected = "https://m.uber.com/ul/?"
            + "client_id=ABC123"
            + "&action=setPickup"
            + "&pickup=my_location"
            + "&dropoff[latitude]=-12.0931"
            + "&dropoff[longitude]=-77.0465"
            + "&dropoff[nickname]=Mi%20Gimnasio"
            + "&dropoff[formatted_address]=Av.%20Ejemplo%20123%2C%20Lima"

        XCTAssertEqual(builder.urlString(for: gym), expected)
    }

    func test_emptyClientID_isOmitted() {
        let builder = UberDeepLinkBuilder(clientID: "")
        XCTAssertFalse(builder.urlString(for: gym).contains("client_id"))
    }

    // MARK: - action / pickup fijos

    func test_action_isSetPickup() {
        let url = UberDeepLinkBuilder().urlString(for: gym)
        XCTAssertTrue(url.contains("action=setPickup"))
    }

    func test_pickup_isMyLocation() {
        let url = UberDeepLinkBuilder().urlString(for: gym)
        XCTAssertTrue(url.contains("pickup=my_location"))
    }

    // MARK: - Corchetes literales (NUNCA %5B / %5D)

    func test_dropoffKeys_useLiteralBrackets() {
        let url = UberDeepLinkBuilder().urlString(for: gym)
        XCTAssertTrue(url.contains("dropoff[latitude]="))
        XCTAssertTrue(url.contains("dropoff[longitude]="))
        XCTAssertTrue(url.contains("dropoff[nickname]="))
        XCTAssertTrue(url.contains("dropoff[formatted_address]="))

        XCTAssertFalse(url.contains("%5B"), "Los corchetes deben ser literales, no codificados")
        XCTAssertFalse(url.contains("%5D"), "Los corchetes deben ser literales, no codificados")
    }

    // MARK: - Coordenadas locale-safe (punto, jamás coma)

    func test_coordinates_useDecimalPoint() {
        let url = UberDeepLinkBuilder().urlString(for: gym)
        XCTAssertTrue(url.contains("dropoff[latitude]=-12.0931"))
        XCTAssertTrue(url.contains("dropoff[longitude]=-77.0465"))
    }

    func test_coordinateString_neverUsesComma_evenForRoundedValues() {
        // Un valor que un formateador es-PE renderizaría como "40,0".
        XCTAssertEqual(UberDeepLinkBuilder.coordinateString(40.0), "40.0")
        XCTAssertEqual(UberDeepLinkBuilder.coordinateString(-12.1191), "-12.1191")
        XCTAssertEqual(UberDeepLinkBuilder.coordinateString(0.0), "0.0")
    }

    func test_url_hasNoLiteralComma_fromCoordinates() {
        // La única coma del payload viene de la dirección y debe ir como %2C.
        // Por tanto no debe existir ninguna coma literal en toda la URL.
        let url = UberDeepLinkBuilder().urlString(for: gym)
        XCTAssertFalse(url.contains(","), "Ninguna coma literal: coords con punto y dirección con %2C")
        XCTAssertTrue(url.contains("%2C"))
    }

    // MARK: - Percent encoding unitario

    func test_percentEncoded_spacesAndCommas() {
        XCTAssertEqual(
            UberDeepLinkBuilder.percentEncoded("Mi Gimnasio"),
            "Mi%20Gimnasio"
        )
        XCTAssertEqual(
            UberDeepLinkBuilder.percentEncoded("Av. Ejemplo 123, Lima"),
            "Av.%20Ejemplo%20123%2C%20Lima"
        )
    }

    func test_percentEncoded_preservesUnreserved() {
        XCTAssertEqual(
            UberDeepLinkBuilder.percentEncoded("aZ09-._~"),
            "aZ09-._~"
        )
    }
}
