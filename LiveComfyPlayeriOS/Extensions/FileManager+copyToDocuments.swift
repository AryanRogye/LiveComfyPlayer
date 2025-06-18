//
//  FileManager+copyToDocuments.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/17/25.
//

import Foundation

extension FileManager {
    func copyToDocuments(_ originalURL: URL) throws -> URL {
        let fileName = originalURL.lastPathComponent
        let destURL = urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        if !fileExists(atPath: destURL.path) {
            try copyItem(at: originalURL, to: destURL)
        }
        return destURL
    }
}
