import UIKit

class CustomButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStyle()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStyle()
    }
    
    private func setupStyle() {
        // 테두리 설정
        //self.layer.borderColor = UIColor.white.cgColor
        //self.layer.borderWidth = 1.5
        self.layer.cornerRadius = 5.0
        self.clipsToBounds = true
        //self.backgroundColor = .white
        //self.setTitleColor(UIColor(red: 3/255, green: 18/255, blue: 48/255, alpha: 1), for: .normal)
    }

}
