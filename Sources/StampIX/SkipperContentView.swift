import SwiftUI

enum SkipperContentTab: String, Hashable {
    case welcome, home, settings
}

struct SkipperContentView: View {
    @AppStorage("tab") var tab = SkipperContentTab.welcome
    @AppStorage("name") var welcomeName = "Skipper"
    @AppStorage("appearance") var appearance = ""
    @State var viewModel = ViewModel()

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                SkipperWelcomeView(welcomeName: $welcomeName)
            }
            .tabItem { Label("Welcome", systemImage: "heart.fill") }
            .tag(SkipperContentTab.welcome)

            NavigationStack {
                SkipperItemListView()
                    .navigationTitle(Text("\(viewModel.items.count) Items"))
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(SkipperContentTab.home)

            NavigationStack {
                SkipperSettingsView(appearance: $appearance, welcomeName: $welcomeName)
                    .navigationTitle("Settings")
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            .tag(SkipperContentTab.settings)
        }
        .environment(viewModel)
        .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
    }
}

struct SkipperWelcomeView : View {
    @State var heartBeating = false
    @Binding var welcomeName: String

    var body: some View {
        VStack(spacing: 0) {
            Text("Hello [\(welcomeName)](https://skip.dev)!")
                .padding()
            Image(systemName: "heart.fill")
                .foregroundStyle(.red)
                .scaleEffect(heartBeating ? 1.5 : 1.0)
                .task {
                    withAnimation(.easeInOut(duration: 1).repeatForever()) {
                        heartBeating = true
                    }
                }
        }
        .font(.largeTitle)
    }
}

struct SkipperItemListView : View {
    @Environment(ViewModel.self) var viewModel: ViewModel

    var body: some View {
        List {
            ForEach(viewModel.items) { item in
                NavigationLink(value: item) {
                    Label {
                        Text(item.itemTitle)
                    } icon: {
                        if item.favorite {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                        }
                    }
                }
            }
            .onDelete { offsets in
                viewModel.items.remove(atOffsets: offsets)
            }
            .onMove { fromOffsets, toOffset in
                viewModel.items.move(fromOffsets: fromOffsets, toOffset: toOffset)
            }
        }
        .navigationDestination(for: Item.self) { item in
            ItemView(item: item)
                .navigationTitle(item.itemTitle)
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    withAnimation {
                        viewModel.items.insert(Item(), at: 0)
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
    }
}

struct SkipperItemView : View {
    @State var item: Item
    @Environment(ViewModel.self) var viewModel: ViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            TextField("Title", text: $item.title)
                .textFieldStyle(.roundedBorder)
            Toggle("Favorite", isOn: $item.favorite)
            DatePicker("Date", selection: $item.date)
            Text("Notes").font(.title3)
            TextEditor(text: $item.notes)
                .border(Color.secondary, width: 1.0)
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    viewModel.save(item: item)
                    dismiss()
                }
                .disabled(!viewModel.isUpdated(item))
            }
        }
    }
}

struct SkipperSettingsView : View {
    @Binding var appearance: String
    @Binding var welcomeName: String

    var body: some View {
        Form {
            TextField("Name", text: $welcomeName)
            Picker("Appearance", selection: $appearance) {
                Text("System").tag("")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                Text("Version \(version) (\(buildNumber))")
            }
            HStack {
                PlatformHeartView()
                Text("Powered by [Skip](https://skip.dev)")
            }
        }
    }
}

/// A view that shows a blue heart on iOS and a green heart on Android.
struct SkipperPlatformHeartView : View {
    var body: some View {
        #if os(Android)
        ComposeView {
            SkipperHeartComposer()
        }
        #else
        Text(verbatim: "💙")
        #endif
    }
}

#if SKIP
/// Use a ContentComposer to integrate Compose content. This code will be transpiled to Kotlin.
struct SkipperHeartComposer : ContentComposer {
    @Composable func Compose(context: ComposeContext) {
        androidx.compose.material3.Text("💚", modifier: context.modifier)
    }
}
#endif
