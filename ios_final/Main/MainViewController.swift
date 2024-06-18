import UIKit
import FirebaseAuth
import FSCalendar

class MainViewController: UIViewController, CommentsViewControllerDelegate, KeyboardEvent {
    
    @IBOutlet weak var loginLogoutButton: UIButton!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var bodyView: UIView!
    var postCreateViewController: PostCreateViewController?
    @IBOutlet weak var postView: UIView!
    @IBOutlet weak var calendar: FSCalendar!
    weak var delegate: CalendarDelegate?
    
    var specialDates: [String] = [] // 현재 보이는 달에서 일정이 저장된 날짜들을 저장하는 배열
    var selectedDate: Date = Date()
    let customFont = UIFont.SpoqaHanSans(type: .Light, size: 20)
    
    @IBOutlet weak var commentsContainerView: UIView!
    @IBOutlet weak var commentsContainerHeightConstraint: NSLayoutConstraint!
    var commentsViewController: CommentsViewController?
    
    // 키보드 이벤트 시 움직일 뷰
    var transformView: UIView { return self.view }
    var isKeyboardVisible = false // 키보드가 나타났는지 여부를 기록
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAuthStateListener()
        setCalendarUI()
        calendarCurrentPageDidChange(calendar) // 일정 있는 날짜 색 변경
        addCommentsViewController()
        addPostCreateViewController()
        
        loginLogoutButton.titleLabel?.font = customFont
        loginLogoutButton.layer.borderColor = UIColor.white.cgColor
        loginLogoutButton.layer.borderWidth = 1.5
        loginLogoutButton.layer.cornerRadius = 15.0
        
        commentsContainerHeightConstraint.constant = 60 // 초기 높이 설정
        
        // 키보드가 올라왔을 때 드래그하면 내려간다.
        scrollView.keyboardDismissMode = .onDrag
        
        // KeyboardEvent의 setupKeyboardEvent
        setupKeyboardEvent()
        
        // 로그인 / 로그아웃 리스터
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            guard let self = self else { return }
            commentsViewController?.initComment() // 댓글 초기화
            self.updateDateLabel(with: self.selectedDate) // 오늘 날짜로 레이블 초기화
            self.calendar.select(self.selectedDate) // 오늘 날짜로 달력에서 선택
            calendarCurrentPageDidChange(calendar) // 일정 있는 날짜 색 변경
            scrollToTop()
        }
        
        // 일정이 생성/삭제 되었을 때 알림을 수신하도록 등록
        NotificationCenter.default.addObserver(self, selector: #selector(handleNewPostCreated), name: NSNotification.Name("PostUpdated"), object: nil)
    }
    
    @objc func handleNewPostCreated() {
        calendarCurrentPageDidChange(calendar) // 일정 있는 날짜 색 변경
    }
    
    // KeyboardEvent에서 사용된 addObserver는 자동으로 제거가 안됨
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // KeyboardEvent의 removeKeyboardObserver
        removeKeyboardObserver()
    }
    
    func addPostCreateViewController() {
        // Storyboard 인스턴스 가져오기
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // postCreateViewController 인스턴스 가져오기
        if let postVC = storyboard.instantiateViewController(withIdentifier: "PostCreateViewController") as? PostCreateViewController {
            
            // postCreateViewController를 자식 ViewController로 추가
            addChild(postVC)
            
            // postCreateViewController의 View를 postView에 추가
            postVC.view.frame = postView.bounds
            postView.addSubview(postVC.view)
            
            // postCreateViewController가 자식 ViewController 추가를 완료했음을 알림
            postVC.didMove(toParent: self)
            
            // postCreateViewController 참조 저장
            postCreateViewController = postVC
            postCreateViewController?.selectedDate = selectedDate // 선택 날짜 변경 전달
            postCreateViewController?.mainViewController = self
            
            // commentsViewController 설정
            if let mainCommentsVC = self.commentsViewController {
                postCreateViewController?.commentsViewController = mainCommentsVC
            }
        }
    }
    
    func addCommentsViewController() {
        // Storyboard 인스턴스 가져오기
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // commentsViewController 인스턴스 가져오기
        if let mainCommentsVC = storyboard.instantiateViewController(withIdentifier: "CommentsViewController") as? CommentsViewController {
            
            // commentsViewController를 자식 ViewController로 추가
            addChild(mainCommentsVC)
            
            // commentsViewController의 View를 commentsContainerView에 추가
            mainCommentsVC.view.frame = commentsContainerView.bounds
            commentsContainerView.addSubview(mainCommentsVC.view)
            
            // commentsViewController가 자식 ViewController 추가를 완료했음을 알림
            mainCommentsVC.didMove(toParent: self)
            
            // commentsViewController 참조 저장
            self.commentsViewController = mainCommentsVC
            commentsViewController?.delegate = self
        }
    }
    
    func updateDateLabel(with date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        postCreateViewController?.currentDateLabel.text = dateFormatter.string(from: date)
        postCreateViewController?.selectedDate = date // 선택 날짜 변경 전달
        postCreateViewController?.loadPost(for: date)
    }
    
    private func isLoginViewControllerPresented() -> Bool {
        return presentedViewController is LoginViewController
    }
    
    @IBAction func loginLogoutButtonTapped(_ sender: UIButton) {
        if Auth.auth().currentUser != nil {
            // 로그아웃 처리
            showAlert(title: "로그아웃", message: "로그아웃 하시겠습니까?") { [weak self] in
                guard let self = self else { return }
                do {
                    try Auth.auth().signOut()
                    // 로그아웃 후 UI 업데이트
                    updateUIForLoginState()
                    print("User logged out successfully")
                    return
                } catch let signOutError as NSError {
                    print("Error signing out: %@", signOutError)
                }
            }
            
        } else {
            // 로그인 화면 표시
            if !isLoginViewControllerPresented() {
                print("Showing login view controller")
                performSegue(withIdentifier: "showLogin", sender: self)
            }
        }
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            self?.updateUIForLoginState()
        }
    }
    
    private func updateUIForLoginState() {
        if let user = Auth.auth().currentUser {
            // 로그인 상태
            print("User is logged in as: \(user.email ?? "No Email")")
            loginLogoutButton.setTitle("Logout", for: .normal)
        } else {
            // 로그아웃 상태
            print("User is logged out")
            loginLogoutButton.setTitle("Login", for: .normal)
        }
        loginLogoutButton.titleLabel?.font = customFont
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
    
    func scrollToTop() {
        // 스크롤뷰를 최상단으로 스크롤
        let topOffset = CGPoint(x: 0, y: -scrollView.contentInset.top)
        scrollView.setContentOffset(topOffset, animated: true)
    }
}
