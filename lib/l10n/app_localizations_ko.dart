// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '캡슐 노트';

  @override
  String capsulesPending(int count) {
    return '미정리 $count 개';
  }

  @override
  String get pressToRecord => '버튼을 길게 눌러 음성 메모 기록';

  @override
  String get recordingListening => '녹음 중... 손을 떼면 완료';

  @override
  String get tapToRecordHint => '버튼을 길게 눌러 음성을 녹음하세요';

  @override
  String get filterAll => '전체';

  @override
  String get emptyCapsulesTitle => '캡슐 메모가 없습니다';

  @override
  String get emptyCapsulesSubtitle => '하단 버튼을 길게 눌러 언제든 아이디어를 기록하세요';

  @override
  String get saveAsNote => '캡슐 메모로 저장';

  @override
  String get voiceConversionDone => '음성 변환 완료';

  @override
  String get capsuleTitleLabel => '캡슐 제목';

  @override
  String get rawTranscriptLabel => '음성 변환 내용';

  @override
  String get tagsLabel => '태그 (쉼표로 구분)';

  @override
  String get proUpgradeTitle => 'Capsule PRO 로 업그레이드';

  @override
  String get proBadge => 'PRO';

  @override
  String get proSubtitle => '무제한 AI 요약 및 깔끔한 무광고 전자잉크 경험 해제';

  @override
  String get proFeature1 => '100% 깔끔한 무광고 전자잉크 인터페이스';

  @override
  String get proFeature2 => '무제한 AI 음성 요약 및 실행 항목 추출';

  @override
  String get proFeature3 => '고급 Markdown 및 오디오 내보내기';

  @override
  String get unlockRewardAd => '광고 보고 AI 할당량 +3회 받기';

  @override
  String get upgradeToProButton => 'PRO 평생 버전 잠금 해제 (₩2,500)';

  @override
  String get restorePurchases => '구매 내역 복원';

  @override
  String quotaRemaining(int count) {
    return '오늘의 남은 AI 할당량: $count 회';
  }

  @override
  String get rewardSuccess => '보상 획득: AI 할당량 +3회가 추가되었습니다!';

  @override
  String get switchLanguage => '언어 변경';

  @override
  String get darkModeToggle => '다크 모드로 전환';

  @override
  String get lightModeToggle => '라이트 모드로 전환';

  @override
  String get markAsDone => '정리 완료로 표시';

  @override
  String get markAsPending => '미정리로 표시';

  @override
  String get copyMarkdownSuccess => 'Markdown 형식으로 클립보드에 복사되었습니다!';

  @override
  String get capsuleDetailTitle => '메모 상세';

  @override
  String get deleteCapsuleTitle => '캡슐 삭제';

  @override
  String get deleteCapsuleMessage => '이 캡슐 메모를 완전히 삭제하시겠습니까?';

  @override
  String get cancel => '취소';

  @override
  String get confirmDelete => '삭제';

  @override
  String get addNewAction => '실행 항목 추가';

  @override
  String get addActionHint => '할 일 또는 작업 입력...';

  @override
  String get addAction => '추가';

  @override
  String get noActionItemsHint => '실행 항목이 없습니다. + 버튼을 눌러 추가하세요.';

  @override
  String get audioRecordTitle => '음성 녹음 데이터';

  @override
  String get audioFileMissing => '녹음 파일을 찾을 수 없어 재생할 수 없습니다';

  @override
  String get audioOnlySaveHint => '텍스트를 비우고 녹음만 저장할 수 있습니다';

  @override
  String get recordingSavedTitle => '녹음이 완료되었습니다';

  @override
  String get recordingSavedSubtitle => '원본 녹음이 저장되었습니다. 텍스트 변환은 나중에 할 수 있습니다.';

  @override
  String get saveRecordingOnly => '녹음 저장';

  @override
  String get transcribeLater => '나중에 텍스트로 변환';

  @override
  String get transcribeToText => '텍스트로 변환';

  @override
  String get retranscribe => '다시 변환';

  @override
  String get transcribing => '변환 중…';

  @override
  String get transcriptionNotConfigured => '텍스트 변환 서비스가 설정되지 않았습니다';

  @override
  String get transcriptionFailed => '변환에 실패했습니다. 나중에 다시 시도하세요.';

  @override
  String get clearTranscript => '텍스트 지우기';

  @override
  String get audioRecordingDefaultTitle => '음성 녹음 메모';

  @override
  String get noTranscriptYetHint => '아직 텍스트로 변환되지 않았습니다';

  @override
  String get transcriptionPreparing => '준비 중…';

  @override
  String get transcriptionConverting => '오디오 변환 중…';

  @override
  String transcriptionProgress(int percent) {
    return '변환 중 $percent%';
  }

  @override
  String get transcriptionCompleted => '변환 완료';

  @override
  String get transcriptionCancelled => '변환이 취소되었습니다';

  @override
  String get cancelTranscription => '취소';

  @override
  String get runLocalSummary => '로컬 요약 생성';

  @override
  String get transcriptionModelMissing => '기기 내 Whisper 모델을 찾을 수 없습니다';

  @override
  String get dailyDigestTitle => '오늘의 다이제스트';

  @override
  String get exportModalTitle => '내보내기 형식 선택';

  @override
  String get exportSuccess => '클립보드에 복사되었습니다!';

  @override
  String get speechCleanedBadge => '음성 정리 완료';

  @override
  String get navToday => '오늘';

  @override
  String get navCalendar => '캘린더';

  @override
  String get navNotes => '메모';

  @override
  String get navTodos => '할 일';

  @override
  String get todayFocus => '오늘의 포커스';

  @override
  String get todayTodosTitle => '오늘의 할 일';

  @override
  String get overdueTodosTitle => '기한 지남';

  @override
  String get todayNotesTitle => '오늘의 메모';

  @override
  String get addTodo => '할 일 추가';

  @override
  String get editTodo => '할 일 수정';

  @override
  String get saveTodo => '저장';

  @override
  String get todoTitleLabel => '할 일 제목';

  @override
  String get todoTitleRequired => '할 일 제목을 입력하세요';

  @override
  String get todoDescLabel => '상세 내용 및 메모';

  @override
  String get dueDateLabel => '예정 일시';

  @override
  String get priorityLabel => '우선순위';

  @override
  String get priorityLow => '낮음';

  @override
  String get priorityMedium => '보통';

  @override
  String get priorityHigh => '높음';

  @override
  String get priorityUrgent => '긴급';

  @override
  String get enableReminder => '알림 켜기';

  @override
  String get persistentReminder => '완료할 때까지 반복 알림';

  @override
  String get repeatRuleLabel => '반복 규칙';

  @override
  String get repeatNone => '반복 안 함';

  @override
  String get repeatDaily => '매일';

  @override
  String get repeatWeekly => '매주';

  @override
  String get repeatMonthly => '매월';

  @override
  String get filterPending => '미완료';

  @override
  String get filterCompleted => '완료됨';

  @override
  String get filterOverdue => '기한 지남';

  @override
  String get snooze30m => '30분 후 알림';

  @override
  String get snooze1h => '1시간 후 알림';

  @override
  String get snooze3h => '3시간 후 알림';

  @override
  String get snoozeTomorrow => '내일 알림';

  @override
  String get deleteTodoTitle => '할 일 삭제';

  @override
  String get deleteTodoConfirm => '이 할 일을 삭제하시겠습니까?';

  @override
  String get convertToTodo => '할 일로 변환';

  @override
  String get convertAllToTodos => '전체 할 일로 변환';

  @override
  String get backToToday => '오늘로 이동';

  @override
  String get viewMonth => '월';

  @override
  String get viewWeek => '주';

  @override
  String get viewDay => '일';

  @override
  String get settingsTitle => '설정 및 환경설정';

  @override
  String get notificationCheck => '알림 및 알람 권한 확인';
}
