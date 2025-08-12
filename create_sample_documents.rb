user = User.first

# 문서 1: 휴가신청서 (결재 대기 상태)
doc1 = Document.create!(
  title: "2024년 연차휴가 신청서",
  content: "안녕하세요. 아래와 같이 연차휴가를 신청합니다.\n\n기간: 2024년 8월 15일 ~ 2024년 8월 16일 (2일)\n사유: 개인 사정\n\n업무 인수인계는 동료 직원에게 완료하였으며, 긴급상황 시 연락 가능합니다.\n감사합니다.",
  document_type: "leave_request",
  department: "의료진",
  security_level: "normal",
  status: "pending",
  author: user,
  version: 1
)

# 결재선 설정 (1순위: 관리자)
approval1 = Approval.create!(
  document: doc1,
  approver: user, # 테스트를 위해 본인을 결재자로 설정
  status: "pending",
  order_index: 0,
  comments: ""
)

# 문서 2: 업무보고서 (승인 완료 상태)
doc2 = Document.create!(
  title: "7월 월간 업무보고서",
  content: "7월 한 달간의 주요 업무 성과를 보고드립니다.\n\n1. 환자 진료 현황\n- 외래 진료: 150건\n- 입원 환자: 25명\n- 수술: 8건\n\n2. 주요 성과\n- 환자 만족도 95% 달성\n- 의료사고 0건 유지\n- 신규 치료법 도입 성공\n\n3. 차월 계획\n- 의료진 교육 프로그램 실시\n- 장비 점검 및 교체\n- 환자 안전 관리 강화\n\n감사합니다.",
  document_type: "work_report",
  department: "의료진",
  security_level: "confidential",
  status: "approved",
  author: user,
  version: 1
)

# 결재선 설정 (승인 완료)
approval2 = Approval.create!(
  document: doc2,
  approver: user,
  status: "approved",
  order_index: 0,
  comments: "업무 성과가 우수합니다. 승인합니다.",
  approved_at: 1.day.ago
)

# 문서 3: 구매요청서 (작성중 상태)
doc3 = Document.create!(
  title: "의료장비 구매 요청서",
  content: "다음과 같은 의료장비 구매를 요청드립니다.\n\n품목: 디지털 X-ray 촬영기\n모델: SAMSUNG XGEO GR40\n수량: 1대\n예상 가격: 50,000,000원\n\n구매 사유:\n- 기존 장비 노후화로 인한 성능 저하\n- 환자 대기시간 단축 필요\n- 화질 개선으로 진단 정확도 향상\n\n긴급도: 높음\n희망 납기: 2024년 9월 말\n\n담당자: 관리자\n연락처: 02-1234-5678",
  document_type: "purchase_request",
  department: "의료진",
  security_level: "confidential",
  status: "draft",
  author: user,
  version: 1
)

# 문서 4: 출장신청서 (반려 상태)
doc4 = Document.create!(
  title: "의료진 학회 참석 출장신청서",
  content: "대한의사협회 하계 학술대회 참석을 위한 출장을 신청합니다.\n\n출장지: 부산 벡스코\n출장기간: 2024년 8월 20일 ~ 2024년 8월 22일 (3일)\n출장목적: 최신 의료기술 습득 및 네트워킹\n\n예상 비용:\n- 교통비: 300,000원\n- 숙박비: 400,000원\n- 학회 등록비: 200,000원\n- 기타: 100,000원\n총계: 1,000,000원\n\n기대효과:\n- 최신 의료기술 도입\n- 타 병원과의 협력 방안 모색\n- 진료 서비스 품질 향상",
  document_type: "business_trip",
  department: "의료진",
  security_level: "normal",
  status: "rejected",
  author: user,
  version: 1
)

# 결재선 설정 (반려)
approval4 = Approval.create!(
  document: doc4,
  approver: user,
  status: "rejected",
  order_index: 0,
  comments: "예산 부족으로 인해 이번 출장은 반려합니다. 다음 분기에 재신청 바랍니다.",
  approved_at: 2.days.ago
)

# 문서 5: 회의록 (결재 대기 상태 - 다단계 결재)
doc5 = Document.create!(
  title: "2024년 8월 월례회의 회의록",
  content: "일시: 2024년 8월 10일 오전 9시\n장소: 대회의실\n참석자: 의료진 전체 (15명)\n\n안건:\n1. 여름 휴가철 대비 인력 운영 계획\n2. 의료장비 점검 및 교체 계획\n3. 환자 안전 관리 강화 방안\n4. 기타 업무\n\n주요 결정사항:\n1. 휴가철 응급실 24시간 운영 체계 구축\n2. CT 스캔 장비 정기 점검 일정 확정\n3. 환자 안전 교육 프로그램 월 1회 실시\n4. 다음 회의 일정: 2024년 9월 10일\n\n작성자: 관리자\n검토자: 의료팀장",
  document_type: "meeting_minutes",
  department: "의료진",
  security_level: "confidential",
  status: "pending",
  author: user,
  version: 1
)

# 다단계 결재선 설정
approval5_1 = Approval.create!(
  document: doc5,
  approver: user, # 1순위 결재자
  status: "pending",
  order_index: 0,
  comments: ""
)

approval5_2 = Approval.create!(
  document: doc5,
  approver: user, # 2순위 결재자 (테스트를 위해 동일인으로 설정)
  status: "pending",
  order_index: 1,
  comments: ""
)

puts "샘플 문서 데이터가 생성되었습니다!"
puts "문서 1 (휴가신청서): #{doc1.id} - #{doc1.status}"
puts "문서 2 (업무보고서): #{doc2.id} - #{doc2.status}"
puts "문서 3 (구매요청서): #{doc3.id} - #{doc3.status}"
puts "문서 4 (출장신청서): #{doc4.id} - #{doc4.status}"
puts "문서 5 (회의록): #{doc5.id} - #{doc5.status}"