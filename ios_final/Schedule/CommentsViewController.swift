import UIKit
import FirebaseAuth
import FirebaseFirestore

protocol CommentsViewControllerDelegate: AnyObject {
    func updateCommentsContainerHeight(_ height: CGFloat)
    func scrollToBottom()
}

class CommentsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var postCommentButton: UIButton!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    weak var delegate: CommentsViewControllerDelegate?
    
    let placeholderText = "댓글 입력하기"
    var postId: String? {
        didSet {
            print("postId set to: \(postId ?? "nil")") // postId 설정 확인 로그
            loadComments()
            isCommentSaved = false // 새로 글을 로드하면 스크롤이 최하단으로 안가게 함
        }
    }
    var comments: [[String: Any]] = [] // 댓글 데이터를 저장할 배열 (딕셔너리 형태)
    var isCommentSaved = false // 댓글이 1회라도 저장되어야 화면이 최하단으로 스크롤되게 하기 위함.
    let commentHeight: CGFloat = 50 // 댓글 하나당 고정 높이
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        commentTextView.delegate = self
        
        tableView.register(CustomTableViewCell.self, forCellReuseIdentifier: "CustomCell")
        tableView.separatorStyle = .none
        tableViewHeightConstraint.constant = 0
        
        // 텍스트뷰 설정
        commentTextView.isScrollEnabled = false
        commentTextView.textContainer.lineBreakMode = .byWordWrapping
        
        // 초기 텍스트뷰 높이 설정
        commentTextView.translatesAutoresizingMaskIntoConstraints = false
        let heightConstraint = commentTextView.heightAnchor.constraint(equalToConstant: 40)
        heightConstraint.isActive = true
        view.layoutIfNeeded()
        
        // 텍스트뷰 초기 설정
        configureTextView(commentTextView)
        commentTextView.text = placeholderText

    }
    
    func textViewDidChange(_ textView: UITextView) {
        // 텍스트뷰의 기본 높이 설정
        let minHeight: CGFloat = 35 // 기본 높이
        let maxHeight: CGFloat = 3 * minHeight // 최대 3줄 높이까지만 확장
        
        // 텍스트뷰의 높이 업데이트
        let size = CGSize(width: textView.frame.width, height: .infinity)
        let estimatedSize = textView.sizeThatFits(size)
        
        textView.isScrollEnabled = estimatedSize.height > maxHeight
        
        let newHeight = min(max(estimatedSize.height, minHeight), maxHeight)
        
        textView.constraints.forEach { (constraint) in
            if constraint.firstAttribute == .height {
                constraint.constant = newHeight
            }
        }
        
        // 댓글 컨테이너 높이 업데이트
        tableView.layoutIfNeeded()
        let tableViewContentHeight = tableView.contentSize.height
        let otherSubviewsHeight: CGFloat = 25 // 예: 댓글 입력 필드와 버튼의 높이 합산
        let newContainerHeight = tableViewContentHeight + otherSubviewsHeight + newHeight
        
        delegate?.updateCommentsContainerHeight(newContainerHeight)
        delegate?.scrollToBottom()
    }
    
    // 텍스트뷰 포커싱되면 플레이스홀더 삭제
    func textViewDidBeginEditing(_ textView: UITextView) {
        if commentTextView.text == placeholderText {
            commentTextView.text = ""
            commentTextView.textColor = .white
        }
        animateBorderWidth(for: textView, to: focusedBorderWidth)
    }
    
    // 텍스트뷰 포커싱 해제되면 플레이스홀더 적용
    func textViewDidEndEditing(_ textView: UITextView) {
        if commentTextView.text.isEmpty {
            commentTextView.text = placeholderText
            commentTextView.textColor = UIColor.lightGray.withAlphaComponent(0.7)
        }
        animateBorderWidth(for: textView, to: defaultBorderWidth)
    }
    
    
    @IBAction func postCommentButtonTapped(_ sender: UIButton) {
        guard let commentText = commentTextView.text, !commentText.isEmpty else {
            showAlert(title: "Error", message: "댓글을 입력하세요.")
            return
        }
        
        saveComment(commentText)
    }
    
    func saveComment(_ comment: String) {
        
        guard let user = Auth.auth().currentUser else {
            showAlert(title: "Error", message: "You must be logged in to post a comment.")
            return
        }
        guard let postId = postId else {
            showAlert(title: "Error", message: "Invalid post ID.")
            return
        }
        
        let email = user.email ?? ""
        let username = email.components(separatedBy: "@").first ?? ""
        
        let commentData: [String: Any] = [
            "authorId": user.uid,
            "authorName": username,
            "timestamp": Int(Date().timeIntervalSince1970),
            "comment": comment
        ]
        
        let db = Firestore.firestore()
        
        db.collection("posts").document(postId).collection("comments").addDocument(data: commentData) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: "Error saving comment: \(error.localizedDescription)")
                }
            } else {
                DispatchQueue.main.async {
                    self.comments.append(commentData)
                    self.commentTextView.text = ""
                    self.tableView.reloadData()
                    self.isCommentSaved = true // 댓글이 저장되었음을 표시
                    self.updateTableViewHeight()
                }
            }
        }
    }
    
    func loadComments() {
        guard let postId = postId else {
            showAlert(title: "Error", message: "Invalid post ID.")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("posts").document(postId).collection("comments").getDocuments { (querySnapshot, error) in
            if let error = error {
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: "Error loading comments: \(error.localizedDescription)")
                }
            } else {
                DispatchQueue.main.async {
                    self.comments = querySnapshot?.documents.compactMap { $0.data() } ?? []
                    
                    // 댓글 없으면 테이블뷰 초기화.
                    if self.comments.isEmpty {
                        print("empty!")
                        self.comments = []
                    }
                    
                    // timestamp 필드에 따라 최신 댓글일수록 뒤로 가도록 정렬
                    self.comments.sort {
                        guard let timestamp1 = $0["timestamp"] as? Int,
                              let timestamp2 = $1["timestamp"] as? Int else {
                            return false
                        }
                        return timestamp1 < timestamp2
                    }
                    
                    self.tableView.reloadData()
                    self.updateTableViewHeight()
                }
            }
        }
    }
    
    func initComment() {
        
        // 댓글 창 초기화
        comments = []
        tableView.reloadData()
        updateTableViewHeight()
    }
    
    func updateTableViewHeight() {
        tableView.layoutIfNeeded()
        let tableViewContentHeight = tableView.contentSize.height
        
        let commentCount = comments.count// comments 배열에 있는 댓글 수 확인
        let otherSubviewsHeight: CGFloat = 60 // 예: 댓글 입력 필드와 버튼의 높이 합산
        let newContainerHeight = otherSubviewsHeight + CGFloat(commentCount) * commentHeight
        
        tableViewHeightConstraint.constant = newContainerHeight - otherSubviewsHeight
        delegate?.updateCommentsContainerHeight(newContainerHeight)
        if isCommentSaved {delegate?.scrollToBottom()}
    }
    
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    // UITableViewDataSource Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return commentHeight // 테이블 셀 높이
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as! CustomTableViewCell
        let commentData = comments[indexPath.row]
        if let commentText = commentData["comment"] as? String,
           let authorName = commentData["authorName"] as? String {
            cell.textLabel?.text = "\(authorName): \(commentText)"
        }
        return cell
    }
}
