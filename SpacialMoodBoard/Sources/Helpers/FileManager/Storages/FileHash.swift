//
//  FileHash.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/21/25.
//

import Foundation
import CryptoKit

enum FileHash {
    static func sha256Hex(url: URL) throws -> String {
        try Self._streamingSHA256Hex(of: url)
    }

    private static func _streamingSHA256Hex(of url: URL) throws -> String {
        let bufferSize = 1 << 20 // 1MB
        guard let stream = InputStream(url: url) else {
            throw NSError(domain: "Hash", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "InputStream open failed"])
        }
        stream.open(); defer { stream.close() }

        var hasher = SHA256()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read > 0 {
                hasher.update(data: Data(bytesNoCopy: buffer, count: read, deallocator: .none))
            } else if read < 0 {
                throw stream.streamError ?? NSError(domain: "Hash", code: -2)
            } else { break }
        }
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
