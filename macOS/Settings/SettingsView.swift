import SwiftUI

struct SettingsView: View {
    @State var selectedView = 0

    var body: some View {
        TabView(selection: $selectedView) {
            Form {
                Section(header: Text("Login Details")) {
                    AccountView()
                }
            }
            .tabItem {
                Image(systemName: "person.crop.circle")
                Text("Account")
            }
            .tag(0)
            VStack {
                PreferencesView()
                Spacer()
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Preferences")
            }
            .tag(1)
        }
    }
}

struct SettingsView_AccountTabPreviews: PreviewProvider {
    static var previews: some View {
        SettingsView(selectedView: 0)
    }
}

struct SettingsView_PreferencesTabPreviews: PreviewProvider {
    static var previews: some View {
        SettingsView(selectedView: 1)
    }
}
