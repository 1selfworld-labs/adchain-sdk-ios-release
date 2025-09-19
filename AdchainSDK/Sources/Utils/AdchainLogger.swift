//
//  AdchainLogger.swift
//  AdchainSdk
//
//  Created by AdchainSdk on 2025/01/18.
//

import Foundation

/// Log level enum defining the verbosity of logs
@objc public enum LogLevel: Int, Comparable {
    case none = 0
    case error = 1
    case warning = 2
    case info = 3
    case debug = 4
    case verbose = 5

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// Centralized logger for AdchainSdk
public class AdchainLogger: NSObject {

    /// Current log level - default to WARNING for production safety
    public static var logLevel: LogLevel = .warning

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    /// Log error message
    public static func e(_ tag: String, _ message: String, _ error: Error? = nil) {
        if logLevel >= .error {
            let errorInfo = error != nil ? " - \(error!.localizedDescription)" : ""
            log(level: "E", tag: tag, message: "\(message)\(errorInfo)")
        }
    }

    /// Log warning message
    public static func w(_ tag: String, _ message: String, _ error: Error? = nil) {
        if logLevel >= .warning {
            let errorInfo = error != nil ? " - \(error!.localizedDescription)" : ""
            log(level: "W", tag: tag, message: "\(message)\(errorInfo)")
        }
    }

    /// Log info message
    public static func i(_ tag: String, _ message: String) {
        if logLevel >= .info {
            log(level: "I", tag: tag, message: message)
        }
    }

    /// Log debug message
    public static func d(_ tag: String, _ message: String) {
        if logLevel >= .debug {
            log(level: "D", tag: tag, message: message)
        }
    }

    /// Log verbose message
    public static func v(_ tag: String, _ message: String) {
        if logLevel >= .verbose {
            log(level: "V", tag: tag, message: message)
        }
    }

    private static func log(level: String, tag: String, message: String) {
        let timestamp = dateFormatter.string(from: Date())
        print("[\(timestamp)] [\(level)/\(tag)] \(message)")
    }
}