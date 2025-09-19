import Foundation

public protocol AdchainQuizEventsListener: AnyObject {
    func onImpressed(_ quizEvent: QuizEvent)
    func onClicked(_ quizEvent: QuizEvent)
    func onQuizCompleted(_ quizEvent: QuizEvent, rewardAmount: Int)
}