user = User.first
facilities = Facility.all

# 자산 1: MRI 기기
asset1 = Asset.create!(
  name: "필립스 3.0T MRI",
  asset_type: "medical_equipment",
  category: "diagnostic",
  model: "Philips Achieva dStream",
  serial_number: "MRI001PH2024",
  purchase_date: Date.new(2023, 3, 15),
  purchase_price: 250000000,
  vendor: "필립스 헬스케어",
  warranty_expiry: Date.new(2026, 3, 14),
  status: "maintenance",
  facility: facilities.find_by(facility_type: 'radiology'),
  manager: user,
  description: "고해상도 3.0T MRI 스캐너, 뇌 및 척추 촬영 전문"
)

# 자산 2: 수술용 현미경
asset2 = Asset.create!(
  name: "칼자이스 수술용 현미경",
  asset_type: "medical_equipment",
  category: "surgical",
  model: "ZEISS KINEVO 900",
  serial_number: "SUR002CZ2024",
  purchase_date: Date.new(2024, 1, 10),
  purchase_price: 180000000,
  vendor: "칼자이스",
  warranty_expiry: Date.new(2027, 1, 9),
  status: "active",
  facility: facilities.find_by(facility_type: 'operating_room'),
  manager: user,
  description: "신경외과 및 뇌혈관 수술용 고해상도 현미경"
)

# 자산 3: 환자 모니터
asset3 = Asset.create!(
  name: "필립스 환자 모니터",
  asset_type: "medical_equipment",
  category: "monitoring",
  model: "Philips IntelliVue MX750",
  serial_number: "MON003PH2024",
  purchase_date: Date.new(2024, 2, 20),
  purchase_price: 8500000,
  vendor: "필립스 헬스케어",
  warranty_expiry: Date.new(2027, 2, 19),
  status: "active",
  facility: facilities.find_by(facility_type: 'ward'),
  manager: user,
  description: "중환자실 및 병실용 다중 파라미터 모니터"
)

# 자산 4: 병원 정보 시스템 서버
asset4 = Asset.create!(
  name: "EMR 서버",
  asset_type: "it_equipment",
  category: "server",
  model: "Dell PowerEdge R750",
  serial_number: "IT001DL2024",
  purchase_date: Date.new(2024, 1, 5),
  purchase_price: 15000000,
  vendor: "델 테크놀로지스",
  warranty_expiry: Date.new(2027, 1, 4),
  status: "active",
  facility: nil, # 서버실 (별도 시설)
  manager: user,
  description: "전자의무기록(EMR) 시스템 메인 서버"
)

# 자산 5: 병실 침대
asset5 = Asset.create!(
  name: "전동 병실 침대",
  asset_type: "furniture",
  category: "general",
  model: "Stryker InTouch ICU",
  serial_number: "BED001ST2024",
  purchase_date: Date.new(2024, 3, 1),
  purchase_price: 4500000,
  vendor: "스트라이커",
  warranty_expiry: Date.new(2026, 2, 28),
  status: "active",
  facility: facilities.find_by(facility_type: 'ward'),
  manager: user,
  description: "중환자실용 다기능 전동 침대"
)

# 자산 6: 응급처치 장비
asset6 = Asset.create!(
  name: "자동제세동기 AED",
  asset_type: "medical_equipment",
  category: "therapeutic",
  model: "Philips HeartStart MRx",
  serial_number: "AED001PH2024",
  purchase_date: Date.new(2023, 8, 10),
  purchase_price: 12000000,
  vendor: "필립스 헬스케어",
  warranty_expiry: Date.new(2026, 8, 9),
  status: "active",
  facility: facilities.find_by(facility_type: 'emergency'),
  manager: user,
  description: "응급실 및 병동용 자동제세동기"
)

# 자산 7: 진료용 컴퓨터
asset7 = Asset.create!(
  name: "진료실 컴퓨터",
  asset_type: "it_equipment",
  category: "computer",
  model: "HP EliteDesk 800 G9",
  serial_number: "PC001HP2024",
  purchase_date: Date.new(2024, 2, 1),
  purchase_price: 1200000,
  vendor: "HP",
  warranty_expiry: Date.new(2027, 1, 31),
  status: "active",
  facility: facilities.find_by(facility_type: 'consultation_room'),
  manager: user,
  description: "EMR 접속용 진료실 전용 컴퓨터"
)

# 자산 8: 의료용 냉장고
asset8 = Asset.create!(
  name: "의료용 백신 냉장고",
  asset_type: "medical_equipment",
  category: "general",
  model: "Thermo Fisher TSX Series",
  serial_number: "REF001TF2024",
  purchase_date: Date.new(2023, 12, 15),
  purchase_price: 8500000,
  vendor: "써모 피셔",
  warranty_expiry: Date.new(2026, 12, 14),
  status: "active",
  facility: facilities.find_by(facility_type: 'pharmacy') || facilities.first,
  manager: user,
  description: "백신 및 의약품 보관용 온도조절 냉장고"
)

