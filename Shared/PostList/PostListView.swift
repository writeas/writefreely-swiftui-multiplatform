import SwiftUI
import Combine

struct PostListView: View {
    @EnvironmentObject var model: WriteFreelyModel
    @Environment(\.managedObjectContext) var managedObjectContext

    @State private var postCount: Int = 0

    #if os(iOS)
    private var frameHeight: CGFloat {
        var height: CGFloat = 50
        let bottom = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
        height += bottom
        return height
    }
    #endif

    var body: some View {
        #if os(iOS)
        ZStack(alignment: .bottom) {
            PostListFilteredView(
                collection: model.selectedCollection,
                showAllPosts: model.showAllPosts,
                postCount: $postCount
            )
                .navigationTitle(
                    model.showAllPosts ? "All Posts" : model.selectedCollection?.title ?? (
                        model.account.server == "https://write.as" ? "Anonymous" : "Drafts"
                    )
                )
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        // We have to add a Spacer as a sibling view to the Button in some kind of Stack, so that any
                        // a11y modifiers are applied as expected: bug report filed as FB8956392.
                        ZStack {
                            Spacer()
                            Button(action: {
                                let managedPost = model.editor.generateNewLocalPost(withFont: model.preferences.font)
                                withAnimation {
                                    self.model.showAllPosts = false
                                    self.model.selectedCollection = nil
                                    self.model.selectedPost = managedPost
                                }
                            }, label: {
                                ZStack {
                                    Image("does.not.exist")
                                        .accessibilityHidden(true)
                                    Image(systemName: "square.and.pencil")
                                        .accessibilityHidden(true)
                                        .imageScale(.large)         // These modifiers compensate for the resizing
                                        .padding(.vertical, 12)     // done to the Image (and the button tap target)
                                        .padding(.leading, 12)      // by the SwiftUI layout system from adding a
                                        .padding(.trailing, 8)      // Spacer in this ZStack (FB8956392).
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            })
                            .accessibilityLabel(Text("Compose"))
                            .accessibilityHint(Text("Compose a new local draft"))
                        }
                    }
                }
            VStack {
                HStack(spacing: 0) {
                    Button(action: {
                        model.isPresentingSettingsView = true
                    }, label: {
                        Image(systemName: "gear")
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                    })
                    .accessibilityLabel(Text("Settings"))
                    .accessibilityHint(Text("Open the Settings sheet"))
                    Spacer()
                    Text(postCount == 1 ? "\(postCount) post" : "\(postCount) posts")
                        .foregroundColor(.secondary)
                    Spacer()
                    if model.isProcessingRequest {
                        ProgressView()
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                    } else {
                        Button(action: {
                            DispatchQueue.main.async {
                                model.fetchUserCollections()
                                model.fetchUserPosts()
                            }
                        }, label: {
                            Image(systemName: "arrow.clockwise")
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                        })
                        .accessibilityLabel(Text("Refresh Posts"))
                        .accessibilityHint(Text("Fetch changes from the server"))
                        .disabled(!model.account.isLoggedIn)
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 8)
                Spacer()
            }
            .frame(height: frameHeight)
            .background(Color(UIColor.systemGray5))
            .overlay(Divider(), alignment: .top)
        }
        .ignoresSafeArea()
        #else //if os(macOS)
        PostListFilteredView(
            collection: model.selectedCollection,
            showAllPosts: model.showAllPosts,
            postCount: $postCount
        )
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if model.selectedPost != nil {
                    ActivePostToolbarView(activePost: model.selectedPost!)
                        .alert(isPresented: $model.isPresentingNetworkErrorAlert, content: {
                            Alert(
                                title: Text("Connection Error"),
                                message: Text("""
                                    There is no internet connection at the moment. \
                                    Please reconnect or try again later.
                                    """),
                                dismissButton: .default(Text("OK"), action: {
                                    model.isPresentingNetworkErrorAlert = false
                                })
                            )
                        })
                }
            }
        }
        .navigationTitle(
            model.showAllPosts ? "All Posts" : model.selectedCollection?.title ?? (
                model.account.server == "https://write.as" ? "Anonymous" : "Drafts"
            )
        )
        #endif
    }
}

struct PostListView_Previews: PreviewProvider {
    static var previews: some View {
        let context = LocalStorageManager.persistentContainer.viewContext
        let model = WriteFreelyModel()

        return PostListView()
            .environment(\.managedObjectContext, context)
            .environmentObject(model)
    }
}
