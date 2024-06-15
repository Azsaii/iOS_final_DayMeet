import UIKit
import FirebaseAuth
import FirebaseFirestore

class PostCreateViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var currentDateLabel: UILabel!
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
            showAlert(title: "Error", message: "Please enter both title and content.")
            return
        }
        
        guard let user = Auth.auth().currentUser else {
            showAlert(title: "Error", message: "You must be logged in to submit a post.")
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
                self.showAlert(title: "Error", message: "Error saving post: \(error.localizedDescription)")
            } else {
                // 사용자의 게시글 경로에 글 ID 저장
                db.collection("users").document(user.uid).collection("posts").document(postId).setData(["postId": postId]) { error in
                    if let error = error {
                        self.showAlert(title: "Error", message: "Error saving post in user path: \(error.localizedDescription)")
                    } else {
                        self.showAlert(title: "Success", message: "Post successfully saved!")
                    }
                }
            }
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
                        self.showAlert(title: "Error", message: "Error loading post: \(error.localizedDescription)")
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
                            self.commentsViewController?.postId = document.documentID
                        } else {
                            self.titleTextField.text = ""
                            self.contentTextView.text = self.placeholderText
                            self.contentTextView.textColor = .lightGray
                            self.privacyToggle.isOn = true
                            self.updatePrivacyLabel(isPublic: true)
                            completion(nil)
                        }
                    }
                }
            }
    }
}
