import SwiftUI

enum Route {
    case addTimezone
    case mainView
    case editTimeZone(entryId: Int64?)
    case editProfile
    case about
}

class Router: ObservableObject {
    @Published var activeRoute: Route = .mainView

    func setActiveRoute(to route: Route) {
        withAnimation(CommandLine.arguments.contains("-ui-testing") ? nil : .default) {
            activeRoute = route
        }
    }

    func cleanActiveRoute() {
        withAnimation(CommandLine.arguments.contains("-ui-testing") ? nil : .default) {
            activeRoute = .mainView
        }
    }
}
