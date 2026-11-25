import SwiftUI
import UIKit

@main
struct RestrictionApp: App {
    @StateObject private var store = Store()

    init() {
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.06, alpha: 1)
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.05, alpha: 1)
        nav.shadowColor = .clear
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        nav.titleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .onAppear {
                    if store.data.profile.onboarded {
                        Notifs.reschedule(profile: store.data.profile)
                    }
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        Group {
            if store.data.profile.onboarded {
                mainTabs
            } else {
                OnboardingView()
            }
        }
    }

    private var mainTabs: some View {
        TabView {
            HomeView()
                .tabItem { Label("Accueil", systemImage: "flame.fill") }
            TrainView()
                .tabItem { Label("Entraînement", systemImage: "dumbbell.fill") }
            ProgressTabView()
                .tabItem { Label("Progrès", systemImage: "chart.line.uptrend.xyaxis") }
            HabitsView()
                .tabItem { Label("Hygiène", systemImage: "drop.fill") }
            MoreView()
                .tabItem { Label("Plus", systemImage: "square.grid.2x2.fill") }
        }
        .tint(Theme.accent)
        .fullScreenCover(item: $store.pendingWorkout) { template in
            ActiveWorkoutView(template: template)
                .environmentObject(store)
        }
    }
}
