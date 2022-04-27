/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

extension Result: CustomStringConvertible {
    public var description: String {
        switch self {
        case .success(let value):
            return "Result(\(value))"
        case .failure(let error):
            return "Result(\(error))"
        }
    }
}

/// A type erased error enum.
public struct AnyError: Swift.Error, CustomStringConvertible {
    /// The underlying error.
    public let underlyingError: Swift.Error

    public init(_ error: Swift.Error) {
        // If we already have any error, don't nest it.
        if case let error as AnyError = error {
            self = error
        } else {
            self.underlyingError = error
        }
    }

    public var description: String {
        return String(describing: underlyingError)
    }
}

/// Represents a string error.
public struct StringError: Equatable, Codable, CustomStringConvertible, Error {

    /// The description of the error.
    public let description: String

    /// Create an instance of StringError.
    public init(_ description: String) {
        self.description = description
    }
}

// AnyError specific helpers.
extension Result where Failure == AnyError {
    /// Initialise with something that throws AnyError.
    public init(anyError body: () throws -> Success) {
        do {
            self = .success(try body())
        } catch {
            self = .failure(AnyError(error))
        }
    }

    /// Initialise with an error, it will be automatically converted to AnyError.
    public init(_ error: Swift.Error) {
        self = .failure(AnyError(error))
    }

    /// Evaluates the given throwing closure when this Result instance has a value.
    ///
    /// The final result will either be the transformed value or any error thrown by the closure.
    public func mapAny<U>(_ transform: (Success) throws -> U) -> Result<U, AnyError> {
        switch self {
        case .success(let value):
            do {
                let transformed = try transform(value)
                return Result<U, AnyError>.success(transformed)
            } catch {
                return Result<U, AnyError>(error)
            }
        case .failure(let error):
            return Result<U, AnyError>(error)
        }
    }
}

extension Result where Failure == StringError {
    /// Create an instance of Result<Success, StringError>.
    ///
    /// Errors will be encoded as StringError using their description.
    public init(string body: () throws -> Success) {
        do {
            self = .success(try body())
        } catch let error as StringError {
            self = .failure(error)
        } catch {
            self = .failure(StringError(String(describing: error)))
        }
    }
}

extension Result: Codable where Success: Codable, Failure: Codable {
    private enum CodingKeys: String, CodingKey {
        case success, failure
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .success(let value):
            var unkeyedContainer = container.nestedUnkeyedContainer(forKey: .success)
            try unkeyedContainer.encode(value)
        case .failure(let error):
            var unkeyedContainer = container.nestedUnkeyedContainer(forKey: .failure)
            try unkeyedContainer.encode(error)
        }
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        guard let key = values.allKeys.first(where: values.contains) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Did not find a matching key"))
        }
        switch key {
        case .success:
            var unkeyedValues = try values.nestedUnkeyedContainer(forKey: key)
            let value = try unkeyedValues.decode(Success.self)
            self = .success(value)
        case .failure:
            var unkeyedValues = try values.nestedUnkeyedContainer(forKey: key)
            let error = try unkeyedValues.decode(Failure.self)
            self = .failure(error)
        }
    }
}
