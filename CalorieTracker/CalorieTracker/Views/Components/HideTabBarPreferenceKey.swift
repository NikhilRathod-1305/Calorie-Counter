import SwiftUI

/// Lets a pushed detail screen ask the root floating tab bar to hide itself,
/// since the app's tab bar is a custom overlay (not a system TabView) and has
/// no built-in way to react to navigation pushes inside a tab.
struct HideTabBarPreferenceKey: PreferenceKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

extension View {
    func hidesTabBar(_ hidden: Bool = true) -> some View {
        preference(key: HideTabBarPreferenceKey.self, value: hidden)
    }
}
