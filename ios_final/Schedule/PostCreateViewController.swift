import UIKit
import FirebaseAuth
import FirebaseFirestore

class PostCreateViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var currentDateLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var privacyLabel: UILabel!
    @IBOutlet weak var privacyToggle: UISwitch!
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var submitButton: UIButton!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentTextViewHeightConstraint: NSLayoutConstraint!
    weak var commentsViewController: CommentsViewController?
    
    // 달력 선택 날짜가 바뀌면 데이터 가져오기
    var selectedDate: Date = Date()
    let placeholderText = "일정 입력하기"
    var currentPostId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleTextField.delegate = self
        contentTextView.delegate = self
        updateCurrentDateLabel()
        
        titleTextField.placeholder = "제목"
        contentTextView.text = "일정 입력하기"
        
        configureTextField(titleTextField)
        configureTextView(contentTextView)
        
        // 텍스트필드 플레이스홀더 텍스트 색상 설정
        if let placeholder = titleTextField.placeholder {
            titleTextField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        }
        submitButton.layer.cornerRadius = 5.0
        setupButtonStyle(for: deleteButton)
        setupButtonStyle(for: clearButton)
    }
    
    // 텍스트뷰 포커싱되면 플레이스홀더 삭제
    func textViewDidBeginEditing(_ textView: UITextView) {
        if contentTextView.text == placeholderText {
            contentTextView.text = ""
            contentTextView.textColor = .white
        }
        animateBorderWidth(for: textView, to: focusedBorderWidth)
    }
    
    // 텍스트뷰 포커싱 해제되면 플레이스홀더 적용
    func textViewDidEndEditing(_ textView: UITextView) {
        if contentTextView.text.isEmpty {
            contentTextView.text = placeholderText
            contentTextView.textColor = UIColor.lightGray.withAlphaComponent(0.7)
        }
        animateBorderWidth(for: textView, to: defaultBorderWidth)
    }
    
    func updateCurrentDateLabel() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        currentDateLabel.text = dateFormatter.string(from: selectedDate)
    }
    
    @IBAction func submitButtonTapped(_ sender: UIButton) {
        guard let title = titleTextField.text, !title.isEmpty,
              let content = contentTextView.text, !content.isEmpty else {
            showAlert(title: "경고", message: "제목과 내용을 입력해주세요.")
            return
        }
        
        guard let user = Auth.auth().currentUser else {
            showAlert(title: "경고", message: "일정을 저장하려면 로그인이 필요합니다.")
            return
        }
        
        let postId = UUID().uuidString
        let timestamp = Int(Date().timeIntervalSince1970)
        
        let calendar = Calendar.current
        let year = calendar.component(.year, from: selectedDate)
        let month = calendar.component(.month, from: selectedDate)
        let day = calendar.component(.day, from: selectedDate)
        let isPublic = privacyToggle.isOn
        
        guard let email = user.email,
              let indexOfAtSign = email.firstIndex(of: "@") else {
            return
        }
        
        let username = String(email.prefix(upTo: indexOfAtSign))
        
        let post: [String: Any] = [
            "authorId": user.uid,
            "authorName": username,
            "timestamp": timestamp,
            "title": title,
            "content": content,
            "year": year,
            "month": month,
            "day": day,
            "isPublic": isPublic
        ]
        
        let db = Firestore.firestore()
        
        // 모든 게시글을 위한 경로에 저장
        db.collection("posts").document(postId).setData(post) { error in
            if let error = error {
                self.showAlert(title: "에러", message: "일정 저장 에러: \(error.localizedDescription)")
            } else {
                // 사용자의 게시글 경로에 글 ID 저장
                db.collection("users").document(user.uid).collection("posts").document(postId).setData(["postId": postId]) { error in
                    if let error = error {
                        self.showAlert(title: "에러", message: "일정 저장 경로 에러: \(error.localizedDescription)")
                    } else {
                        self.showAlert(title: "성공", message: "일정이 저장되었습니다!")
                        self.commentsViewController?.setPostId(postId: postId)
                        self.currentPostId = postId
                        
                        // UserPostsViewController 에서 새로 글을 가져오게 하기 위한 알림
                        NotificationCenter.default.post(name: NSNotification.Name("NewPostCreated"), object: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        
        guard let _ = self.currentPostId,
              let _ = Auth.auth().currentUser else {
            self.showAlert(title: "작업 불가", message: "삭제할 일정이 없습니다.")
            return
        }
        
        showAlert(title: "삭제 확인", message: "정말 삭제하시겠습니까?") { [weak self] in
            self?.deletePost()
        }
    }
  
    private func deletePost() {
        guard let postId = self.currentPostId,
              let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        
        // posts 컬렉션에서 삭제
        db.collection("posts").document(postId).delete { error in
            if let error = error {
                self.showAlert(title: "에러", message: "일정 삭제 에러: \(error.localizedDescription)")
            } else {
                // users 컬렉션에서 해당 게시글 ID 삭제
                db.collection("users").document(user.uid).collection("posts").document(postId).delete { error in
                    if let error = error {
                        self.showAlert(title: "에러", message: "일정 삭제 경로 에러: \(error.localizedDescription)")
                    } else {
                        self.showAlert(title: "성공", message: "일정이 삭제되었습니다!")
                        self.resetPostFields() // 삭제 후 UI 업데이트
                        self.currentPostId = nil
                        self.commentsViewController?.setPostId(postId: "")
                    }
                }
            }
        }
    }
        
    @IBAction func clearButtonTapped(_ sender: UIButton) {
        guard let _ = self.currentPostId,
              let _ = Auth.auth().currentUser else {
            self.showAlert(title: "작업 불가", message: "이미 초기화되었습니다.")
            return
        }
        showAlert(title: "삭제 확인", message: "일정을 초기화하시겠습니까?") { [weak self] in
            self?.resetPostFields() // 입력 필드 초기화
        }
    }
    
    // 토글 값 변경 시 호출되는 메서드
    @IBAction func privacyToggleChanged(_ sender: UISwitch) {
        updatePrivacyLabel(isPublic: sender.isOn)
    }
    
    // Privacy Label 업데이트 메서드
    private func updatePrivacyLabel(isPublic: Bool) {
        privacyLabel.text = isPublic ? "공개" : "비공개"
    }
    
    // Firebase에서 날짜에 따른 글 정보 로드
    func loadPost(for date: Date, completion: @escaping (String?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            resetPostFields()
            completion(nil)
            return
        }
        
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        let db = Firestore.firestore()
        db.collection("posts")
            .whereField("authorId", isEqualTo: user.uid)
            .whereField("year", isEqualTo: year)
            .whereField("month", isEqualTo: month)
            .whereField("day", isEqualTo: day)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    DispatchQueue.main.async {
                        self.showAlert(title: "에러", message: "일정 로딩 에러: \(error.localizedDescription)")
                    }
                    completion(nil)
                } else {
                    DispatchQueue.main.async {
                        if let document = querySnapshot?.documents.first {
                            let data = document.data()
                            self.titleTextField.text = data["title"] as? String
                            self.contentTextView.text = data["content"] as? String
                            self.contentTextView.textColor = .white
                            let isPublic = data["isPublic"] as? Bool ?? true
                            self.privacyToggle.isOn = isPublic
                            self.updatePrivacyLabel(isPublic: isPublic)
                            completion(document.documentID)
                            
                            // 댓글 컨트롤러에 업데이트된 postId 전달
                            self.commentsViewController?.setPostId(postId: document.documentID)
                            
                            // 문서 ID 저장
                            self.currentPostId = document.documentID
                        } else {
                            self.resetPostFields()
                            completion(nil)
                        }
                    }
                }
            }
    }
    
    private func resetPostFields() {
        self.titleTextField.text = ""
        self.contentTextView.text = self.placeholderText
        self.contentTextView.textColor = .lightGray
        self.privacyToggle.isOn = true
        self.updatePrivacyLabel(isPublic: true)
    }
}
