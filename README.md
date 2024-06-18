# 일정 관리 및 공유 앱 - Day Meet
2024년 4학년 1학기 iOS 기말 프로젝트입니다.


## 기능 소개

### 로그인 / 로그아웃 / 회원가입
- 메인 화면 우측 상단에 항상 보이는 로그인 버튼을 통해 로그인과 회원가입이 가능합니다.
- 로그인 화면에서 회원가입 버튼을 누르면 회원가입 화면으로 이동합니다.
- 로그인한 상태라면 메인 화면의 로그인 버튼이 로그아웃 버튼으로 변경됩니다.
- 계정 정보는 파이어베이스에서 관리됩니다.

### 메인 화면
- 로그인한 경우, 달력에서 날짜를 선택한 후 일정을 작성하고 저장할 수 있습니다.
- 달력에서 오늘 날짜는 **빨간색**, 저장된 일정이 있는 날짜는 **노란색**으로 표시됩니다. 그 외에는 흰색으로 표시됩니다.
- 달력을 좌우로 드래그하여 달을 변경할 수 있습니다.
- 일정을 다른 사람에게 공개할지 여부를 선택할 수 있습니다. 비공개 일정은 오직 자신만 볼 수 있습니다.
- 일정 초기화 버튼을 눌러 작성 중인 일정의 입력 필드를 초기화할 수 있습니다.
- 삭제 버튼을 눌러 저장된 일정을 삭제할 수 있습니다.
- 기존에 저장된 일정을 수정한 후 저장 버튼을 누르면 업데이트됩니다.
- 저장된 일정에는 댓글을 작성할 수 있고, 본인이 작성한 댓글에 한해 삭제가 가능합니다.
- 일정과 댓글은 파이어베이스에 저장됩니다.

### 소셜 화면
- 닉네임으로 사용자 검색이 가능합니다.
- 로그인한 경우, 다른 사용자를 검색해서 팔로우, 언팔로우 가능합니다.
- 검색 중이 아닌 경우, 팔로우한 사용자 목록이 나타납니다.
- 검색 결과나 팔로우 목록에 나타난 다른 사용자를 터치하면 해당 사용자의 공개된 일정들을 [mm / dd 일정: 제목] 형식으로 보이는 리스트 화면이 나타납니다.
- 일정 리스트에서 하나를 선택하면 일정의 제목, 내용, 작성자, 작성시각, 댓글이 나타나는 화면으로 이동합니다.
- 로그인한 경우, 다른 사용자의 일정 하단에 댓글 작성 및 삭제가 가능합니다.

### 나의 일정 화면
- 로그인한 경우, 자신이 작성한 일정 리스트를 보여주는 화면입니다.
- 로그인 상태가 아니거나, 작성된 일정이 없으면 빈 리스트가 나타납니다.
- 자신이 작성한 일정 리스트이므로 공개 여부 상관 없이 모두 보입니다.
- 일정 리스트에서 하나를 선택하면 일정의 제목, 내용, 작성자, 작성시각, 댓글이 나타나는 화면으로 이동합니다.
- 일정 하단에 댓글 작성이 가능하고 본인 댓글의 삭제가 가능합니다.

#### * 메인 화면, 소셜 화면, 나의 일정 화면은 하단 탭을 통해 이동 가능합니다.

### 시연 영상
https://youtu.be/VJgwYH0VAXs
