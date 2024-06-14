import UIKit
import FirebaseAuth
import FirebaseFirestore

class UserPostsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nicknameLabel: UILabel!
    
    var posts: [Post] = []
    var userId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        fetchUserPosts()
        
        // UITableViewCell 등록
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PostCell")
        
        // 뒤로가기 버튼 설정
        setupNavigationBar()
    }
    
    func setUserId(_ userId: String) {
        self.userId = userId
        
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
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

    func setupNavigationBar() {
        let backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backButtonTapped))
        navigationItem.leftBarButtonItem = backButton
    }

    @objc func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    
    func fetchUserPosts() {
        guard let userId = userId ?? Auth.auth().currentUser?.uid else {
            print("User not logged in or userId not set")
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
                    self.showNoPostsMessage()
                } else {
                    self.fetchPosts(by: postIds)
                }
            }
        }
    }

    func fetchPosts(by postIds: [String]) {
        let db = Firestore.firestore()
        let postsRef = db.collection("posts")
        
        let dispatchGroup = DispatchGroup()
        
        var fetchedPosts: [Post] = []
        
        for postId in postIds {
            dispatchGroup.enter()
            postsRef.document(postId).getDocument { (document, error) in
                if let error = error {
                    print("Error fetching post with ID \(postId): \(error)")
                } else if let document = document, document.exists {
                    do {
                        let post = try document.data(as: Post.self)
                        // isPublic 필드가 true인 경우에만 가져오기
                        if post.isPublic {
                            fetchedPosts.append(post)
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
            self.posts = fetchedPosts.sorted { $0.timestamp > $1.timestamp }
            if self.posts.isEmpty {
                self.showNoPostsMessage()
            } else {
                self.tableView.reloadData()
            }
        }
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
        return cell
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // 선택 해제
        let post = posts[indexPath.row]
        navigateToPostDetail(with: post)
    }
    
    // Navigate to PostDetailViewController using performSegue
    func navigateToPostDetail(with post: Post) {
        self.performSegue(withIdentifier: "showPostDetail", sender: post)
    }

    // Prepare for segue and pass the post data
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPostDetail",
           let postDetailVC = segue.destination as? PostDetailViewController,
           let post = sender as? Post {
            postDetailVC.setPost(post)
        }
    }
}
