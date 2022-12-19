import UIKit
import Combine

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

let subject = PassthroughSubject<String, Never>()
let subscription = subject.handleEvents(receiveSubscription: { (subscription) in
    print("Receive subscription")
}, receiveOutput: { output in
    print("Received output: \(output)")
}, receiveCompletion: { _ in
    print("Receive completion")
}, receiveCancel: {
    print("Receive cancel")
}, receiveRequest: { demand in
    print("Receive request: \(demand)")
}).sink { _ in }

subject.send("Hello!")
subscription.cancel()
