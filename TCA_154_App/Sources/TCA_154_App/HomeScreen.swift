import ComposableArchitecture
import SwiftUI

@Reducer
public struct HomeScreen: Reducer {
  public enum State: Equatable {
    case passcode(PasscodeScreen.State = PasscodeScreen.State())
    case second
  }

  public enum Action {
    case passcode(PasscodeScreen.Action)
    case second(Void)
  }

  public init() {}

  @Dependency(\.suspendingClock) var clock

  public var body: some ReducerOf<Self> {
    Scope(state: \.passcode, action: \.passcode) {
      PasscodeScreen()
    }

    Reduce { state, action in
      switch action {
      case .passcode(.delegate(.didSetupPasscode)):
        state = .second
        return .none

      case .passcode:
        return .none

      case .second:
        state = .passcode(.init())
        return .none
      }
    }
  }
}

public struct HomeScreenView: View {
  let store: StoreOf<HomeScreen>

  public init(store: StoreOf<HomeScreen>) {
    self.store = store
  }

  public var body: some View {
    SwitchStore(store) { state in
      switch state {
      case .passcode:
        CaseLet(\HomeScreen.State.passcode, action: HomeScreen.Action.passcode) { store in
          PasscodeScreenView(store: store)
        }

      case .second:
        CaseLet(\HomeScreen.State.second, action: HomeScreen.Action.second) { store in
          VStack {
            Text("Did Set Up Passcode Successfully!")
            Button("Go back") {
              store.send(())
            }
          }
        }
      }
    }
  }
}
