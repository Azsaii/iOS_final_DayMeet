import UIKit

extension UIResponder {
    
    private struct Static {
        static weak var responder: UIResponder?
    }
    
    static var currentResponder: UIResponder? {
        Static.responder = nil
        UIApplication.shared.sendAction(#selector(UIResponder._trap), to: nil, from: nil, for: nil)
        return Static.responder
    }
    
    @objc private func _trap() {
        Static.responder = self
    }
}

protocol KeyboardEvent where Self: UIViewController {
    var transformView: UIView { get }
    var isKeyboardVisible: Bool { get set }
    func setupKeyboardEvent()
}

extension KeyboardEvent where Self: UIViewController {
    func setupKeyboardEvent() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification,
                                               object: nil,
                                               queue: OperationQueue.main) { [weak self] notification in
            self?.keyboardWillAppear(notification)
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification,
                                               object: nil,
                                               queue: OperationQueue.main) { [weak self] notification in
            self?.keyboardWillDisappear(notification)
        }
    }
    
    func removeKeyboardObserver() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func keyboardWillAppear(_ sender: Notification) {
        guard !isKeyboardVisible, // 키보드가 이미 나타나 있는지 확인
              let keyboardFrame = sender.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
              let currentResponder = UIResponder.currentResponder as? UIView else { return }
        
        let keyboardTopY = keyboardFrame.cgRectValue.origin.y
        let convertedResponderFrame = transformView.convert(currentResponder.frame, from: currentResponder.superview)
        let responderBottomY = convertedResponderFrame.origin.y + convertedResponderFrame.size.height
        
        print("responderBottomY: \(responderBottomY)")
        print("keyboardTopY: \(keyboardTopY)")
        if responderBottomY > keyboardTopY {
            let offset = responderBottomY - keyboardTopY + 20 // 적절한 오프셋 추가
            transformView.frame.origin.y -= offset
            print("transformView.frame.origin.y: \(transformView.frame.origin.y)")
            isKeyboardVisible = true // 키보드가 나타났음을 기록
        }
    }
    
    private func keyboardWillDisappear(_ sender: Notification) {
        if transformView.frame.origin.y != 0 {
            transformView.frame.origin.y = 0
            isKeyboardVisible = false // 키보드가 사라졌음을 기록
        }
    }
}

