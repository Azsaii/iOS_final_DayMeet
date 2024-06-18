import UIKit
import FirebaseAuth
import FirebaseFirestore

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 텍스트 필드 delegate 설정
        emailTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
        nicknameTextField.delegate = self
        
        // *** 로 보이게 설정
        passwordTextField.isSecureTextEntry = true
        confirmPasswordTextField.isSecureTextEntry = true
        
        // 텍스트 필드 초기 설정
        configureTextField(emailTextField)
        configureTextField(passwordTextField)
        configureTextField(confirmPasswordTextField)
        configureTextField(nicknameTextField)
        
        // 영어만 입력 가능
        emailTextField.keyboardType = .asciiCapable
        passwordTextField.keyboardType = .asciiCapable
        confirmPasswordTextField.keyboardType = .asciiCapable
        
        // 버튼 모서리 둥글게
        signUpButton.layer.cornerRadius = 5.0
    }
    
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty,
              let nickname = nicknameTextField.text, !nickname.isEmpty else {
            // Show alert for missing fields
            showAlert(title: "경고", message: "모든 항목을 입력해주세요.")
            return
        }
        
        guard password == confirmPassword else {
            // Show alert for password mismatch
            showAlert(title: "경고", message: "비밀번호가 일치하지 않습니다.")
            passwordTextField.text = ""
            confirmPasswordTextField.text = ""
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            if let error = error {
                // Show error alert
                self.showAlert(title: "에러", message: error.localizedDescription)
                return
            }
            
            // 회원가입 후 닉네임 저장
            guard let user = Auth.auth().currentUser else { return }
            let db = Firestore.firestore()
            db.collection("users").document(user.uid).setData(["nickname": nickname]) { error in
                if let error = error {
                    self.showAlert(title: "에러", message: "회원가입 시 닉네임 저장 에러: \(error.localizedDescription)")
                } else {
                    self.showAlert(title: "회원가입 완료", message: "\(nickname)님, 환영합니다") {
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    func switchToMainScreen() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate else {
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainViewController = storyboard.instantiateViewController(withIdentifier: "MainViewController")
        let navigationController = UINavigationController(rootViewController: mainViewController)
        
        sceneDelegate.window?.rootViewController = navigationController
        sceneDelegate.window?.makeKeyAndVisible()
    }
}
