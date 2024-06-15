import UIKit

class CustomTableViewCell: UITableViewCell {
    private let containerView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupContainerView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupContainerView()
    }

    private func setupContainerView() {
        containerView.backgroundColor = .customBlue
        containerView.layer.cornerRadius = 5
        containerView.layer.masksToBounds = false
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
        contentView.addSubview(containerView)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.frame = contentView.bounds.insetBy(dx: 16, dy: 8)
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
        self.contentView.backgroundColor = .clear // contentView의 배경색을 투명하게 설정
        self.backgroundColor = .clear // 셀의 배경색도 투명하게 설정
        self.textLabel?.textColor = .white
        updateAccessoryViewBackgroundColor()
        self.selectionStyle = .none // 선택 스타일을 none으로 설정
    }

    private func updateAccessoryViewBackgroundColor() {
        // 액세서리 뷰의 배경색 설정
        if let accessoryView = self.accessoryView {
            accessoryView.backgroundColor = .clear
            accessoryView.subviews.forEach { subview in
                subview.backgroundColor = .clear
            }
        }
    }
}
