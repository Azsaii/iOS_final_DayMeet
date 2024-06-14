import UIKit
import FirebaseAuth
import FSCalendar

class MainViewController: UIViewController, CommentsViewControllerDelegate {
    
    @IBOutlet weak var loginLogoutButton: UIButton!
    @IBOutlet weak var myPostsButton: UIButton!
    
    @IBOutlet weak var bodyView: UIView!
    var postCreateViewController: PostCreateViewController?
    @IBOutlet weak var postView: UIView!
    @IBOutlet weak var calendar: FSCalendar!
    weak var delegate: CalendarDelegate?
    var selectedDate: Date = Date()
    let customFont = UIFont.SpoqaHanSans(type: .Light, size: 20)
    
    @IBOutlet weak var commentsContainerView: UIView!
    @IBOutlet weak var commentsContainerHeightConstraint: NSLayoutConstraint!
    var commentsViewController: CommentsViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAuthStateListener()
        setCalendarUI()
        addPostCreateViewController()
        addCommentsViewController()
        updateDateLabel(with: selectedDate)
        
        loginLogoutButton.titleLabel?.font = customFont
        loginLogoutButton.layer.borderColor = UIColor.white.cgColor
        loginLogoutButton.layer.borderWidth = 1.5
        loginLogoutButton.layer.cornerRadius = 15.0
        
        commentsViewController?.delegate = self 
        commentsContainerHeightConstraint.constant = 60 // 초기 높이 설정
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

            // commentsViewController 설정
            if let commentsVC = self.commentsViewController {
                postCreateViewController?.commentsViewController = commentsVC
            }
        }
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
        }
    }
    
    func updateDateLabel(with date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        postCreateViewController?.currentDateLabel.text = dateFormatter.string(from: date)
        postCreateViewController?.selectedDate = date // 선택 날짜 변경 전달
        postCreateViewController?.loadPost(for: date) { [weak self] postId in
            guard let self = self else { return }
            if let postId = postId {
                print("Received postId: \(postId)") // postId 로그 출력
                self.commentsViewController?.postId = postId
            } else {
                print("No postId found for the selected date.") // postId가 없을 때 로그 출력
            }
        }
    }
    
    
    private func isLoginViewControllerPresented() -> Bool {
        return presentedViewController is LoginViewController
    }
    
    @IBAction func loginLogoutButtonTapped(_ sender: UIButton) {
        if Auth.auth().currentUser != nil {
            // 로그아웃 처리
            do {
                try Auth.auth().signOut()
                // 로그아웃 후 UI 업데이트
                updateUIForLoginState()
                print("User logged out successfully")
                return
            } catch let signOutError as NSError {
                print("Error signing out: %@", signOutError)
            }
        } else {
            // 로그인 화면 표시
            if !isLoginViewControllerPresented() {
                print("Showing login view controller")
                performSegue(withIdentifier: "showLogin", sender: self)
            }
        }
    }
    
    @IBAction func myPostsButtonTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let userPostsVC = storyboard.instantiateViewController(withIdentifier: "UserPostsViewController") as? UserPostsViewController {
            let navController = UINavigationController(rootViewController: userPostsVC)
            navController.modalPresentationStyle = .fullScreen
            self.present(navController, animated: true, completion: nil)
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
        print("main height update")
        commentsContainerHeightConstraint.constant = height
        view.layoutIfNeeded()
    }
}

