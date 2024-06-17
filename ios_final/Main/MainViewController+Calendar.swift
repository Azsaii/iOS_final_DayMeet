import UIKit
import FSCalendar
import FirebaseFirestore
import FirebaseAuth

protocol CalendarDelegate: AnyObject {
    func dateUpdated(date: String)
}

extension MainViewController: FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance {
    
    func setCalendarUI() {
        // delegate, dataSource
        self.calendar.delegate = self
        self.calendar.dataSource = self
        
        // calendar locale > 한국으로 설정
        self.calendar.locale = Locale(identifier: "ko_KR")
        
        // 상단 요일을 한글로 변경
        self.calendar.calendarWeekdayView.weekdayLabels[0].text = "일"
        self.calendar.calendarWeekdayView.weekdayLabels[1].text = "월"
        self.calendar.calendarWeekdayView.weekdayLabels[2].text = "화"
        self.calendar.calendarWeekdayView.weekdayLabels[3].text = "수"
        self.calendar.calendarWeekdayView.weekdayLabels[4].text = "목"
        self.calendar.calendarWeekdayView.weekdayLabels[5].text = "금"
        self.calendar.calendarWeekdayView.weekdayLabels[6].text = "토"
        
        // 주간/월간 표시
        //self.calendar.scope = .week   // 주간
        self.calendar.scope = .month  // 월간
        
        // 월~일 글자 폰트 및 사이즈 지정
        self.calendar.appearance.weekdayFont = UIFont.SpoqaHanSans(type: .Regular, size: 14)
        // 숫자들 글자 폰트 및 사이즈 지정
        self.calendar.appearance.titleFont = UIFont.SpoqaHanSans(type: .Regular, size: 14)
        
        // 캘린더 스크롤 가능하게 지정
        self.calendar.scrollEnabled = true
        // 캘린더 스크롤 방향 지정
        self.calendar.scrollDirection = .horizontal
        // self.calendar.scrollDirection = .vertical
        
        // Header dateFormat, 년도, 월 폰트(사이즈)와 색, 가운데 정렬
        self.calendar.appearance.headerDateFormat = "YYYY년 MM월"
        self.calendar.appearance.headerTitleFont = UIFont.SpoqaHanSans(type: .Bold, size: 20)
        self.calendar.appearance.headerTitleColor = UIColor.white.withAlphaComponent(1)
        self.calendar.appearance.headerTitleAlignment = .center
        
        // 요일 글자 색
        self.calendar.appearance.weekdayTextColor = UIColor.white.withAlphaComponent(1)
        
        // 캘린더 높이 지정
        self.calendar.headerHeight = 40
        self.calendar.weekdayHeight = 30
        // 캘린더의 cornerRadius 지정
        self.calendar.layer.cornerRadius = 10
        
        // 양옆 년도, 월 지우기
        self.calendar.appearance.headerMinimumDissolvedAlpha = 0.0
    
        // 달에 유효하지 않은 날짜의 색 지정
        self.calendar.appearance.titlePlaceholderColor = UIColor.white.withAlphaComponent(0.5)
        // 평일 날짜 색
        //self.calendar.appearance.titleDefaultColor = UIColor.red.withAlphaComponent(0.5)
        self.calendar.appearance.titleWeekendColor = UIColor.green
        // 달에 유효하지않은 날짜 지우기
        self.calendar.placeholderType = .none
        
        // 캘린더 숫자와 subtitle간의 간격 조정
        self.calendar.appearance.subtitleOffset = CGPoint(x: 0, y: 4)
        
        self.calendar.select(selectedDate)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    // 날짜를 선택했을 때 할 일을 지정
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        updateDateLabel(with: date) // 선택한 날짜로 레이블 업데이트
        let dateString = dateFormatter.string(from: date)
        self.delegate?.dateUpdated(date: dateString)
    }

