import UIKit

protocol CustomTableViewCellDelegate: AnyObject {
    func didTapDeleteButton(on cell: CustomTableViewCell)
}

class CustomTableViewCell: UITableViewCell {
    private let containerView = UIView()
    private let separatorView = UIView() // 구분선 추가
    let commentLabel = UILabel()
    let authorLabel = UILabel()
    let deleteButton = UIButton()
    
    weak var delegate: CustomTableViewCellDelegate?
    @objc private func deleteButtonTapped() {
        delegate?.didTapDeleteButton(on: self)
    }
    
    var showSeparator: Bool = true {
        didSet {
            separatorView.isHidden = !showSeparator
        }
    }
    
    var showDeleteButton: Bool = true {
        didSet {
            deleteButton.isHidden = !showDeleteButton
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupContainerView()
        setupLabel()
        setupSeparator()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupContainerView()
        setupLabel()
        setupSeparator()
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
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
        ])
    }
    
    private func setupLabel() {
        commentLabel.numberOfLines = 0 // 여러 줄 지원
        commentLabel.lineBreakMode = .byWordWrapping // 자동 줄 바꿈
        commentLabel.textColor = .white
        commentLabel.translatesAutoresizingMaskIntoConstraints = false
        
        authorLabel.numberOfLines = 1
        authorLabel.textColor = .white
        authorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        deleteButton.setTitle("삭제", for: .normal)
        deleteButton.setTitleColor(.red, for: .normal)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        
        containerView.addSubview(commentLabel)
        containerView.addSubview(authorLabel)
        containerView.addSubview(deleteButton)
        containerView.addSubview(separatorView) // 구분선 추가
        
        NSLayoutConstraint.activate([
            authorLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
            authorLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            
            deleteButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 5),
            deleteButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            deleteButton.bottomAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: -10),
            deleteButton.widthAnchor.constraint(equalToConstant: 50), // 삭제 버튼 너비 지정
            
            commentLabel.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 10),
            commentLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10),
            commentLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            commentLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            
            separatorView.heightAnchor.constraint(equalToConstant: 1),
            separatorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: commentLabel.topAnchor, constant: -10)
        ])
    }
    
    private func setupSeparator() {
        separatorView.backgroundColor = .lightGray
        separatorView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
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
