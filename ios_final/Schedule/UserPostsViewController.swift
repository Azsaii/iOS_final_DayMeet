import UIKit
import FirebaseAuth
import FirebaseFirestore

class UserPostsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nicknameLabel: UILabel!
    
    var commentsViewController: CommentsViewController?
    var posts: [Post] = []
    var postIds: [String] = []
    var userId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        fetchUserPosts()
        
        // UITableViewCell 등록
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PostCell")
        
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            guard let self = self else { return }
            self.fetchUserPosts()
        }
        
        // 새로운 일정이 생성되었을 때 알림을 수신하도록 등록
        NotificationCenter.default.addObserver(self, selector: #selector(handleNewPostCreated), name: NSNotification.Name("NewPostCreated"), object: nil)
    }
    
    @objc func handleNewPostCreated() {
        fetchUserPosts()
    }
    
    
    func setUserId(_ userId: String) {
        
        self.userId = userId
        
        let currentUserId = Auth.auth().currentUser?.uid
        if userId == currentUserId {
            nicknameLabel.text = "나의 일정 목록"
        } else {
            let db = Firestore.firestore()
            db.collection("users").document(userId).getDocument { (document, error) in
                if let error = error {
                    print("Error fetching user nickname: \(error)")
                    self.nicknameLabel.text = "일정 목록"
                } else if let document = document, let data = document.data(), let nickname = data["nickname"] as? String {
                    self.nicknameLabel.text = "\(nickname)의 일정 목록"
                } else {
                    self.nicknameLabel.text = "일정 목록"
                }
            }
        }
    }
    
    func fetchUserPosts() {
        guard let userId = userId ?? Auth.auth().currentUser?.uid else {
            print("User not logged in or userId not set")
            setClearTable() // 테이블 뷰 초기화
            return
        }
        print("id: \(userId)")
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("posts").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting user posts: \(error.localizedDescription)")
            } else {
                let postIds = querySnapshot?.documents.compactMap { document in
                    document.data()["postId"] as? String
                } ?? []
                
                if postIds.isEmpty {
                    self.setClearTable() // 테이블 뷰 초기화
                } else {
                    self.hideNoPostsMessage()
                    self.fetchPosts(by: postIds)
                }
            }
        }
    }
    
    func fetchPosts(by postIds: [String]) {
        let db = Firestore.firestore()
        let postsRef = db.collection("posts")
        
        let dispatchGroup = DispatchGroup()
        
        var fetchedPostsWithIds: [(post: Post, id: String)] = []  // Post 객체와 문서 ID를 함께 저장
        
        for postId in postIds {
            dispatchGroup.enter()
            postsRef.document(postId).getDocument { (document, error) in
                if let error = error {
                    print("Error fetching post with ID \(postId): \(error)")
                } else if let document = document, document.exists {
                    do {
                        let post = try document.data(as: Post.self)
                        if post.isPublic {
                            fetchedPostsWithIds.append((post: post, id: postId))  // Post 객체와 문서 ID를 함께 저장
                        }
                    } catch {
                        print("Error decoding post with ID \(postId): \(error)")
                    }
                } else {
                    print("No document found with ID \(postId)")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            // 작성 날짜에 따라 정렬
            let sortedPostsWithIds = fetchedPostsWithIds.sorted {
                if $0.post.year != $1.post.year {
                    return $0.post.year > $1.post.year
                } else if $0.post.month != $1.post.month {
                    return $0.post.month > $1.post.month
                } else {
                    return $0.post.day > $1.post.day
                }
            }
            
            // 각각의 배열에 저장
            self.posts = sortedPostsWithIds.map { $0.post }
            self.postIds = sortedPostsWithIds.map { $0.id }
            
            if self.posts.isEmpty {
                self.showNoPostsMessage()
            } else {
                self.tableView.reloadData()
            }
        }
    }
    
    func setClearTable() {
        posts.removeAll()
        postIds.removeAll()
        showNoPostsMessage()
        tableView.reloadData() // 테이블 뷰 초기화
    }
    
    func showNoPostsMessage() {
        let noPostsLabel = UILabel()
        noPostsLabel.text = "추가된 일정이 없습니다"
        noPostsLabel.textColor = .white
        noPostsLabel.textAlignment = .center
        noPostsLabel.frame = tableView.bounds
        noPostsLabel.sizeToFit()
        
        tableView.backgroundView = noPostsLabel
        tableView.separatorStyle = .none
    }
    
    func hideNoPostsMessage() {
        tableView.backgroundView = nil
        tableView.separatorStyle = .singleLine
    }
    
    // UITableViewDataSource 및 UITableViewDelegate 메서드 구현
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as! CustomTableViewCell
        let post = posts[indexPath.row]
        
        let dateString = "\(post.month) / \(post.day) 일정: \(post.title)"
        cell.textLabel?.text = dateString
        cell.detailTextLabel?.text = post.content
        
        // 셀의 배경색과 글자색 설정
        cell.backgroundColor = .customBlue
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .white
        
        // 셀의 선택 스타일을 none으로 설정
        cell.selectionStyle = .none
        
        cell.showDeleteButton = false // 삭제 버튼 숨김
        cell.showSeparator = false // 구분선 숨김
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50 // 테이블 셀 높이
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // 선택 해제
        let post = posts[indexPath.row]
        let postId = postIds[indexPath.row] // postIds 배열에서 해당 포스트의 ID를 가져옴
        navigateToPostDetail(with: post, postId: postId)
    }
    
    func navigateToPostDetail(with post: Post, postId: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let postDetailVC = storyboard.instantiateViewController(withIdentifier: "PostDetailViewController") as? PostDetailViewController {
            postDetailVC.post = post
            postDetailVC.postId = postId
            self.navigationController?.pushViewController(postDetailVC, animated: true)
        }
    }
}
