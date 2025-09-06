import UIKit

public class AdchainMissionViewBinder {
    // MARK: - Properties
    private let titleLabel: UILabel
    private let descriptionLabel: UILabel?
    private let rewardLabel: UILabel?
    private let progressLabel: UILabel?
    private let progressBar: UIProgressView?
    private let iconImageView: UIImageView?
    private let containerView: UIView
    
    private init(
        titleLabel: UILabel,
        descriptionLabel: UILabel?,
        rewardLabel: UILabel?,
        progressLabel: UILabel?,
        progressBar: UIProgressView?,
        iconImageView: UIImageView?,
        containerView: UIView
    ) {
        self.titleLabel = titleLabel
        self.descriptionLabel = descriptionLabel
        self.rewardLabel = rewardLabel
        self.progressLabel = progressLabel
        self.progressBar = progressBar
        self.iconImageView = iconImageView
        self.containerView = containerView
    }
    
    // MARK: - Bind Method (Android와 완전 동일한 로직)
    public func bind(mission: Mission, adchainMission: AdchainMission, viewController: UIViewController) {
        print("Binding mission: \(mission.id)")
        
        // Bind basic data
        titleLabel.text = mission.title
        descriptionLabel?.text = mission.description
        
        // Show participating status or point (Android와 동일)
        rewardLabel?.text = adchainMission.isParticipating(mission.id) ? "참여확인중" : mission.point
        
        // Hide progress bar (Android 주석: 개별 미션 진행도는 제공되지 않음)
        progressBar?.isHidden = true
        progressLabel?.isHidden = true
        
        // Load icon image
        if let iconImageView = iconImageView {
            loadImage(imageUrl: mission.image_url, into: iconImageView)
        }
        
        // Remove existing gesture recognizers
        containerView.gestureRecognizers?.forEach { containerView.removeGestureRecognizer($0) }
        
        // Set click listener (Android와 동일한 로직)
        let tapGesture = UITapGestureRecognizer { [weak viewController, weak self] in
            print("Mission clicked: \(mission.id)")
            
            // Open WebView immediately
            adchainMission.onMissionClicked(mission)
            if let vc = viewController {
                adchainMission.openMissionWebView(from: vc, mission: mission)
            }
            
            // Change text after 1 second (Android의 CoroutineScope와 동일)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // Change text after delay
                self?.rewardLabel?.text = "참여확인중"
                
                // Mark as participating
                adchainMission.markAsParticipating(mission.id)
            }
        }
        containerView.addGestureRecognizer(tapGesture)
        
        // Track impression
        adchainMission.onMissionImpressed(mission)
    }
    
    private func loadImage(imageUrl: String, into imageView: UIImageView) {
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
        private var titleLabel: UILabel?
        private var descriptionLabel: UILabel?
        private var rewardLabel: UILabel?
        private var progressLabel: UILabel?
        private var progressBar: UIProgressView?
        private var iconImageView: UIImageView?
        private var containerView: UIView?
        
        public init() {}
        
        public func titleTextView(_ label: UILabel) -> Builder {
            self.titleLabel = label
            return self
        }
        
        public func descriptionTextView(_ label: UILabel) -> Builder {
            self.descriptionLabel = label
            return self
        }
        
        public func rewardTextView(_ label: UILabel) -> Builder {
            self.rewardLabel = label
            return self
        }
        
        public func progressTextView(_ label: UILabel) -> Builder {
            self.progressLabel = label
            return self
        }
        
        public func progressBar(_ progressBar: UIProgressView) -> Builder {
            self.progressBar = progressBar
            return self
        }
        
        public func iconImageView(_ imageView: UIImageView) -> Builder {
            self.iconImageView = imageView
            return self
        }
        
        public func containerView(_ view: UIView) -> Builder {
            self.containerView = view
            return self
        }
        
        public func build() -> AdchainMissionViewBinder {
            guard let titleLabel = titleLabel else {
                fatalError("titleTextView must be set")
            }
            guard let containerView = containerView else {
                fatalError("containerView must be set")
            }
            
            return AdchainMissionViewBinder(
                titleLabel: titleLabel,
                descriptionLabel: descriptionLabel,
                rewardLabel: rewardLabel,
                progressLabel: progressLabel,
                progressBar: progressBar,
                iconImageView: iconImageView,
                containerView: containerView
            )
        }
    }
}