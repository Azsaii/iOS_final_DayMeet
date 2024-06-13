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
}
