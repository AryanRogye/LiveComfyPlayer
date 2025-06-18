//
//  SceneState.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/18/25.
//

import SwiftUI

@propertyWrapper
struct SceneState<Value: Codable>: DynamicProperty {
    @SceneStorage private var raw: Data
    private var defaultValue: Value
    
    init(wrappedValue: Value, _ key: String) {
        self._raw = SceneStorage(wrappedValue: try! JSONEncoder().encode(wrappedValue), key)
        self.defaultValue = wrappedValue
    }
    
    var wrappedValue: Value {
        get {
            (try? JSONDecoder().decode(Value.self, from: raw)) ?? defaultValue
        }
        nonmutating set {
            raw = (try? JSONEncoder().encode(newValue)) ?? raw
        }
    }
    
    var projectedValue: Binding<Value> {
        Binding(get: { wrappedValue }, set: { wrappedValue = $0 })
    }
}
