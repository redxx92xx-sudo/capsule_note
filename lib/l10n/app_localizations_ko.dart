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
    return '미정리 $count개';
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
  String get emptyCapsulesTitle => '등록된 캡슐 노트가 없습니다';

  @override
  String get emptyCapsulesSubtitle => '하단 버튼을 길게 눌러 생각을 빠르게 기록해보세요';

  @override
  String get saveAsNote => '캡슐 노트 저장';

  @override
  String get voiceConversionDone => '음성 변환 완료';

  @override
  String get capsuleTitleLabel => '캡슐 제목';

  @override
  String get rawTranscriptLabel => '음성 텍스트 내용';

  @override
  String get tagsLabel => '태그 (쉼표로 구분)';

  @override
  String get proUpgradeTitle => 'Capsule PRO 업그레이드';

  @override
  String get proBadge => 'PRO';

  @override
  String get proSubtitle => '무제한 AI 요약 및 완전 무광고 전자잉크 경험';

  @override
  String get proFeature1 => '100% 완전 광고 없는 미니멀 인터페이스';

  @override
  String get proFeature2 => '무제한 AI 음성 요약 및 액션 아이템 추출';

  @override
  String get proFeature3 => '고급 Markdown 및 오디오 데이터 내보내기';

  @override
  String get unlockRewardAd => '광고 시청하고 AI 이용권 +3회 받기';

  @override
  String get upgradeToProButton => 'PRO 평생 이용권 구매 (₩6,600)';

  @override
  String get restorePurchases => '구매 내역 복원';

  @override
  String quotaRemaining(int count) {
    return '오늘의 AI 잔여 횟수: $count회';
  }

  @override
  String get rewardSuccess => '보상 획득 완료: AI 횟수 +3회 추가!';

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
  String get capsuleDetailTitle => '캡슐 상세';

  @override
  String get deleteCapsuleTitle => '캡슐 삭제';

  @override
  String get deleteCapsuleMessage => '이 캡슐 노트를 영구적으로 삭제하시겠습니까?';

  @override
  String get cancel => '취소';

  @override
  String get confirmDelete => '삭제 확인';

  @override
  String get addNewAction => '액션 아이템 추가';

  @override
  String get addActionHint => '할 일 또는 실행 항목 입력...';

  @override
  String get addAction => '추가';

  @override
  String get noActionItemsHint => '액션 항목이 없습니다. + 버튼을 눌러 추가하세요.';

  @override
  String get audioRecordTitle => '음성 녹음 데이터';

  @override
  String get dailyDigestTitle => '오늘의 영감 다이제스트';

  @override
  String get exportModalTitle => '내보내기 형식 선택';

  @override
  String get exportSuccess => '성공적으로 복사되었습니다!';

  @override
  String get speechCleanedBadge => '정제 완료';
}
