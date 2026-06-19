import XCTest
@testable import UberVoiceCore

final class SiriSimulationTests: XCTestCase {

    func testVoiceScenarios() throws {

        let scenarios = try loadScenarios()

        let resolver = MockSiriResolver()
        let builder = UberDeepLinkBuilder()

        for scenario in scenarios {

            let destination = try XCTUnwrap(
                resolver.resolve(scenario.input),
                "Could not resolve: \(scenario.input)"
            )

            let url = builder.urlString(for: destination)

            XCTAssertTrue(
                url.contains(
                    "dropoff[nickname]=\(scenario.expectedNickname)"
                ),
                """
                Scenario failed

                Input:
                \(scenario.input)

                Expected:
                \(scenario.expectedNickname)

                URL:
                \(url)
                """
            )
        }
    }

    private func loadScenarios() throws -> [SiriScenario] {

        let url = try XCTUnwrap(
            Bundle.module.url(
                forResource: "utterances",
                withExtension: "json"   
            )
        )

        let data = try Data(contentsOf: url)

        return try JSONDecoder().decode(
            [SiriScenario].self,
            from: data
        )
    }
}