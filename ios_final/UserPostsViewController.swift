import UIKit
import FirebaseAuth
import FirebaseFirestore

class UserPostsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var posts: [Post] = []
    
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

    func setupNavigationBar() {
        let backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backButtonTapped))
        navigationItem.leftBarButtonItem = backButton
    }

    @objc func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    
    func fetchUserPosts() {
        guard let user = Auth.auth().currentUser else {
            print("User not logged in")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("posts").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting user posts: \(error.localizedDescription)")
            } else {
                let postIds = querySnapshot?.documents.compactMap { document in
                    document.data()["postId"] as? String
                } ?? []
                
                self.fetchPosts(by: postIds)
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
                if let document = document, document.exists {
                    if let post = try? document.data(as: Post.self) {
                        fetchedPosts.append(post)
                    }
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.posts = fetchedPosts.sorted { $0.timestamp > $1.timestamp }
            self.tableView.reloadData()
        }
    }
    
    // UITableViewDataSource 및 UITableViewDelegate 메서드 구현
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath)
        let post = posts[indexPath.row]
        cell.textLabel?.text
        cell.textLabel?.text = post.title
        cell.detailTextLabel?.text = post.content
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.row]
        navigateToPostDetail(with: post)
    }
    
    func navigateToPostDetail(with post: Post) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let postDetailVC = storyboard.instantiateViewController(withIdentifier: "PostDetailViewController") as? PostDetailViewController {
            postDetailVC.setPost(post)
            navigationController?.pushViewController(postDetailVC, animated: true)
        }
    }
}
