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
        
        // 맞춤법 검사 및 자동 수정 비활성화
        configureTextField(emailTextField)
        configureTextField(passwordTextField)
        
        // 텍스트 필드 초기 설정
        setupTextField(emailTextField)
        setupTextField(passwordTextField)
        
    }
    
    private func configureTextField(_ textField: UITextField) {
        textField.autocorrectionType = .no // 자동 수정 비활성화
        textField.spellCheckingType = .no // 맞춤법 검사 비활성화
        textField.smartInsertDeleteType = .no // 스마트 삽입/삭제 비활성화
        textField.autocapitalizationType = .none // 자동 대문자 비활성화
    }
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            // Show alert for missing fields
            showAlert(title: "Error", message: "Please enter both email and password.")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { (authResult, error) in
            if let error = error {
                // Show error alert
                self.showAlert(title: "Error", message: error.localizedDescription)
                return
            }
            
            // Successfully logged in
            self.showAlert(title: "Success", message: "Successfully logged in!") {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showSignUp", sender: self)
    }
}
