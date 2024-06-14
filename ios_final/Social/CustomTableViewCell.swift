import UIKit

class CustomTableViewCell: UITableViewCell {
    private let bottomBorder = CALayer()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupBottomBorder()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupBottomBorder()
    }

    private func setupBottomBorder() {
        bottomBorder.backgroundColor = UIColor.lightGray.cgColor // 밑줄 색상 설정
        layer.addSublayer(bottomBorder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let borderWidth: CGFloat = 1.0
        bottomBorder.frame = CGRect(x: 0, y: frame.size.height - borderWidth, width: frame.size.width, height: borderWidth)
    }

    func hideBottomBorder() {
        bottomBorder.isHidden = true
    }

    func showBottomBorder() {
        bottomBorder.isHidden = false
    }
    
    // 아이템이 선택되어도 배경색이 안변하게 한다.
    override func awakeFromNib() {
        super.awakeFromNib()
        setupAppearance()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // 선택 상태와 관계없이 배경색 설정
        setupAppearance()
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        // 강조 상태와 관계없이 배경색 설정
        setupAppearance()
    }

    private func setupAppearance() {
        // 초기 배경색 설정
        self.contentView.backgroundColor = .customBlue
        self.backgroundColor = .customBlue
        updateAccessoryViewBackgroundColor()
        self.selectionStyle = .none // 선택 스타일을 none으로 설정
    }

    private func updateAccessoryViewBackgroundColor() {
        // 액세서리 뷰의 배경색 설정
        if let accessoryView = self.accessoryView {
            accessoryView.backgroundColor = .customBlue
            accessoryView.subviews.forEach { subview in
                subview.backgroundColor = .customBlue
            }
        }
    }
}
