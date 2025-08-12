user = User.first

# 시설 1: 내과 진료실
facility1 = Facility.create!(
  name: "내과 진료실 1",
  facility_type: "consultation_room",
  building: "본관",
  floor: 2,
  room_number: "201",
  capacity: 2,
  status: "active",
  manager: user,
  description: "내과 전문의 진료실, 고혈압 및 당뇨 전문"
)

# 시설 2: 수술실
facility2 = Facility.create!(
  name: "수술실 A",
  facility_type: "operating_room",
  building: "본관",
  floor: 3,
  room_number: "301",
  capacity: 5,
  status: "active",
  manager: user,
  description: "복강경 수술 전용 수술실"
)

# 시설 3: 병실
facility3 = Facility.create!(
  name: "일반병실 1병동",
  facility_type: "ward",
  building: "동관",
  floor: 4,
  room_number: "401",
  capacity: 4,
  status: "active",
  manager: user,
  description: "4인실 일반병실"
)

# 시설 4: 영상의학과
facility4 = Facility.create!(
  name: "MRI실",
  facility_type: "radiology",
  building: "본관",
  floor: 1,
  room_number: "101",
  capacity: 3,
  status: "maintenance",
  manager: user,
  description: "3.0T MRI 촬영실, 정기 점검 중"
)

# 시설 5: 응급실
facility5 = Facility.create!(
  name: "응급처치실",
  facility_type: "emergency",
  building: "본관",
  floor: 1,
  room_number: "102",
  capacity: 8,
  status: "active",
  manager: user,
  description: "24시간 응급환자 처치실"
)

puts "시설 데이터가 생성되었습니다!"
puts "시설 1 (내과 진료실): #{facility1.id} - #{facility1.status}"
puts "시설 2 (수술실): #{facility2.id} - #{facility2.status}"
puts "시설 3 (병실): #{facility3.id} - #{facility3.status}"
puts "시설 4 (MRI실): #{facility4.id} - #{facility4.status}"
puts "시설 5 (응급실): #{facility5.id} - #{facility5.status}"

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
  facility: facility4,
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
  facility: facility2,
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
  facility: facility3,
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
  facility: facility3,
  manager: user,
  description: "중환자실용 다기능 전동 침대"
)

puts "\n자산 데이터가 생성되었습니다!"
puts "자산 1 (MRI): #{asset1.id} - #{asset1.status}"
puts "자산 2 (수술현미경): #{asset2.id} - #{asset2.status}"
puts "자산 3 (모니터): #{asset3.id} - #{asset3.status}"
puts "자산 4 (서버): #{asset4.id} - #{asset4.status}"
puts "자산 5 (침대): #{asset5.id} - #{asset5.status}"

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

# 점검/보수 이력 5: 침대 부품교체
maintenance5 = Maintenance.create!(
  asset: asset5,
  maintenance_type: "parts_replacement",
  scheduled_date: Date.current - 5.days,
  status: "overdue",
  description: "모터 부품 교체 및 기능 점검",
  technician: "정정비 (스트라이커 엔지니어)"
)

puts "\n점검/보수 이력이 생성되었습니다!"
puts "점검 1 (MRI): #{maintenance1.id} - #{maintenance1.status}"
puts "점검 2 (수술현미경): #{maintenance2.id} - #{maintenance2.status}"
puts "점검 3 (모니터): #{maintenance3.id} - #{maintenance3.status}"
puts "점검 4 (서버): #{maintenance4.id} - #{maintenance4.status}"
puts "점검 5 (침대): #{maintenance5.id} - #{maintenance5.status}"

puts "\n=== 시설/자산 관리 시스템 샘플 데이터 생성 완료 ==="
puts "총 시설: #{Facility.count}개"
puts "총 자산: #{Asset.count}개"
puts "총 점검이력: #{Maintenance.count}건"