import UIKit
import FirebaseAuth
import FirebaseFirestore

protocol CommentsViewControllerDelegate: AnyObject {
    func updateCommentsContainerHeight(_ height: CGFloat)
    func scrollToBottom()
    func scrollToTop()
}

class CommentsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, CustomTableViewCellDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var postCommentButton: UIButton!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    weak var delegate: CommentsViewControllerDelegate?
    
    let placeholderText = "댓글 입력하기"
    var postId: String?
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
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100 // 적절한 추정 높이 설정
        
        tableViewHeightConstraint.constant = 0
        
        // 텍스트뷰 설정
        commentTextView.isScrollEnabled = false
        commentTextView.textContainer.lineBreakMode = .byWordWrapping
        
        // 텍스트뷰 초기 설정
        configureTextView(commentTextView)
        commentTextView.textColor = UIColor.white
        // 드래그 시 키보드 내림
        tableView.keyboardDismissMode = .onDrag
        
        postCommentButton.layer.cornerRadius = 5.0
        
        // postId 업데이트 수신
        NotificationCenter.default.addObserver(self, selector: #selector(handlePostIdUpdated(_:)), name: NSNotification.Name("PostIdUpdated"), object: self)
    }
    
    @objc func handlePostIdUpdated(_ notification: Notification) {
        if let userInfo = notification.userInfo, let postId = userInfo["postId"] as? String {
            self.postId = postId
            // 변경된 날짜의 일정이 없는경우 댓글 초기화, 있으면 댓글 로드
            postId == "" ? initComment() : loadComments()
            self.commentTextView.text = ""
            self.commentTextView.resignFirstResponder()
        }
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
        let tableViewContentHeight = tableView.contentSize.height
        let otherSubviewsHeight: CGFloat = 25 // 예: 댓글 입력 필드와 버튼의 높이 합산
        let newContainerHeight = tableViewContentHeight + otherSubviewsHeight + newHeight
        
        delegate?.updateCommentsContainerHeight(newContainerHeight)
        delegate?.scrollToBottom()
    }
    
    // 텍스트뷰 포커싱되면 플레이스홀더 삭제
    func textViewDidBeginEditing(_ textView: UITextView) {
        animateBorderWidth(for: textView, to: focusedBorderWidth)
    }
    
    // 텍스트뷰 포커싱 해제되면 플레이스홀더 적용
    func textViewDidEndEditing(_ textView: UITextView) {
        animateBorderWidth(for: textView, to: defaultBorderWidth)
    }
    
    
    @IBAction func postCommentButtonTapped(_ sender: UIButton) {
        guard let commentText = commentTextView.text, !commentText.isEmpty else {
            showAlert(title: "경고", message: "댓글을 입력해주세요.")
            return
        }
        
        saveComment(commentText)
    }
    
    func saveComment(_ comment: String) {
        guard let user = Auth.auth().currentUser else {
            showAlert(title: "경고", message: "댓글을 작성하려면 로그인이 필요합니다.")
            return
        }
        if postId == "" {
            showAlert(title: "경고", message: "일정을 저장해야 댓글 작성이 가능합니다.")
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
        let document = db.collection("posts").document(postId!).collection("comments").document()
        
        document.setData(commentData) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.showAlert(title: "에러", message: "댓글 저장 에러: \(error.localizedDescription)")
                }
            } else {
                var newCommentData = commentData
                newCommentData["id"] = document.documentID // 고유 ID 추가
                DispatchQueue.main.async {
                    self.comments.append(newCommentData)
                    self.commentTextView.text = ""
                    self.commentTextView.resignFirstResponder()
                    self.tableView.reloadData()
                    self.isCommentSaved = true // 댓글이 저장되었음을 표시
                    self.updateTableViewHeight()
                    self.isCommentSaved = false // 스크롤 막기
                }
            }
        }
    }
    
    func loadComments() {
        if postId == "" {
            showAlert(title: "에러", message: "잘못된 일정 id")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("posts").document(postId!).collection("comments").getDocuments { (querySnapshot, error) in
            if let error = error {
                DispatchQueue.main.async {
                    self.showAlert(title: "에러", message: "댓글 로딩 에러: \(error.localizedDescription)")
                }
            } else {
                DispatchQueue.main.async {
                    self.comments = querySnapshot?.documents.compactMap { document in
                        var data = document.data()
                        data["id"] = document.documentID
                        return data
                    } ?? []
                    
                    // 댓글 없으면 테이블뷰 초기화.
                    if self.comments.isEmpty {
                        print("comment empty!")
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
    
    // 댓글 창 초기화
    func initComment() {
        print("init comment")
        comments = []
        tableView.reloadData()
        updateTableViewHeight()
    }
    
    @objc private func deleteButtonTapped(_ sender: UIButton) {
        guard let cell = sender.superview?.superview as? CustomTableViewCell,
              let indexPath = tableView.indexPath(for: cell) else { return }
        
        showAlert(title: "삭제 확인", message: "정말 삭제하시겠습니까?") {
            self.deleteComment(at: indexPath)
        }
    }
    
    // UITableViewDataSource Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func updateTableViewHeight() {
        tableView.layoutIfNeeded()
        var totalHeight: CGFloat = 0
        
        for i in 0..<comments.count {
            let indexPath = IndexPath(row: i, section: 0)
            totalHeight += tableView.rectForRow(at: indexPath).height
        }
        
        let otherSubviewsHeight: CGFloat = 60 // 댓글 입력 필드와 버튼의 높이 합산
        let newContainerHeight = totalHeight + otherSubviewsHeight
        
        tableViewHeightConstraint.constant = totalHeight
        delegate?.updateCommentsContainerHeight(newContainerHeight)
        if isCommentSaved {
            delegate?.scrollToBottom()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as! CustomTableViewCell
        let commentData = comments[indexPath.row]
        if let commentText = commentData["comment"] as? String,
           let authorName = commentData["authorName"] as? String,
           let authorId = commentData["authorId"] as? String {
            cell.commentLabel.text = commentText
            cell.authorLabel.text = authorName
            cell.deleteButton.isHidden = authorId != Auth.auth().currentUser?.uid
            cell.delegate = self // 델리게이트 설정
            setupButtonStyle(for: cell.deleteButton) // 버튼 스타일 설정
        }
        return cell
    }
    
    func didTapDeleteButton(on cell: CustomTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        showAlert(title: "삭제 확인", message: "정말 삭제하시겠습니까?") {
            self.deleteComment(at: indexPath)
        }
    }
    
    private func deleteComment(at indexPath: IndexPath) {
        let commentData = comments[indexPath.row]
        guard let commentId = commentData["id"] as? String else { return }
        print("delete commentid: \(commentId)")
        let db = Firestore.firestore()
        db.collection("posts").document(postId!).collection("comments").document(commentId).delete { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.showAlert(title: "에러", message: "댓글 삭제 에러: \(error.localizedDescription)")
                }
            } else {
                DispatchQueue.main.async {
                    self.comments.remove(at: indexPath.row)
                    self.tableView.reloadData()
                    self.updateTableViewHeight()
                }
            }
        }
    }
}
