import Foundation

final actor TaskScheduler {
	private var nextTaskTime = DispatchTime(uptimeNanoseconds: 0)
	private var cancel: (() -> Void)?
	
	func enqueue<T>(minDelay: TimeInterval, _ taskBlock: @escaping () -> T) async throws -> T {
		let now = DispatchTime.now()
		cancel?()
		let task = Task {
			do {
				if nextTaskTime > now {
					try await Task.sleep(nanoseconds: nextTaskTime.uptimeNanoseconds - now.uptimeNanoseconds)
				}
				try Task.checkCancellation()
			} catch {
				throw error
			}
			nextTaskTime = .now() + minDelay
			return taskBlock()
		}
		cancel = task.cancel
		return try await task.value
	}
}
