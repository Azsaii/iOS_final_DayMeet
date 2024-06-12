import UIKit
import FirebaseAuth
import FirebaseFirestore

class PostCreateViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    
    
    @IBOutlet weak var currentDateLabel: UILabel!
    @IBOutlet weak var privacyLabel: UILabel!
    @IBOutlet weak var privacyToggle: UISwitch!
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var submitButton: UIButton!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentTextViewHeightConstraint: NSLayoutConstraint!
    
    var selectedDate: Date = Date()
    let placeholderText = "내용"
    let defaultBorderWidth = 1.5
    let focusedBorderWidth = 2.5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleTextField.delegate = self
        contentTextView.delegate = self
        updateCurrentDateLabel()
        loadPost(for: selectedDate)
        
        // 텍스트필드 설정
        titleTextField.placeholder = "제목"
        titleTextField.backgroundColor = .clear
        titleTextField.textColor = .white
        titleTextField.layer.borderColor = UIColor.white.cgColor
        titleTextField.layer.borderWidth = defaultBorderWidth
        titleTextField.layer.cornerRadius = 5
        titleTextField.clipsToBounds = true
        
        // 텍스트필드 플레이스홀더 텍스트 색상 설정
        if let placeholder = titleTextField.placeholder {
            titleTextField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        }
        
        // 텍스트뷰 설정
        contentTextView.text = placeholderText
        contentTextView.textColor = .lightGray
        contentTextView.layer.cornerRadius = 5
        contentTextView.clipsToBounds = true
        contentTextView.backgroundColor = .clear
        contentTextView.layer.borderColor = UIColor.white.cgColor
        contentTextView.layer.borderWidth = defaultBorderWidth
        
        // 초기 플레이스홀더 색상 설정
        if contentTextView.text == placeholderText {
            contentTextView.textColor = .lightGray
        } else {
            contentTextView.textColor = .white
        }
        
        // submitButton 설정
        submitButton.layer.borderColor = UIColor.white.cgColor
        submitButton.layer.borderWidth = defaultBorderWidth
        submitButton.layer.cornerRadius = 5
        submitButton.clipsToBounds = true
    }
    
    // 텍스트필드 포커싱
    func textFieldDidBeginEditing(_ textField: UITextField) {
        animateBorderWidth(for: textField, to: focusedBorderWidth)
    }
    
    // 텍스트필드 포커싱 해제
    func textFieldDidEndEditing(_ textField: UITextField) {
        animateBorderWidth(for: textField, to: defaultBorderWidth)
    }
    
    // 텍스트뷰 포커싱
    func textViewDidBeginEditing(_ textView: UITextView) {
        if contentTextView.text == placeholderText {
            contentTextView.text = ""
            contentTextView.textColor = .white
        }
        animateBorderWidth(for: textView, to: focusedBorderWidth)
    }
    
    // 텍스트뷰 포커싱
    func textViewDidEndEditing(_ textView: UITextView) {
        if contentTextView.text.isEmpty {
            contentTextView.text = placeholderText
            contentTextView.textColor = UIColor.lightGray.withAlphaComponent(0.7)
        }
        animateBorderWidth(for: textView, to: defaultBorderWidth)
    }
    
    // 애니메이션을 사용하여 테두리 두께 변경
    func animateBorderWidth(for view: UIView, to width: CGFloat) {
        let animation = CABasicAnimation(keyPath: "borderWidth")
        animation.fromValue = view.layer.borderWidth
        animation.toValue = width
        animation.duration = 0.2
        view.layer.add(animation, forKey: "borderWidth")
        view.layer.borderWidth = width
    }
    
    func updateCurrentDateLabel() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        currentDateLabel.text = dateFormatter.string(from: selectedDate)
    }
    
    @IBAction func submitButtonTapped(_ sender: UIButton) {
        guard let title = titleTextField.text, !title.isEmpty,
              let content = contentTextView.text, !content.isEmpty else {
            showAlert(message: "Please enter both title and content.")
            return
        }
        
        guard let user = Auth.auth().currentUser else {
            showAlert(message: "You must be logged in to submit a post.")
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
                self.showAlert(message: "Error saving post: \(error.localizedDescription)")
            } else {
                // 사용자의 게시글 경로에 글 ID 저장
                db.collection("users").document(user.uid).collection("posts").document(postId).setData(["postId": postId]) { error in
                    if let error = error {
                        self.showAlert(message: "Error saving post in user path: \(error.localizedDescription)")
                    } else {
                        self.showAlert(message: "Post successfully saved!")
                    }
                }
            }
        }
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // Firebase에서 날짜에 따른 글 정보 로드
    func loadPost(for date: Date) {
        guard let user = Auth.auth().currentUser else { return }
        
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
                    self.showAlert(message: "Error loading post: \(error.localizedDescription)")
                } else {
                    if let document = querySnapshot?.documents.first {
                        let data = document.data()
                        self.titleTextField.text = data["title"] as? String
                        self.contentTextView.text = data["content"] as? String
                        self.privacyToggle.isOn = data["isPublic"] as? Bool ?? true
                    } else {
                        self.titleTextField.text = ""
                        self.contentTextView.text = ""
                        self.privacyToggle.isOn = true
                    }
                }
            }
    }
}
