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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        searchTextField.delegate = self
        searchTextField.keyboardType = .asciiCapable
        searchTextField.setRightClearButton(target: self, action: #selector(clearText))

        tableView.dataSource = self
        tableView.delegate = self

        // 텍스트 필드에 돋보기 아이콘 추가
        if let searchIcon = UIImage(systemName: "magnifyingglass") {
            searchTextField.setLeftIcon(searchIcon)
        }
        configureTextField(searchTextField) // 검사 해제
        setupTextField(searchTextField) // 스타일 설정

        fetchFriends()
    }

    @objc private func clearText() {
        searchTextField.text = ""
        textFieldEditingChanged(searchTextField)
    }

    
    private func configureTextField(_ textField: UITextField) {
        textField.autocorrectionType = .no // 자동 수정 비활성화
        textField.spellCheckingType = .no // 맞춤법 검사 비활성화
        textField.smartInsertDeleteType = .no // 스마트 삽입/삭제 비활성화
        textField.autocapitalizationType = .none // 자동 대문자 비활성화
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50 // 원하는 셀 높이 설정 (예: 80)
    }
    
    // Firestore에서 친구 목록을 가져옵니다.
    func fetchFriends() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
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
            }
        }
    }
    
    // UITableViewDataSource 메소드
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            return filteredFriends.count
        } else {
            return allFriends.isEmpty ? 1 : allFriends.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as! CustomTableViewCell
        
        if isSearching {
            configureCell(cell, with: filteredFriends[indexPath.row])
        } else {
            if allFriends.isEmpty {
                cell.textLabel?.text = "No followed friends found."
                cell.textLabel?.textColor = .white
                cell.backgroundColor = .customBlue
                cell.accessoryView = nil
            } else {
                configureCell(cell, with: allFriends[indexPath.row])
            }
        }
        
        return cell
    }
    
    func configureCell(_ cell: CustomTableViewCell, with user: User) {
        cell.textLabel?.text = user.nickname
        cell.textLabel?.textColor = .white // 글자색
        cell.backgroundColor = .customBlue // 셀 배경색 설정
        
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
        
        if sender.isSelected {
            // 팔로우 취소 확인 알림창
            let alert = UIAlertController(title: "Unfollow", message: "Are you sure you want to unfollow \(followUser.nickname)?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Unfollow", style: .destructive, handler: { _ in
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
                    }
                }
            }))
            present(alert, animated: true, completion: nil)
        } else {
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
    
    @objc func textFieldEditingChanged(_ textField: UITextField) {
        let currentText = textField.text ?? ""
        if currentText.isEmpty {
            isSearching = false
            filteredFriends.removeAll()
            explainLabel.text = "팔로우 목록" // 레이블 텍스트 설정
            fetchFriends() // 검색어가 비워졌을 때 팔로우한 사람 목록을 다시 가져옴
        } else {
            isSearching = true
            explainLabel.text = "검색 결과" // 레이블 텍스트 설정
            searchUsers(with: currentText.lowercased())
        }
        tableView.reloadData()
    }
    
    override func textFieldDidEndEditing(_ textField: UITextField) {
        animateBorderWidth(for: textField, to: defaultBorderWidth)
        if textField.text?.isEmpty ?? true {
            isSearching = false
            filteredFriends.removeAll()
            explainLabel.text = "팔로우 목록" // 레이블 텍스트 설정
            fetchFriends() // 검색어가 비워졌을 때 팔로우한 사람 목록을 다시 가져옴
            tableView.reloadData()
        }
    }
    
    // 검색 텍스트바 사용 여부에 따라 레이블 변경
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? string
        if currentText.isEmpty {
            isSearching = false
            filteredFriends.removeAll()
            explainLabel.text = "팔로우 목록" // 레이블 텍스트 설정
            fetchFriends() // 검색어가 비워졌을 때 팔로우한 사람 목록을 다시 가져옴
        } else {
            isSearching = true
            explainLabel.text = "검색 결과" // 레이블 텍스트 설정
            searchUsers(with: currentText.lowercased())
        }
        tableView.reloadData()
        return true
    }
    
    func searchUsers(with query: String) {
        let db = Firestore.firestore()
        let usersRef = db.collection("users")
        let currentUserId = Auth.auth().currentUser?.uid
        
        // Firestore에서 닉네임을 소문자로 검색
        usersRef.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
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
            }
        }
    }
}

// 유저 모델
struct User {
    var uid: String
    var nickname: String
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
