import UIKit
import FirebaseFirestore

class PostDetailViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    
    var postId: String?
    var post: Post?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // post 객체가 있으면 UI 업데이트
        if let post = post {
            updateUI(with: post)
        // postId가 있으면 Firestore에서 데이터 가져오기
        } else if let postId = postId {
            fetchPost(with: postId)
        }
    }
    
    func setPost(_ post: Post) {
        self.post = post
    }
    
    func setPostId(_ postId: String) {
        self.postId = postId
    }
    
    func updateUI(with post: Post) {
        titleLabel.text = post.title
        contentTextView.text = post.content
        authorLabel.text = "작성자: \(post.authorName)"
        
        let timeInterval = TimeInterval(post.timestamp)
        let date = Date(timeIntervalSince1970: timeInterval)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let formattedDate = dateFormatter.string(from: date)
        
        timestampLabel.text = "작성 시각: \(formattedDate)"
    }
    
    func fetchPost(with postId: String) {
        let db = Firestore.firestore()
        db.collection("posts").document(postId).getDocument { (document, error) in
            if let document = document, document.exists {
                if let post = try? document.data(as: Post.self) {
                    self.post = post
                    self.updateUI(with: post)
                }
            } else {
                print("Post does not exist")
            }
        }
    }
}
