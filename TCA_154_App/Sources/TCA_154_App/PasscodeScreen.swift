import ComposableArchitecture
import SwiftUI

@Reducer
public struct PasscodeScreen: Reducer {
  public struct State: Equatable {
    @BindingState public var passcode: String

    public init(passcode: String = "") {
      self.passcode = passcode
    }
  }

  public enum Action: BindableAction {
    case delegate(Delegate)
    case binding(BindingAction<State>)

    public enum Delegate {
      case didSetupPasscode
    }
  }

  @Dependency(\.suspendingClock) var clock

  public var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce<State, Action> { state, action in
      switch action {
      case .binding(\.$passcode):
        if state.passcode.caseInsensitiveCompare("open") == .orderedSame {
          return .run { send in
            await send(.delegate(.didSetupPasscode))
          }
        }

        return .none

      case .delegate, .binding:
        return .none
      }
    }
  }
}

public struct PasscodeScreenView: View {
  let store: StoreOf<PasscodeScreen>

  public init(store: StoreOf<PasscodeScreen>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
      VStack {
        Text("Enter Passcode")
          .font(.callout)

        TextField("", text: viewStore.$passcode.removeDuplicates(by: ==))
          .textFieldStyle(.roundedBorder)
      }
    }
  }

  struct ViewState: Equatable {
    @BindingViewState var passcode: String

    init(store: BindingViewStore<PasscodeScreen.State>) {
      self._passcode = store.$passcode
    }
  }
}

extension Binding {
  func removeDuplicates(by equals: @escaping (Value, Value) -> Bool) -> Self {
    Binding(
      get: { self.wrappedValue },
      set: { newValue, transaction in
        guard !equals(newValue, self.wrappedValue) else { return }
        if transaction.animation != nil {
          withTransaction(transaction) {
            self.wrappedValue = newValue
          }
        } else {
          self.wrappedValue = newValue
        }
      }
    )
  }
}
