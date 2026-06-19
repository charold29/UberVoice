import Foundation
@testable import UberVoiceCore

final class MockSiriResolver: SiriResolving {

    func resolve(_ phrase: String) -> Destination? {

        switch phrase.lowercased() {

        case "llévame a casa",
             "a casa",
             "de siempre":

            return Destination(
                latitude: -12.0931,
                longitude: -77.0465,
                nickname: "Home",
                formattedAddress: "San Isidro"
            )

        case "ir al gym",
             "al gimnasio",
             "llévame al gimnasio":

            return Destination(
                latitude: -12.1010,
                longitude: -77.0300,
                nickname: "Gym",
                formattedAddress: "Bodytech"
            )

        case "al aeropuerto",
             "llévame al aeropuerto":

            return Destination(
                latitude: -12.0219,
                longitude: -77.1143,
                nickname: "Airport",
                formattedAddress: "Jorge Chavez Airport"
            )

        default:
            return nil
        }
    }
}