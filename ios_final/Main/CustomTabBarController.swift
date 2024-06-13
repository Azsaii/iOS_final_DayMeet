import UIKit

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

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }

        // 탭 바 아이템 설정
        if let viewControllers = viewControllers {
            let mainViewController = viewControllers[0]
            mainViewController.tabBarItem = UITabBarItem(title: "Main", image: UIImage(systemName: "house.fill"), tag: 0)
            
            let socialViewController = viewControllers[1]
            socialViewController.tabBarItem = UITabBarItem(title: "Social", image: UIImage(systemName: "person.2.fill"), tag: 1)
        }
    }
}
