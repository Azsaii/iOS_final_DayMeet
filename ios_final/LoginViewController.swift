import UIKit
import FirebaseAuth

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    
    // 테두리 두께 변수 설정
    let defaultBorderWidth: CGFloat = 1.5
    let focusedBorderWidth: CGFloat = 2.5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 텍스트 필드의 delegate 설정
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        // 맞춤법 검사 및 자동 수정 비활성화
        emailTextField.autocorrectionType = .no
        emailTextField.spellCheckingType = .no
        passwordTextField.autocorrectionType = .no
        passwordTextField.spellCheckingType = .no
        
        // 텍스트 필드 변경 감지
        emailTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        // 텍스트 필드 초기 설정
        setupTextField(emailTextField)
        setupTextField(passwordTextField)
        
    }
    
    // 텍스트 필드 초기 설정
    func setupTextField(_ textField: UITextField) {
        textField.layer.borderWidth = defaultBorderWidth
        textField.layer.borderColor = UIColor.white.cgColor
        textField.backgroundColor = .clear
        textField.layer.cornerRadius = 5
        textField.clipsToBounds = true
    }
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            // Show alert for missing fields
            showAlert(message: "Please enter both email and password.")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { (authResult, error) in
            if let error = error {
                // Show error alert
                self.showAlert(message: error.localizedDescription)
                return
            }
            
            // Successfully logged in
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // 텍스트 필드에 포커스가 가면 영어로 입력되게 설정
        if let range = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument) {
            textField.replace(range, withText: textField.text ?? "")
        }
        textField.keyboardType = .asciiCapable
        textField.reloadInputViews()
        
        // 포커스 상태일 때 테두리 두께 변경
        textField.layer.borderWidth = focusedBorderWidth
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // 포커스가 해제될 때 테두리 두께 기본값으로 변경
        textField.layer.borderWidth = defaultBorderWidth
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            // Show alert for missing fields
            showAlert(message: "Please enter both email and password.")
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            if let error = error {
                // Show error alert
                self.showAlert(message: error.localizedDescription)
                return
            }
            
            // Successfully signed up
            self.showAlert(message: "Successfully signed up! Please log in.")
        }
    }
}
