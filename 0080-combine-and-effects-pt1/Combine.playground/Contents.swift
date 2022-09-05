
public struct Effect<A> {
  public let run: (@escaping (A) -> Void) -> Void

  public func map<B>(_ f: @escaping (A) -> B) -> Effect<B> {
	return Effect<B> { callbackForB in self.run { a in callbackForB(f(a)) } } // { a in callbackForB(f(a)) } is now the callback for A.run (which 'persists' as part of B)
  }
}

import Dispatch

let anIntInTwoSeconds = Effect<Int> { callback in
  DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
	callback(42)
	callback(1729)
  } // Closure is A.run - note (A) -> Void callback passed in.
}

// anIntInTwoSeconds.run { int in print(int) }

// JT Uncommented second example
anIntInTwoSeconds.map { $0 * $0 }.run { int in print(int) }

import Combine

// JT Concrete implementation of a Combine publisher, that we don't need to use.
//Publisher.init
//AnyPublisher.init(<#T##publisher: Publisher##Publisher#>)


var count = 0
let iterator = AnyIterator<Int>.init {
  count += 1
  return count
}
print(Array(iterator.prefix(10)))

// Add Deferred to stop the future being eager
let aFutureInt =  Future<Int, Never> { callback in
	DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
	  print("Hello from the future")
	  callback(.success(4))
	  callback(.success(12)) // This never runs, unlike with the Effect type.
	}
}

// subscription example - can use sink instead - see below.
/*aFutureInt.subscribe(AnySubscriber<Int, Never>.init(
  receiveSubscription: { subscription in
    print("subscription")
    //subscription.cancel() - removed this, stops the subscription dead in its tracks - no output.
    subscription.request(.unlimited)
},
  receiveValue: { (value) -> Subscribers.Demand in
    print("value", value)
    return .unlimited
},
  receiveCompletion: { completion in
    print("completion", completion)
}
))*/

let cancellable = aFutureInt.sink { int in
  print(int)
}
// Need to comment next line out if we want to see a value returned.
//cancellable.cancel()

//Subject.init just a protocol so no point doing this.

let passthrough = PassthroughSubject<Int, Never>.init()
let currentValue = CurrentValueSubject<Int, Never>.init(2)

let c1 = passthrough.sink { x in
  print("passthrough", x)
}
let c2 = currentValue.sink { x in
  print("currentValue", x)
}

passthrough.send(42)
currentValue.send(1729)
passthrough.send(42)
currentValue.send(1729)

