import Foundation
import CoreGraphics

extension Data {
    var string: String {
        return String(data: self, encoding: String.Encoding.utf8) ?? ""
    }
}
