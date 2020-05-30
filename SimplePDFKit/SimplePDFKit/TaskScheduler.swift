import Foundation

final class TaskScheduler {
	var minDelay: TimeInterval
	
	private let queue: DispatchQueue
	private var mostRecentTask: Task?
	private var nextTaskTime = DispatchTime(uptimeNanoseconds: 0)
	
	init(on queue: DispatchQueue, minDelay: TimeInterval) {
		self.queue = queue
		self.minDelay = minDelay
	}
	
	func enqueue(_ taskBlock: @escaping () -> Void) {
		let task = Task()
		mostRecentTask = task
		queue.async { [queue] in
			guard self.mostRecentTask == task else { return }
			
			let now = DispatchTime.now()
			guard self.nextTaskTime < now else {
				queue.asyncAfter(deadline: self.nextTaskTime, execute: {
					guard self.mostRecentTask == task else { return }
					taskBlock()
				})
				return
			}
			self.nextTaskTime = now + self.minDelay
			
			taskBlock()
		}
	}
	
	private struct Task: Equatable {
		let id = UUID()
	}
}
