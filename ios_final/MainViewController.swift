import UIKit
import FirebaseAuth
import FSCalendar

class MainViewController: UIViewController {
    
    @IBOutlet weak var loginLogoutButton: UIButton!
    @IBOutlet weak var myPostsButton: UIButton!
    @IBOutlet weak var friendPostsButton: UIButton!
    
    @IBOutlet weak var topView: UIStackView!
    @IBOutlet weak var bodyView: UIView!
    var postCreateViewController: PostCreateViewController?
    @IBOutlet weak var postView: UIView!
    @IBOutlet weak var calendar: FSCalendar!
    weak var delegate: CalendarDelegate?
    var selectedDate: Date = Date()
    
    let customFont = UIFont.SpoqaHanSans(type: .Bold, size: 20)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAuthStateListener()
        setCalendarUI()
        addPostCreateViewController()
        updateDateLabel(with: selectedDate)
        
        loginLogoutButton.titleLabel?.font = customFont
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
            postCreateViewController?.loadPost(for: selectedDate) // 선택 날짜 일기 가져오기
        }
    }
    
    func updateDateLabel(with date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        postCreateViewController?.currentDateLabel.text = dateFormatter.string(from: date)
        postCreateViewController?.selectedDate = date // 선택 날짜 변경 전달
        postCreateViewController?.loadPost(for: date) // 선택 날짜 일기 가져오기
    }
    
    private func isLoginViewControllerPresented() -> Bool {
        return presentedViewController is LoginViewController
    }
    
    @IBAction func loginLogoutButtonTapped(_ sender: UIButton) {
        if let user = Auth.auth().currentUser {
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
            loginLogoutButton.setTitle("로그아웃", for: .normal)
            print("t1")
        } else {
            // 로그아웃 상태
            print("User is logged out")
            loginLogoutButton.setTitle("로그인", for: .normal)
        }
        loginLogoutButton.titleLabel?.font = customFont
    }
}

