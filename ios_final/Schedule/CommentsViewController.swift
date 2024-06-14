import UIKit
import FirebaseAuth
import FirebaseFirestore

protocol CommentsViewControllerDelegate: AnyObject {
    func updateCommentsContainerHeight(_ height: CGFloat)
}

class CommentsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet weak var postCommentButton: UIButton!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    weak var delegate: CommentsViewControllerDelegate?
    
    var postId: String? {
        didSet {
            print("postId set to: \(postId ?? "nil")") // postId 설정 확인 로그
            loadComments() 
        }
    }
    var comments: [[String: Any]] = [] // 댓글 데이터를 저장할 배열 (딕셔너리 형태)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        commentTextField.delegate = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CommentCell")
        tableViewHeightConstraint.constant = 0
    }
    
    @IBAction func postCommentButtonTapped(_ sender: UIButton) {
        guard let commentText = commentTextField.text, !commentText.isEmpty else {
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
                    self.commentTextField.text = ""
                    self.tableView.reloadData()
                    self.updateTableViewHeight()
                }
            }
        }
    }
    
    func loadComments() {
        print("commend loaded!")
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
                    self.tableView.reloadData()
                    self.updateTableViewHeight()
                }
            }
        }
    }
    
    func updateTableViewHeight() {
        tableView.layoutIfNeeded()
        let tableViewContentHeight = tableView.contentSize.height
        
        let commentCount = comments.count // comments 배열에 있는 댓글 수 확인
        let commentHeight: CGFloat = 45 // 댓글 하나당 고정 높이
        
        let otherSubviewsHeight: CGFloat = 60 // 예: 댓글 입력 필드와 버튼의 높이 합산
        let newContainerHeight = otherSubviewsHeight + CGFloat(commentCount) * commentHeight
        
        tableViewHeightConstraint.constant = tableViewContentHeight
        delegate?.updateCommentsContainerHeight(newContainerHeight)
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath)
        let commentData = comments[indexPath.row]
        if let commentText = commentData["comment"] as? String,
           let authorName = commentData["authorName"] as? String {
            cell.textLabel?.text = "\(authorName): \(commentText)"
        }
        return cell
    }
}
