import SwiftUI

/// App root: Entry and Totals side by side in a horizontal pager with a
/// custom bottom tab bar. A pager (not the system TabView) because saving an
/// expense slides to Totals with a horizontal animation, which TabView cannot
/// do; both screens stay alive so an in-progress entry survives tab switches.
struct RootTabView: View {
    @State private var selectedTab: Tab = .entry
    @State private var showSaveConfirmation = false
    /// Each save bumps this; a dismiss timer only hides the confirmation it
    /// was scheduled for, so rapid saves keep the overlay up.
    @State private var confirmationGeneration = 0

    private enum Tab: Hashable {
        case entry
        case totals
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                pager
                tabBar
            }

            if showSaveConfirmation {
                saveConfirmationOverlay
            }
        }
        // Keep the tab bar pinned under the keyboard like the system one.
        .ignoresSafeArea(.keyboard, edges: .bottom)
        // spendthrift://entry — the widget's non-button tap target opens the
        // app straight onto the keypad (spec: widget-quick-entry).
        .onOpenURL { url in
            if url.scheme == "spendthrift", url.host == "entry" {
                selectedTab = .entry
            }
        }
    }

    private var pager: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                EntryView(onSaved: handleExpenseSaved)
                    .frame(width: geometry.size.width)
                    .accessibilityHidden(selectedTab != .entry)
                TotalsView()
                    .frame(width: geometry.size.width)
                    .accessibilityHidden(selectedTab != .totals)
            }
            .offset(x: selectedTab == .entry ? 0 : -geometry.size.width)
            // The off-screen page stays mounted (state survives switches) but
            // must not be reachable — by taps or the accessibility tree, which
            // would otherwise surface duplicate elements from both pages.
        }
    }

    private func handleExpenseSaved() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedTab = .totals
        }
        showSaveConfirmation = true
        confirmationGeneration += 1
        let generation = confirmationGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if confirmationGeneration == generation {
                showSaveConfirmation = false
            }
        }
    }

    // MARK: - Tab bar

    private var tabBar: some View {
        HStack {
            tabButton(for: .entry, label: "Entry", systemImage: "square.grid.3x3.fill", identifier: "tab-entry")
            tabButton(for: .totals, label: "Totals", systemImage: "chart.bar.fill", identifier: "tab-totals")
        }
        .padding(.top, 8)
        .overlay(alignment: .top) { Divider() }
        .background(.bar, ignoresSafeAreaEdges: .bottom)
    }

    private func tabButton(for tab: Tab, label: String, systemImage: String, identifier: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 20))
                Text(label)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(selectedTab == tab ? Color.accentColor : Color.secondary)
        .accessibilityIdentifier(identifier)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selectedTab == tab ? [.isSelected] : [])
    }

    // MARK: - Save confirmation (spec: non-blocking, no tap to dismiss)

    private var saveConfirmationOverlay: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 48))
            .foregroundStyle(.green)
            .padding(24)
            .background(.thinMaterial, in: Circle())
            .accessibilityIdentifier("save-confirmation")
            .accessibilityLabel("Expense saved")
            .transition(.opacity)
            .allowsHitTesting(false)
    }
}

#Preview {
    RootTabView()
}
