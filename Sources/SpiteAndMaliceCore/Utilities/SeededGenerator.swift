import Foundation

public struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed == 0 ? 0x4d595df4d0f33173 : seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var result = state
        result = (result ^ (result >> 30)) &* 0xbf58476d1ce4e5b9
        result = (result ^ (result >> 27)) &* 0x94d049bb133111eb
        return result ^ (result >> 31)
    }
}
