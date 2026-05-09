import Foundation

enum InputMode: String, CaseIterable {
    case candidate
    case dictionary

    var title: String {
        switch self {
        case .candidate:
            return "Candidate"
        case .dictionary:
            return "Dictionary"
        }
    }
}
