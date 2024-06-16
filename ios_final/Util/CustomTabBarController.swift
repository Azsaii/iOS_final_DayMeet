import UIKit
import FirebaseAuth

class CustomTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 탭 바 스타일 설정
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "darkblue") // .darkblue 색상
        
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont(name: "SpoqaHanSans-Regular", size: 15) ?? UIFont.systemFont(ofSize: 15)
        ]
        
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont(name: "SpoqaHanSans-Regular", size: 15) ?? UIFont.systemFont(ofSize: 15)
        ]
        
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        
        // 아이콘 색상 설정
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.darkGray
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
        
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        
        // 탭 바 아이템 설정
        if let viewControllers = viewControllers {
            let mainViewController = viewControllers[0]
            mainViewController.tabBarItem = UITabBarItem(title: "메인", image: UIImage(systemName: "house.fill"), tag: 0)
            
            let socialViewController = viewControllers[1]
            socialViewController.tabBarItem = UITabBarItem(title: "소셜", image: UIImage(systemName: "person.2.fill"), tag: 1)
            
            let myScheduleNavController = viewControllers[2]
            myScheduleNavController.tabBarItem = UITabBarItem(title: "나의 일정", image: UIImage(systemName: "calendar"), tag: 2)
        }
        
        // Firebase Auth 상태 변화 리스너 등록
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            guard let self = self else { return }
            self.handleUserAuthenticationChanged()
        }
    }
    
    private func handleUserAuthenticationChanged() {
        // 소셜탭의 네비게이션 스택을 초기화하여 루트 화면으로 이동
        if let socialNavController = viewControllers?[1] as? UINavigationController {
            socialNavController.popToRootViewController(animated: false)
        }
    }
}
