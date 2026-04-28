import Foundation
import WatchKit

final class AppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        BackgroundRefresh.scheduleNext()
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let refresh as WKApplicationRefreshBackgroundTask:
                Task {
                    await DataStore.shared.refresh()
                    BackgroundRefresh.scheduleNext()
                    refresh.setTaskCompletedWithSnapshot(false)
                }
            case let urlTask as WKURLSessionRefreshBackgroundTask:
                urlTask.setTaskCompletedWithSnapshot(false)
            case let snapshot as WKSnapshotRefreshBackgroundTask:
                snapshot.setTaskCompleted(restoredDefaultState: true,
                                          estimatedSnapshotExpiration: .distantFuture,
                                          userInfo: nil)
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}