puts "자산 데이터가 생성되었습니다!"
puts "자산 1 (MRI): #{asset1.id} - #{asset1.status}"
puts "자산 2 (수술현미경): #{asset2.id} - #{asset2.status}"
puts "자산 3 (모니터): #{asset3.id} - #{asset3.status}"
puts "자산 4 (서버): #{asset4.id} - #{asset4.status}"
puts "자산 5 (침대): #{asset5.id} - #{asset5.status}"
puts "자산 6 (AED): #{asset6.id} - #{asset6.status}"
puts "자산 7 (컴퓨터): #{asset7.id} - #{asset7.status}"
puts "자산 8 (냉장고): #{asset8.id} - #{asset8.status}"

# 점검/보수 이력 1: MRI 정기점검
maintenance1 = Maintenance.create!(
  asset: asset1,
  maintenance_type: "routine_inspection",
  scheduled_date: Date.current,
  status: "in_progress",
  description: "분기별 정기점검 및 소프트웨어 업데이트",
  technician: "김기술 (필립스 엔지니어)"
)

# 점검/보수 이력 2: 수술현미경 예방정비
maintenance2 = Maintenance.create!(
  asset: asset2,
  maintenance_type: "preventive",
  scheduled_date: Date.current + 7.days,
  status: "scheduled",
  description: "렌즈 청소 및 광학계 점검",
  technician: "이정비 (칼자이스 엔지니어)"
)

# 점검/보수 이력 3: 모니터 완료된 점검
maintenance3 = Maintenance.create!(
  asset: asset3,
  maintenance_type: "routine_inspection",
  scheduled_date: Date.current - 30.days,
  completed_date: Date.current - 28.days,
  status: "completed",
  cost: 150000,
  description: "센서 교정 및 배터리 교체",
  technician: "박정비 (필립스 엔지니어)",
  notes: "모든 파라미터 정상 확인, 다음 점검 예정일: 3개월 후"
)

# 점검/보수 이력 4: 서버 소프트웨어 업데이트
maintenance4 = Maintenance.create!(
  asset: asset4,
  maintenance_type: "software_update",
  scheduled_date: Date.current + 14.days,
  status: "scheduled",
  description: "보안 패치 및 EMR 시스템 업데이트",
  technician: "최개발 (내부 IT팀)"
)

# 점검/보수 이력 5: 침대 부품교체 (연체됨)
maintenance5 = Maintenance.create!(
  asset: asset5,
  maintenance_type: "parts_replacement",
  scheduled_date: Date.current - 5.days,
  status: "scheduled",
  description: "모터 부품 교체 및 기능 점검",
  technician: "정정비 (스트라이커 엔지니어)"
)

# 점검/보수 이력 6: AED 정기점검
maintenance6 = Maintenance.create!(
  asset: asset6,
  maintenance_type: "routine_inspection",
  scheduled_date: Date.current + 3.days,
  status: "scheduled",
  description: "배터리 및 전극패드 상태 점검",
  technician: "응급실 간호팀"
)

# 점검/보수 이력 7: 컴퓨터 정비 (완료)
maintenance7 = Maintenance.create!(
  asset: asset7,
  maintenance_type: "preventive",
  scheduled_date: Date.current - 15.days,
  completed_date: Date.current - 13.days,
  status: "completed",
  cost: 80000,
  description: "하드웨어 청소 및 소프트웨어 업데이트",
  technician: "IT지원팀",
  notes: "정상 작동 확인, 메모리 업그레이드 완료"
)

# 점검/보수 이력 8: 냉장고 교정
maintenance8 = Maintenance.create!(
  asset: asset8,
  maintenance_type: "calibration",
  scheduled_date: Date.current + 21.days,
  status: "scheduled",
  description: "온도센서 교정 및 알람 시스템 점검",
  technician: "써모피셔 엔지니어"
)

puts "\n점검/보수 이력이 생성되었습니다!"
puts "점검 1 (MRI): #{maintenance1.id} - #{maintenance1.status}"
puts "점검 2 (수술현미경): #{maintenance2.id} - #{maintenance2.status}"
puts "점검 3 (모니터): #{maintenance3.id} - #{maintenance3.status}"
puts "점검 4 (서버): #{maintenance4.id} - #{maintenance4.status}"
puts "점검 5 (침대): #{maintenance5.id} - #{maintenance5.status}"
puts "점검 6 (AED): #{maintenance6.id} - #{maintenance6.status}"
puts "점검 7 (컴퓨터): #{maintenance7.id} - #{maintenance7.status}"
puts "점검 8 (냉장고): #{maintenance8.id} - #{maintenance8.status}"

puts "\n=== 시설/자산 관리 시스템 데이터 생성 완료 ==="
puts "총 시설: #{Facility.count}개"
puts "총 자산: #{Asset.count}개"
puts "총 점검이력: #{Maintenance.count}건"