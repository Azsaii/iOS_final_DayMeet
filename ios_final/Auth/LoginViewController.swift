import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 텍스트 필드의 delegate 설정
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        // 스타일, 검사 설정
        configureTextField(emailTextField)
        configureTextField(passwordTextField)
        
        // 버튼 모서리 둥글게
        loginButton.layer.cornerRadius = 5.0
        signUpButton.layer.cornerRadius = 5.0
    }
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            // Show alert for missing fields
            showAlert(title: "경고", message: "아이디와 비밀번호를 입력해주세요.")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { (authResult, error) in
            if let error = error {
                // Show error alert
                self.showAlert(title: "에러", message: error.localizedDescription)
                return
            }
            
            // Successfully logged in
            self.showAlert(title: "성공", message: "로그인 완료") {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showSignUp", sender: self)
    }
}
