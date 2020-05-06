
import Foundation

precedencegroup infix1 {
    associativity: left
}

infix operator <>
infix operator <*>: infix1

protocol Semigroup {
    static func <>(_ left: Self, right: Self) -> Self
}

extension String: Semigroup {
    static func <> (left: String, right: String) -> String {
        left + " " + right
    }
}

enum Validation<A, E> {
    
    case valid(A)
    case invalid(E)
    
    func map<B>(_ f: (A) -> B) -> Validation<B, E> {
        switch self {
        case let .valid(a):
            return .valid(f(a))
            
        case let .invalid(e):
            return .invalid(e)
        }
    }
    
    func mapError<F>(_ f: (E) -> F) -> Validation<A, F> {
        switch self {
        case let .valid(a):
            return .valid(a)
            
        case let .invalid(e):
            return .invalid(f(e))
        }
    }
        
    func flatMap<B>(_ f: (A) -> Validation<B, E>) -> Validation<B, E> {
        switch self {
        case let .valid(a):
            return f(a)
            
        case let .invalid(e):
            return .invalid(e)
        }
    }
    
    static func pure<A>(_ x: A) -> Validation<A, E> {
        .valid(x)
    }
}

extension Validation where E: Semigroup {
    
    func apply<B>(_ f: Validation<(A) -> B, E>) -> Validation<B, E> {
        switch (f, self) {
        case let (.valid(f), _):
          return self.map(f)
        
        case let (.invalid(e), .valid):
          return .invalid(e)
        
        case let (.invalid(e1), .invalid(e2)):
          return .invalid(e1 <> e2)
        }
    }
    
    static func <*> <B>(a2b: Validation<(A) -> B, E>, a: Validation) -> Validation<B, E> {
      return a.apply(a2b)
    }
}

func zip<A, B, E: Semigroup>(_ validate1: Validation<A, E>, _ validate2: Validation<B, E>) -> Validation<(A, B), E> {
    .pure(curry(f2)) <*> validate1 <*> validate2
}

func zip<A, B, C, E: Semigroup>(with f:@escaping (A, B) -> C) -> (_ validate1: Validation<A, E>, _ validate2: Validation<B, E>) -> Validation<C, E> {
    { .pure(curry(f)) <*> $0 <*> $1 }
}

func f2<A, B>(_ a: A, _ b: B) -> (A, B) {
    (a, b)
}

func curry<A, B, C>(_ f:@escaping (A, B) -> C) -> (A) -> (B) -> C {
    { a in { b in f(a,b) }}
}

extension Validation {
    
    func getOrElse(_ x: @autoclosure () -> A) -> A {
        switch self {
        case let .valid(a):
            return a
            
        case .invalid:
            return x()
        }
    }
    
    static func condition(
        _ predicate: () -> Bool,
        valid:@autoclosure () -> A,
        invalid:@autoclosure () -> E) -> Validation {
        guard predicate() else {
            return .invalid(invalid())
        }
        return .valid(valid())
    }
}

struct ValidationError {
    let error: [Int: String]
}

extension ValidationError: Semigroup {
    static func <> (left: ValidationError, right: ValidationError) -> ValidationError {
        .init(error: left.error.merging(right.error) { cur, _ in cur })
    }
}
