import Foundation
@testable import UberVoiceCore

protocol SiriResolving {
    func resolve(_ phrase: String) -> Destination?
}