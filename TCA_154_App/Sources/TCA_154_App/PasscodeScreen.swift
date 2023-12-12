import ComposableArchitecture
import SwiftUI

@Reducer
public struct PasscodeScreen: Reducer {
  public struct State: Equatable {
    @BindingState public var passcode: String
    public var confirmPasscode: String
    public var mode: Mode

    public enum Mode {
      case initial, confirm, set, error
    }

    public init(
      passcode: String = "",
      confirmPasscode: String = "",
      mode: Mode = .initial
    ) {
      self.passcode = passcode
      self.confirmPasscode = confirmPasscode
      self.mode = mode
    }
  }

  public enum Action: BindableAction {
    case switchToConfirm
    case switchToSet

    case reset

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
      case .binding(\.$passcode) where state.mode == .initial:
        if state.passcode.count == 4 {
          return .run { send in
            await send(.switchToConfirm)
          }
        }

        return .none

      case .binding(\.$passcode) where state.mode == .confirm:
        guard state.passcode.count == 4 else {
          return .none
        }

        guard state.passcode == state.confirmPasscode else {
          state.mode = .error
          return .run { send in
            try await clock.sleep(for: .seconds(1))
            await send(.reset)
          }
        }

        return .run { send in
          await send(.switchToSet)
        }

      case .switchToConfirm:
        state.mode = .confirm
        state.confirmPasscode = state.passcode
        return .run { send in
          await send(.set(\.$passcode, ""))
        }

      case .switchToSet:
        state.mode = .set
        return .run { send in
          try await clock.sleep(for: .seconds(1))
          await send(.delegate(.didSetupPasscode))
        }

      case .reset:
        state.passcode = ""
        state.confirmPasscode = ""
        state.mode = .initial
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
        Text(viewStore.prompt)
          .font(.callout)

        TextField("", text: viewStore.$passcode.removeDuplicates(by: ==))
          .textFieldStyle(.roundedBorder)
          .disabled(viewStore.textFieldDisabled)
      }
      .transaction { transaction in
        transaction.animation = nil
      }
    }
  }

  struct ViewState: Equatable {
    @BindingViewState var passcode: String
    var prompt: String
    var textFieldDisabled: Bool

    init(store: BindingViewStore<PasscodeScreen.State>) {
      self._passcode = store.$passcode

      self.prompt = switch store.mode {
      case .initial: "Enter Passcode"
      case .confirm: "Confirm Passcode"
      case .set: "Passcode Set"
      case .error: "Passcodes did not match"
      }

      self.textFieldDisabled = store.mode == .set
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
