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
        
        // 텍스트 필드 초기 설정
        setupTextField(emailTextField)
        setupTextField(passwordTextField)
        setupTextField(confirmPasswordTextField)
        setupTextField(nicknameTextField)
        
        // 텍스트 필드 delegate 설정
        emailTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
        nicknameTextField.delegate = self
        
        // 텍스트 필드 속성 설정
        configureTextField(emailTextField)
        configureTextField(passwordTextField)
        configureTextField(confirmPasswordTextField)
        configureTextField(nicknameTextField)
    }
    
    private func configureTextField(_ textField: UITextField) {
        textField.autocorrectionType = .no // 자동 수정 비활성화
        textField.spellCheckingType = .no // 맞춤법 검사 비활성화
        textField.smartInsertDeleteType = .no // 스마트 삽입/삭제 비활성화
        textField.autocapitalizationType = .none // 자동 대문자 비활성화
    }
    
    
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty,
              let nickname = nicknameTextField.text, !nickname.isEmpty else {
            // Show alert for missing fields
            showAlert(title: "Error", message: "Please fill in all fields.")
            return
        }
        
        guard password == confirmPassword else {
            // Show alert for password mismatch
            showAlert(title: "Error", message: "Passwords do not match.")
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            if let error = error {
                // Show error alert
                self.showAlert(title: "Error", message: error.localizedDescription)
                return
            }
            
            // 회원가입 후 닉네임 저장
            guard let user = Auth.auth().currentUser else { return }
            let db = Firestore.firestore()
            db.collection("users").document(user.uid).setData(["nickname": nickname]) { error in
                if let error = error {
                    self.showAlert(title: "Error", message: "Failed to save nickname: \(error.localizedDescription)")
                } else {
                    self.showAlert(title: "Success", message: "Successfully signed up!") {
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