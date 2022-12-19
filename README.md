# Side Effects with Combine
One of the benefits of adopting Combine's publisher approach to asynchronous programing is that every operation is a stream or pipeline that we can subscribe and react to via powerful operators.

This works really well for situations where would like to execute code outside the scope of a publisher as certain events occur. Such executions are often described as side effects

## Side effects in general FP

A side effect is when a function relies on, or modifies, something outside its parameters to do something. For example, a function which reads or writes from a variable outside its own arguments, a database, a file, or the console can be described as having side effects.

## What are side effects in FRP?

For the context of this article and within the realm of Combine, we can define side effects as invocations that do not transform the output of a publisher which are triggered when certain events occur during a publisher's lifecycle.

Common use cases for side effects in reactive programming include but are not limited to:

- Debugging
- Error handling
- Event tracking
- Persisting data

So how would we go about implementing side effects in Combine?

## Handling events

Combine provides a useful handleEvents() operator that allows us to provide closures that can be performed when certain publisher events occur. This makes it possible, for example, to log relevant information in the event of a non-fatal error:

```
todoRepository.addTodo(title: title)
    .handleEvents(receiveCompletion: { [logger] completion in
        switch completion {
        case .failure(let error):
            logger.error(error)
            debugPrint("an error occurred: \(error)")
        case .finished:
            debugPrint("addTodo publisher completed")
        }
    })
```

In addition to the receiveCompletion parameter, the operator provides other events that we can hook into that can serve a variety of use cases:

### receiveSubscription:

Executes when the publisher receives the subscription from the upstream publisher. A possible use case for this would be to launch a background process/experience whenever a consumer subscribes:

```
videoCallProvider.acceptCall()
    .handleEvents(receiveSubscription: { [cameraManager] _ in
        cameraManager.startCapture()
    })
```

### receiveOutput:

Executes when the publisher receives a value from the upstream publisher. We could use this to keep track of Inputs as users interact with our views:

```
inputSubject
    .handleEvents(receiveOutput: { [eventTracker] input in
        switch input {
        case .addTodo:
            eventTracker.track(.todoAdded)
        case .todoRemoved:
            eventTracker.track(.todoRemoved)
        }
    })
```

### receiveCancel:

```
videoCallProvider.acceptCall()
    .handleEvents(receiveCancel: { [cameraManager] in
        cameraManager.endCapture()
    })
```

### receiveRequest:

Executes when the publisher receives a request for more elements. Had a hard time thinking of a good use case for this one, but could come in handy during situations where we would like know the amount of outputs being requested by a subscriber.

## A tip when handling events 💡:

You might have noticed when typing handleEvents, Xcode will autofill all possible parameters of the method. This can be annoying to deal with, especially if we find ourselves handling specific events frequently. Lets try and fix that with some convenient extensions:

```
extension Publisher {
    func handleOutput(_ receiveOutput: @escaping ((Self.Output) -> Void)) -> Publishers.HandleEvents<Self> {
        handleEvents(receiveOutput: receiveOutput)
    }

    func handleError(_ receiveError: @escaping ((Self.Failure) -> Void)) -> Publishers.HandleEvents<Self> {
        handleEvents(receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                receiveError(error)
            case .finished:
                ()
            }
        })
    }
}
```

With the extensions above, not only will interacting with the operator become more enjoyable, but the end result ends ups looking more readable:

```
todoRepository.addTodo(title: title)
    .handleOutput({ [eventTracker] _ in
        eventTracker.track(.todoAdded)
    })
    .handleError({ [logger] error in
        logger.error(error)
        debugPrint("an error occurred: \(error)")
    })
```

## Conclusion

In situations where we would need to execute some code along side other asynchronous code, the Combine framework can serve as a good candidate given its elegant approach to performing side effects.
