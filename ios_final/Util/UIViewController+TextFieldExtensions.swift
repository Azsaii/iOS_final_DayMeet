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
        
        if title == "에러" || title == "경고" {
            let action = UIAlertAction(title: "OK", style: .default) { _ in
                completion?()
            }
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        } else if title == "삭제 확인" || title == "언팔로우" || title == "로그아웃" {
            let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
            
            let deleteAction = UIAlertAction(title: "삭제", style: .destructive) { _ in
                completion?()
            }
            let unfollowAction = UIAlertAction(title: "언팔로우", style: .destructive) { _ in
                completion?()
            }
            let logoutAction = UIAlertAction(title: "로그아웃", style: .destructive) { _ in
                completion?()
            }
            
            alert.addAction(cancelAction)
            
            switch title{
            case "언팔로우": alert.addAction(unfollowAction)
            case "로그아웃": alert.addAction(logoutAction)
            default: alert.addAction(deleteAction)
            }
            self.present(alert, animated: true, completion: nil)
        } else {
            self.present(alert, animated: true, completion: nil)
            // 성공인 경우 일정 시간 후에 자동으로 알림창 닫기
            var duration = 0.5 // 알림창 닫히기까지 시간
            if title == "회원가입 완료" {
                duration = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                alert.dismiss(animated: true, completion: completion)
            }
        }
    }

    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func setupButtonStyle(for button: UIButton) {
        // 테두리 설정
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1.5
        button.layer.cornerRadius = 5.0
        button.clipsToBounds = true
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
