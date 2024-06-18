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
    weak var mainViewController: MainViewController?
    
    // 달력 선택 날짜가 바뀌면 데이터 가져오기
    var selectedDate: Date = Date()
    let placeholderText = "일정 입력하기"
    var postId: String?
    
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
    
    func updatePostId(_ newPostId: String) {
        print("upd postid: \(newPostId)")
        postId = newPostId
        NotificationCenter.default.post(name: NSNotification.Name("PostIdUpdated"), object: mainViewController?.commentsViewController, userInfo: ["postId": newPostId])
    }
    
    // Firebase에서 날짜에 따른 글 정보 로드
    func loadPost(for date: Date) {
        guard let user = Auth.auth().currentUser else {
            resetPostFields()
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
                } else {
                    DispatchQueue.main.async {
                        if let document = querySnapshot?.documents.first {
                            let data = document.data()
                            // 화면에 일정 로드한 정보 나타내기
                            self.titleTextField.text = data["title"] as? String
                            self.contentTextView.text = data["content"] as? String
                            self.contentTextView.textColor = .white
                            let isPublic = data["isPublic"] as? Bool ?? true
                            self.privacyToggle.isOn = isPublic
                            self.updatePrivacyLabel(isPublic: isPublic)
                            
                            // 새로 받은 postId 전파
                            self.updatePostId(document.documentID)
                        } else {
                            self.resetPostFields()
                            self.updatePostId("") // 일정 없는 경우 postId 초기화
                        }
                    }
                }
            }
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
    
    // 현재 날짜 레이블 업데이트
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
        let formattedDate = String(format: "%04d-%02d-%02d", year, month, day)
        
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
        
        if postId == "" {
            // 새 게시글 저장
            let postId = UUID().uuidString
            saveNewPost(postId: postId, post: post, userId: user.uid, formattedDate: formattedDate)
            
        } else {
            // 기존 게시글 업데이트
            updatePost(postId: postId!, post: post, userId: user.uid, formattedDate: formattedDate)
        }
    }
    
    // 기존 게시글 업데이트
    func updatePost(postId: String, post: [String: Any], userId: String, formattedDate: String) {
        let db = Firestore.firestore()
        db.collection("posts").document(postId).updateData(post) { error in
            if let error = error {
                self.showAlert(title: "에러", message: "일정 업데이트 에러: \(error.localizedDescription)")
            } else {
                let userPostData: [String: Any] = [
                    "postId": postId,
                    "date": formattedDate
                ]
                db.collection("users").document(userId).collection("posts").document(postId).updateData(userPostData) { error in
                    if let error = error {
                        self.showAlert(title: "에러", message: "일정 업데이트 경로 에러: \(error.localizedDescription)")
                    } else {
                        self.showAlert(title: "성공", message: "일정이 업데이트되었습니다!")
                        NotificationCenter.default.post(name: NSNotification.Name("PostUpdated"), object: nil)
                    }
                }
            }
        }
    }
    
    // 새 게시글 저장
    func saveNewPost(postId: String, post: [String: Any], userId: String, formattedDate: String) {
        let db = Firestore.firestore()
        db.collection("posts").document(postId).setData(post) { error in
            if let error = error {
                self.showAlert(title: "에러", message: "일정 저장 에러: \(error.localizedDescription)")
            } else {
                let userPostData: [String: Any] = [
                    "postId": postId,
                    "date": formattedDate
                ]
                db.collection("users").document(userId).collection("posts").document(postId).setData(userPostData) { error in
                    if let error = error {
                        self.showAlert(title: "에러", message: "일정 저장 경로 에러: \(error.localizedDescription)")
                    } else {
                        self.showAlert(title: "성공", message: "일정이 저장되었습니다!")
                        //self.commentsViewController?.setPostId(postId: postId)
                        self.updatePostId(postId)
                        NotificationCenter.default.post(name: NSNotification.Name("PostUpdated"), object: nil)
                    }
                }
            }
        }
    }
    
    
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        
        guard let _ = self.postId,
              let _ = Auth.auth().currentUser else {
            self.showAlert(title: "작업 불가", message: "삭제할 일정이 없습니다.")
            return
        }
        
        showAlert(title: "삭제 확인", message: "정말 삭제하시겠습니까?") { [weak self] in
            self?.deletePost()
        }
    }
    
    // 일정 삭제
    private func deletePost() {
        guard let postId = self.postId,
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
                        self.postId = nil
                        self.updatePostId("")
                        //self.commentsViewController?.setPostId(postId: "")
                        
                        // UserPostsViewController 에서 새로 글을 가져오게 하기 위한 알림
                        NotificationCenter.default.post(name: NSNotification.Name("PostUpdated"), object: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func clearButtonTapped(_ sender: UIButton) {
        guard let _ = self.postId,
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
    
    private func resetPostFields() {
        self.titleTextField.text = ""
        self.contentTextView.text = self.placeholderText
        self.contentTextView.textColor = .lightGray
        self.privacyToggle.isOn = true
        self.updatePrivacyLabel(isPublic: true)
        self.postId = nil
        
        self.contentTextView.resignFirstResponder() // 포커스 해제
        self.titleTextField.resignFirstResponder()
    }
}
