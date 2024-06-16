import UIKit
import FirebaseFirestore
import FirebaseAuth

class FriendsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var explainLabel: UILabel!
    
    var allFriends: [User] = [] // 팔로우한 친구들의 유저 정보
    var filteredFriends: [User] = [] // 필터링된 친구들의 유저 정보
    var isSearching = false // 검색 중인지 여부를 나타내는 플래그
    var selectedUserId: String? // 선택된 유저 ID를 저장할 변수
    var isFollowButtonClicked = false // 팔로우 아이콘 클릭 여부
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchTextField.delegate = self
        searchTextField.keyboardType = .asciiCapable
        
        tableView.dataSource = self
        tableView.delegate = self
        
        // 텍스트 필드에 돋보기 아이콘 추가
        if let searchIcon = UIImage(systemName: "magnifyingglass") {
            searchTextField.setLeftIcon(searchIcon)
        }
        searchTextField.setRightClearButton(target: self, action: #selector(clearText)) // 서치바에 x 버튼추가
        configureTextField(searchTextField) // 초기 설정
        
        // 키보드가 올라왔을 때 드래그하면 내려간다.
        tableView.keyboardDismissMode = .onDrag
        
        // FirebaseAuth 상태 변경 리스너 추가. 로그인/로그아웃 시 다시 팔로우 목록을 가져온다.
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            self?.fetchFriends()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
        
        // 화면이 나타날 때마다 초기화 작업
        searchTextField.text = ""
        handleTextChange("")
    }
    
    func setupNavigationBar() { // 뒤로가기 버튼 스타일 지정
        navigationController?.navigationBar.barTintColor = UIColor.darkBlue
        navigationController?.navigationBar.tintColor = UIColor.white
    }
    
    @objc private func clearText() {
        searchTextField.text = ""
        textFieldEditingChanged(searchTextField)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50 // 테이블 셀 높이
    }
    
    // Firestore에서 친구 목록을 가져옵니다.
    func fetchFriends() {
        print("fetch!")
        guard let userId = Auth.auth().currentUser?.uid else {
            // 로그아웃 상태인 경우 테이블 뷰를 비우고 배경 업데이트
            allFriends.removeAll()
            tableView.reloadData()
            updateTableViewBackground()
            return
        }
        let db = Firestore.firestore()
        let followsRef = db.collection("users").document(userId).collection("follows")
        
        followsRef.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                self.allFriends = snapshot?.documents.compactMap {
                    let data = $0.data()
                    return User(uid: $0.documentID, nickname: data["nickname"] as? String ?? "")
                } ?? []
                self.tableView.reloadData()
                self.updateTableViewBackground()
            }
        }
    }
    
    // 테이블뷰 배경 업데이트
    func updateTableViewBackground() {
        
        if allFriends.isEmpty && !isSearching {
            let noFriendsLabel = UILabel()
            if Auth.auth().currentUser == nil {
                noFriendsLabel.text = "로그인 후 팔로우 가능합니다"
            } else {
                noFriendsLabel.text = "아직 팔로우한 친구가 없습니다"
            }
            
            noFriendsLabel.textColor = .white
            noFriendsLabel.textAlignment = .center
            noFriendsLabel.frame = tableView.bounds
            noFriendsLabel.sizeToFit()
            explainLabel.text = "" // 팔로우한 친구 없는 경우 "팔로우 목록" 문장이 안나타나게 한다.
            
            tableView.backgroundView = noFriendsLabel
            tableView.separatorStyle = .none
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
            if !isSearching {
                explainLabel.text = "팔로우 목록"
            }
        }
    }
    
    // UITableViewDataSource 메소드
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? filteredFriends.count : allFriends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as! CustomTableViewCell
        
        if isSearching {
            configureCell(cell, with: filteredFriends[indexPath.row])
        } else {
            configureCell(cell, with: allFriends[indexPath.row])
        }
        
        cell.showDeleteButton = false // 삭제 버튼 숨김
        cell.showSeparator = false // 구분선 숨김
        return cell
    }
    
    func textFieldEditingChanged(_ textField: UITextField) {
        handleTextChange(textField.text ?? "")
    }
    
    override func textFieldDidEndEditing(_ textField: UITextField) {
        animateBorderWidth(for: textField, to: defaultBorderWidth)
        if textField.text?.isEmpty ?? true {
            handleTextChange("")
        }
    }
    
    // 검색 텍스트바 사용 여부에 따라 레이블 변경
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? string
        handleTextChange(currentText)
        return true
    }
    
    // 텍스트 변경 처리를 위한 함수
    private func handleTextChange(_ currentText: String) {
        if currentText.isEmpty {
            isSearching = false
            filteredFriends.removeAll()
            if isFollowButtonClicked { // 검색 후 팔로우 버튼이 한 번이라도 클릭됬을 때만 업데이트
                fetchFriends()
            }
            isFollowButtonClicked = false
            
            if allFriends.isEmpty {
                explainLabel.text = ""
            } else {
                explainLabel.text = "팔로우 목록" // 레이블 텍스트 설정
            }
        } else {
            isSearching = true
            explainLabel.text = "검색 결과" // 레이블 텍스트 설정
            searchUsers(with: currentText.lowercased()) { hasResults in
                if !hasResults {
                    self.explainLabel.text = "검색 결과 없음"
                }
            }
        }
        updateTableViewBackground()
        tableView.reloadData()
    }
    
    // 검색어를 사용하여 사용자 검색
    private func searchUsers(with query: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let usersRef = db.collection("users")
        let currentUserId = Auth.auth().currentUser?.uid
        
        // Firestore에서 닉네임을 소문자로 검색
        usersRef.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                completion(false)
            } else {
                self.filteredFriends = snapshot?.documents.compactMap {
                    let data = $0.data()
                    if let nickname = data["nickname"] as? String {
                        let matchesQuery = nickname.lowercased().contains(query.lowercased())
                        // 자신의 id 는 검색 대상에서 제외한다.
                        let isNotCurrentUser = currentUserId == nil || $0.documentID != currentUserId
                        if matchesQuery && isNotCurrentUser {
                            return User(uid: $0.documentID, nickname: nickname)
                        }
                    }
                    return nil
                } ?? []
                self.tableView.reloadData()
                completion(!self.filteredFriends.isEmpty)
            }
        }
    }
    
    func configureCell(_ cell: CustomTableViewCell, with user: User) {
        cell.textLabel?.text = user.nickname
        
        // 로그아웃 상태면 팔로우 버튼 추가 안하고 종료한다.
        guard let userId = Auth.auth().currentUser?.uid else {
            cell.accessoryView = nil
            return
        }
        
        // 팔로우 버튼 설정
        let followButton = UIButton(type: .custom)
        if let heartImage = UIImage(systemName: "heart")?.resized(to: CGSize(width: 30, height: 30)),
           let filledHeartImage = UIImage(systemName: "heart.fill")?.resized(to: CGSize(width: 30, height: 30)) {
            followButton.setImage(heartImage, for: .normal)
            followButton.setImage(filledHeartImage, for: .selected)
        }
        followButton.tintColor = .red // 하트의 색을 빨간색으로 설정
        followButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44) // 버튼 크기를 설정
        followButton.addTarget(self, action: #selector(followButtonTapped(_:)), for: .touchUpInside)
        followButton.tag = user.uid.hashValue
        
        // 버튼을 포함하는 컨테이너 뷰를 만들어서 액세서리 뷰로 설정
        let containerView = UIView(frame: followButton.frame)
        containerView.addSubview(followButton)
        cell.accessoryView = containerView
        
        // Firestore에서 팔로우 상태를 확인하여 버튼 상태 설정
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("follows").document(user.uid).getDocument { (document, error) in
            if let document = document, document.exists {
                DispatchQueue.main.async {
                    followButton.isSelected = true
                }
            } else {
                DispatchQueue.main.async {
                    followButton.isSelected = false
                }
            }
        }
    }
    
    // 팔로우 버튼 클릭 처리
    @objc func followButtonTapped(_ sender: UIButton) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        let userToFollow = allFriends.first { $0.uid.hashValue == sender.tag } ?? filteredFriends.first { $0.uid.hashValue == sender.tag }
        guard let followUser = userToFollow else { return }
        
        isFollowButtonClicked = true // 팔로우 버튼 클릭 시 플래그 업데이트
        
        if sender.isSelected {
            // 팔로우 취소 확인 알림창
            showAlert(title: "언팔로우", message: "\(followUser.nickname) 님을 언팔로우 하시겠습니까?") { [weak self] in
                guard let self = self else { return }
                let followsRef = db.collection("users").document(userId).collection("follows").document(followUser.uid)
                
                followsRef.delete { error in
                    if let error = error {
                        print("Error unfollowing user: \(error)")
                    } else {
                        sender.isSelected = false
                        // 리스트에서 팔로우 해제한 사람 제거
                        if let index = self.allFriends.firstIndex(where: { $0.uid == followUser.uid }) {
                            self.allFriends.remove(at: index)
                        }
                        if let index = self.filteredFriends.firstIndex(where: { $0.uid == followUser.uid }) {
                            self.filteredFriends.remove(at: index)
                        }
                        self.tableView.reloadData()
                        self.updateTableViewBackground()
                    }
                }
            }
        }
        else {
            // 팔로우하지 않은 경우 팔로우
            let followsRef = db.collection("users").document(userId).collection("follows").document(followUser.uid)
            
            followsRef.setData(["nickname": followUser.nickname]) { error in
                if let error = error {
                    print("Error following user: \(error)")
                } else {
                    sender.isSelected = true
                }
            }
        }
    }
    
    // 셀 클릭 시 네비게이트
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedUser = isSearching ? filteredFriends[indexPath.row] : allFriends[indexPath.row]
        selectedUserId = selectedUser.uid
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let userPostsVC = storyboard.instantiateViewController(withIdentifier: "UserPostsViewController") as? UserPostsViewController {
            userPostsVC.setUserId(selectedUserId!)
            self.navigationController?.pushViewController(userPostsVC, animated: true)
        }
    }
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let rect = CGRect(origin: .zero, size: size)
        self.draw(in: rect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage?.withRenderingMode(.alwaysTemplate)
    }
}

extension UITextField {
    func setLeftIcon(_ icon: UIImage) {
        let iconView = UIImageView(frame: CGRect(x: 10, y: 5, width: 20, height: 20)) // 아이콘의 크기와 위치를 설정
        iconView.image = icon
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .white
        
        let iconContainerView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 30))
        iconContainerView.addSubview(iconView)
        
        self.leftView = iconContainerView
        self.leftViewMode = .always
    }
    
    func setRightClearButton(target: Any?, action: Selector) {
        let clearButton = UIButton(type: .custom)
        clearButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        clearButton.tintColor = .gray
        clearButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        clearButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10) // 오른쪽 여백을 추가하여 왼쪽으로 이동
        clearButton.addTarget(target, action: action, for: .touchUpInside)
        
        self.rightView = clearButton
        self.rightViewMode = .always
    }
}