    // 선택된 날짜의 배경색 지정
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillSelectionColorFor date: Date) -> UIColor? {
        //return UIColor(red: 255/255.0, green: 0/255.0, blue: 50/255.0, alpha: 1.0)
        return UIColor.white
    }
    
    // 선택된 날짜의 글자색 지정
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleSelectionColorFor date: Date) -> UIColor? {
        return UIColor.darkBlue
    }
    
    // 날짜 배경색 지정
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillDefaultColorFor date: Date) -> UIColor? {
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if dateFormatter.string(from: date) == dateFormatter.string(from: today) {
            return UIColor.clear // 오늘 날짜 배경색
        } else {
            return nil // 오늘 아닌 날짜 배경색
        }
    }
    
    // 날짜 글자색 지정
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let dateString = dateFormatter.string(from: date)
        
        if dateFormatter.string(from: date) == dateFormatter.string(from: today) {
            return UIColor(red: 255/255.0, green: 0/255.0, blue: 50/255.0, alpha: 1.0) // 오늘 날짜 색상
        } else if specialDates.contains(dateString) {
            return UIColor.yellow // 일정 있는 날짜 색 지정
        } else {
            return UIColor.white // 일정 없는 날짜 색 지정
        }
    }

    
    // 선택한 달이 변경될 때마다 리로드
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        let currentPage = calendar.currentPage
        let calendar = Calendar.current
        let year = calendar.component(.year, from: currentPage)
        let month = calendar.component(.month, from: currentPage)

        fetchSpecialDates(forYear: year, month: month) { dates in
            self.specialDates = dates
            self.calendar.reloadData()
        }
    }

    private func fetchSpecialDates(forYear year: Int, month: Int, completion: @escaping ([String]) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }

        let db = Firestore.firestore()
        let postsCollection = db.collection("users").document(userId).collection("posts")
        
        var dates: [String] = []
        
        postsCollection.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                completion(dates)
                return
            }
            
            for document in querySnapshot!.documents {
                let data = document.data()
                if let date = data["date"] as? String {
                    let dateComponents = date.split(separator: "-")
                    if dateComponents.count == 3,
                       let dateYear = Int(dateComponents[0]),
                       let dateMonth = Int(dateComponents[1]),
                       dateYear == year,
                       dateMonth == month {
                        dates.append(date)
                    }
                }
            }
            
            completion(dates)
        }
    }

    // 날짜를 선택했을 때 할일을 지정
//    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
//        let dateString = dateFormatter.string(from: date)
//        self.navigationController?.popViewController(animated: true)
//        self.delegate?.dateUpdated(date: dateString)
//    }
    
    // 선택된 날짜 테두리 색상
//    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, borderSelectionColorFor date: Date) -> UIColor? {
//        return UIColor.black.withAlphaComponent(0)
//    }
    
    // subtitle의 디폴트 색상
//    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, subtitleDefaultColorFor date: Date) -> UIColor? {
//        return UIColor.blue.withAlphaComponent(1)
//    }
    
    // 원하는 날짜 아래에 subtitle 지정
//    func calendar(_ calendar: FSCalendar, subtitleFor date: Date) -> String? {
//        switch dateFormatter.string(from: date) {
//        case dateFormatter.string(from: Date()):
//            return "오늘"
//        default:
//            return nil
//        }
//    }

    // 날짜의 글씨 자체를 오늘로 바꾸기
//    func calendar(_ calendar: FSCalendar, titleFor date: Date) -> String? {
//        switch dateFormatter.string(from: date) {
//        case dateFormatter.string(from: Date()):
//            return "오늘"
//        default:
//            return nil
//        }
//    }
}
extension UIFont {
    enum SpoqaHanSansType: String {
        case Light = "SpoqaHanSansNeo-Light"
        case Regular = "SpoqaHanSansNeo-Regular"
        case Bold = "SpoqaHanSansNeo-Bold"
    }

    static func SpoqaHanSans(type: SpoqaHanSansType, size: CGFloat) -> UIFont? {
        return UIFont(name: type.rawValue, size: size)
    }
}
