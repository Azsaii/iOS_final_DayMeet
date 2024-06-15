import UIKit
import FirebaseFirestore

class PostDetailViewController: UIViewController, CommentsViewControllerDelegate, KeyboardEvent {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    
    @IBOutlet weak var commentsContainerView: UIView!
    @IBOutlet weak var commentsContainerHeightConstraint: NSLayoutConstraint!
    var commentsViewController: CommentsViewController?
    
    var postId: String? {
        didSet {
            // postId가 설정될 때 commentsViewController에 전달
            commentsViewController?.postId = postId
        }
    }
    var post: Post?
    
    // 키보드 이벤트 시 움직일 뷰
    var transformView: UIView { return self.view }
    var isKeyboardVisible = false // 키보드가 나타났는지 여부를 기록
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addCommentsViewController()
        configureTextView(contentTextView)
        contentTextView.isEditable = false
        
        // post 객체가 있으면 UI 업데이트
        if let post = post {
            updateUI(with: post)
        // postId가 있으면 Firestore에서 데이터 가져오기
        }
        
        commentsContainerHeightConstraint.constant = 60 // 초기 높이 설정
        
        // 댓글 뷰 컨트롤러가 설정된 후 postId를 전달
        if let postId = postId {
            commentsViewController?.postId = postId
        }
        
        // 키보드가 올라왔을 때 드래그하면 내려간다.
        scrollView.keyboardDismissMode = .onDrag
        
        // KeyboardEvent의 setupKeyboardEvent
        setupKeyboardEvent()
        
        // 네비게이션 바 설정
        setupNavigationBar()
    }
    
    func setupNavigationBar() {
        // 네비게이션 바의 배경색 설정
        navigationController?.navigationBar.barTintColor = UIColor.darkBlue

        if navigationController?.viewControllers.count == 1 {
            let backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(didTapBackButton))
            
            // 폰트와 텍스트 색상을 설정
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white,
                .font: UIFont(name: "SpoqaHanSans-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
            ]
            backButton.setTitleTextAttributes(attributes, for: .normal)
            
            navigationItem.leftBarButtonItem = backButton
        }
    }
    
    @objc func didTapBackButton() {
        dismiss(animated: true, completion: nil)
    }
    
    // KeyboardEvent에서 사용된 addObserver는 자동으로 제거가 안됨
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // KeyboardEvent의 removeKeyboardObserver
        removeKeyboardObserver()
    }
    
    func setPost(_ post: Post) {
        self.post = post
    }
    
    func setPostId(_ postId: String) {
        self.postId = postId
    }
    
    
    func addCommentsViewController() {
        // Storyboard 인스턴스 가져오기
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // commentsViewController 인스턴스 가져오기
        if let commentsVC = storyboard.instantiateViewController(withIdentifier: "CommentsViewController") as? CommentsViewController {
            
            // commentsViewController를 자식 ViewController로 추가
            addChild(commentsVC)
            
            // commentsViewController의 View를 commentsContainerView에 추가
            commentsVC.view.frame = commentsContainerView.bounds
            commentsContainerView.addSubview(commentsVC.view)
            
            // commentsViewController가 자식 ViewController 추가를 완료했음을 알림
            commentsVC.didMove(toParent: self)
            
            // commentsViewController 참조 저장
            self.commentsViewController = commentsVC
            commentsViewController?.delegate = self
        }
    }
    
    func updateUI(with post: Post) {
        titleLabel.text = post.title
        contentTextView.text = post.content
        authorLabel.text = "작성자: \(post.authorName)"
        
        let timeInterval = TimeInterval(post.timestamp)
        let date = Date(timeIntervalSince1970: timeInterval)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let formattedDate = dateFormatter.string(from: date)
        
        timestampLabel.text = "작성 시각: \(formattedDate)"
    }
    
    func updateCommentsContainerHeight(_ height: CGFloat) {
        commentsContainerHeightConstraint.constant = height
        view.layoutIfNeeded()
    }
    
    func scrollToBottom() {
        // 스크롤뷰를 최하단으로 스크롤
        let bottomOffset = CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.bounds.height + scrollView.contentInset.bottom)
        if bottomOffset.y > 0 {
            scrollView.setContentOffset(bottomOffset, animated: true)
        }
    }
}
