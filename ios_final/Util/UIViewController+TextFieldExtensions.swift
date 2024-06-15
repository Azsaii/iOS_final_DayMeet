import UIKit

// UIViewController 확장
extension UIViewController {
    
    // 테두리 두께 변수 설정
    var defaultBorderWidth: CGFloat { return 1.5 }
    var focusedBorderWidth: CGFloat { return 2.5 }
    
    func configureTextField(_ textField: UITextField) {
        
        // 스타일 적용
        textField.layer.borderWidth = defaultBorderWidth
        textField.layer.borderColor = UIColor.white.cgColor
        textField.backgroundColor = .clear
        textField.layer.cornerRadius = 5
        textField.clipsToBounds = true
        textField.delegate = self as? UITextFieldDelegate
        
        // 검사 해제
        disableChecks(for: textField)
    }
    
    func configureTextView(_ textView: UITextView) {
        
        // 스타일 적용
        textView.layer.cornerRadius = 5
        textView.clipsToBounds = true
        textView.backgroundColor = .clear
        textView.layer.borderColor = UIColor.white.cgColor
        textView.layer.borderWidth = defaultBorderWidth
        
        // 검사 해제
        disableChecks(for: textView)
    }
    
    func disableChecks(for textField: UITextField) {
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.smartInsertDeleteType = .no
        textField.autocapitalizationType = .none
        textField.keyboardType = .default
    }
    
    func disableChecks(for textView: UITextView) {
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no
        textView.autocapitalizationType = .none
        textView.keyboardType = .default
    }
    
    func animateBorderWidth(for view: UIView, to width: CGFloat) {
        let animation = CABasicAnimation(keyPath: "borderWidth")
        animation.fromValue = view.layer.borderWidth
        animation.toValue = width
        animation.duration = 0.2
        view.layer.add(animation, forKey: "borderWidth")
        view.layer.borderWidth = width
    }
    
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if title == "Error" {
            let action = UIAlertAction(title: "OK", style: .default) { _ in
                completion?()
            }
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        } else {
            self.present(alert, animated: true, completion: nil)
            // 성공인 경우 일정 시간 후에 자동으로 알림창 닫기
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // 2초 후에 닫기
                alert.dismiss(animated: true, completion: completion)
            }
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

// UITextFieldDelegate 확장
extension UIViewController: UITextFieldDelegate {
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        //textField.keyboardType = .asciiCapable
        //textField.reloadInputViews()
        
        animateBorderWidth(for: textField, to: focusedBorderWidth)
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        animateBorderWidth(for: textField, to: defaultBorderWidth)
    }
}
