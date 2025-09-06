import UIKit

public class AdchainQuizViewBinder {
    // MARK: - Properties (Android와 완전 동일)
    private let iconImageView: UIImageView
    private let titleLabel: UILabel
    private let descriptionLabel: UILabel?
    private let pointsLabel: UILabel?
    private let containerView: UIView
    
    private init(
        iconImageView: UIImageView,
        titleLabel: UILabel,
        descriptionLabel: UILabel?,
        pointsLabel: UILabel?,
        containerView: UIView
    ) {
        self.iconImageView = iconImageView
        self.titleLabel = titleLabel
        self.descriptionLabel = descriptionLabel
        self.pointsLabel = pointsLabel
        self.containerView = containerView
    }
    
    // MARK: - Bind Method (Android와 완전 동일한 로직)
    public func bind(quizEvent: QuizEvent, quiz: AdchainQuiz, viewController: UIViewController) {
        // Set title
        titleLabel.text = quizEvent.title
        
        // Set description if available
        descriptionLabel?.text = quizEvent.description
        
        // Set points if available
        pointsLabel?.text = quizEvent.point
        
        // Load image (Android의 Glide와 대응)
        loadImage(imageUrl: quizEvent.image_url, into: iconImageView)
        
        // Remove existing gesture recognizers
        containerView.gestureRecognizers?.forEach { containerView.removeGestureRecognizer($0) }
        
        // Set click listener
        let tapGesture = UITapGestureRecognizer { [weak viewController] in
            print("Quiz item clicked: \(quizEvent.id)")
            
            // Track click
            quiz.trackClick(quizEvent)
            
            // Open WebView
            if let vc = viewController {
                quiz.openQuizWebView(from: vc, quizEvent: quizEvent)
            }
        }
        containerView.addGestureRecognizer(tapGesture)
        
    }
    
    private func loadImage(imageUrl: String, into imageView: UIImageView) {
        // Using URLSession for basic image loading (replace with SDWebImage in production)
        guard let url = URL(string: imageUrl) else {
            imageView.image = UIImage(systemName: "photo")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                if let data = data, let image = UIImage(data: data) {
                    imageView.image = image
                } else {
                    imageView.image = UIImage(systemName: "photo")
                    if let error = error {
                        print("Failed to load image: \(imageUrl), error: \(error)")
                    }
                }
            }
        }.resume()
    }
    
    // MARK: - Builder Pattern (Android와 동일)
    public class Builder {
        private var iconImageView: UIImageView?
        private var titleLabel: UILabel?
        private var descriptionLabel: UILabel?
        private var pointsLabel: UILabel?
        private var containerView: UIView?
        
        public init() {}
        
        public func iconImageView(_ view: UIImageView) -> Builder {
            self.iconImageView = view
            return self
        }
        
        public func titleTextView(_ label: UILabel) -> Builder {
            self.titleLabel = label
            return self
        }
        
        public func descriptionTextView(_ label: UILabel) -> Builder {
            self.descriptionLabel = label
            return self
        }
        
        public func pointsTextView(_ label: UILabel) -> Builder {
            self.pointsLabel = label
            return self
        }
        
        public func containerView(_ view: UIView) -> Builder {
            self.containerView = view
            return self
        }
        
        public func build() -> AdchainQuizViewBinder {
            guard let iconImageView = iconImageView else {
                fatalError("Icon ImageView is required")
            }
            guard let titleLabel = titleLabel else {
                fatalError("Title TextView is required")
            }
            guard let containerView = containerView else {
                fatalError("Container View is required")
            }
            
            return AdchainQuizViewBinder(
                iconImageView: iconImageView,
                titleLabel: titleLabel,
                descriptionLabel: descriptionLabel,
                pointsLabel: pointsLabel,
                containerView: containerView
            )
        }
    }
}

// MARK: - Gesture Recognizer with Closure
extension UITapGestureRecognizer {
    convenience init(action: @escaping () -> Void) {
        self.init()
        addAction(action)
    }
    
    private func addAction(_ action: @escaping () -> Void) {
        let sleeve = ClosureSleeve(action)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke))
        objc_setAssociatedObject(self, "\(UUID())", sleeve, .OBJC_ASSOCIATION_RETAIN)
    }
}

private class ClosureSleeve {
    let closure: () -> Void
    
    init(_ closure: @escaping () -> Void) {
        self.closure = closure
    }
    
    @objc func invoke() {
        closure()
    }
}