//
//  TCA_154_BugApp.swift
//  TCA_154_Bug
//
//  Created by Rhys Morgan on 12/12/2023.
//

import ComposableArchitecture
import SwiftUI
import TCA_154_App

@main
struct TCA_154_BugApp: App {
  let store = Store(initialState: .passcode()) {
    HomeScreen()
  }

  var body: some Scene {
    WindowGroup {
      HomeScreenView(store: store)
    }
  }
}
