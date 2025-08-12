# 예산/재무 시스템 테스트 데이터 생성
puts "🏦 예산/재무 시스템 테스트 데이터 생성 시작..."

# 기존 데이터 정리 (개발 환경에서만)
if Rails.env.development?
  puts "기존 예산/재무 데이터 정리 중..."
  Expense.destroy_all
  Invoice.destroy_all
  Budget.destroy_all
end

# 사용자 데이터가 없다면 기본 사용자 생성
admin_user = User.find_or_create_by(email: 'admin@hospital.com') do |user|
  user.name = '관리자'
  user.password = 'password123'
  user.role = 3 # admin
end

manager_user = User.find_or_create_by(email: 'manager@hospital.com') do |user|
  user.name = '부서 관리자'
  user.password = 'password123'
  user.role = 2 # manager
end

finance_user = User.find_or_create_by(email: 'finance@hospital.com') do |user|
  user.name = '재무 담당자'
  user.password = 'password123'
  user.role = 1 # staff
end

staff_users = []
['김의사', '이간호사', '박행정', 'IT담당자', '시설관리자'].each_with_index do |name, index|
  user = User.find_or_create_by(email: "staff#{index + 1}@hospital.com") do |u|
    u.name = name
    u.password = 'password123'
    u.role = 1 # staff
  end
  staff_users << user
end

# 예산 생성 (2024년 및 2025년)
puts "📊 예산 데이터 생성 중..."

departments = [
  'medical', 'nursing', 'administration', 'it', 'facility',
  'finance', 'hr', 'pharmacy', 'laboratory', 'radiology'
]

categories = [
  'personnel', 'medical_equipment', 'it_equipment', 'facility_management',
  'supplies', 'education', 'research', 'maintenance', 'utilities', 'marketing', 'other'
]

budgets = []

[2024, 2025].each do |year|
  departments.each do |dept|
    # 각 부서마다 주요 카테고리 3-5개 예산 생성
    dept_categories = case dept
    when 'medical'
      ['personnel', 'medical_equipment', 'supplies', 'education']
    when 'nursing'
      ['personnel', 'medical_equipment', 'supplies', 'education']
    when 'administration'
      ['personnel', 'facility_management', 'utilities', 'other']
    when 'it'
      ['personnel', 'it_equipment', 'maintenance', 'education']
    when 'facility'
      ['personnel', 'facility_management', 'maintenance', 'utilities']
    when 'finance'
      ['personnel', 'it_equipment', 'education', 'other']
    when 'hr'
      ['personnel', 'education', 'supplies', 'other']
    when 'pharmacy'
      ['personnel', 'medical_equipment', 'supplies', 'research']
    when 'laboratory'
      ['personnel', 'medical_equipment', 'supplies', 'research']
    when 'radiology'
      ['personnel', 'medical_equipment', 'maintenance', 'supplies']
    end

    dept_categories.each do |category|
      # 예산 금액 설정 (부서와 카테고리에 따라 다름)
      base_amount = case category
      when 'personnel'
        rand(80_000_000..200_000_000) # 인건비는 높음
      when 'medical_equipment'
        rand(30_000_000..100_000_000) # 의료장비도 높음
      when 'it_equipment'
        rand(10_000_000..50_000_000)
      when 'facility_management'
        rand(20_000_000..80_000_000)
      when 'supplies'
        rand(5_000_000..30_000_000)
      when 'education'
        rand(2_000_000..15_000_000)
      when 'research'
        rand(10_000_000..50_000_000)
      when 'maintenance'
        rand(5_000_000..25_000_000)
      when 'utilities'
        rand(15_000_000..40_000_000)
      when 'marketing'
        rand(3_000_000..20_000_000)
      else
        rand(5_000_000..30_000_000)
      end

      # 2024년은 어느 정도 사용된 상태, 2025년은 새로 시작
      used_amount = if year == 2024
        rand(0..(base_amount * 0.8).to_i) # 최대 80% 사용
      else
        rand(0..(base_amount * 0.3).to_i) # 최대 30% 사용 (새해 시작)
      end

      # 상태 결정
      status = if year == 2024 && rand < 0.2
        'closed' # 20% 확률로 마감
      elsif year == 2024 && rand < 0.1
        'suspended' # 10% 확률로 중단
      else
        'active'
      end

      budget = Budget.create!(
        department: dept,
        category: category,
        fiscal_year: year,
        period_type: 'annual',
        allocated_amount: base_amount,
        used_amount: used_amount,
        status: status,
        manager: [admin_user, manager_user, finance_user].sample,
        description: "#{year}년 #{Budget.new(department: dept).department_text} #{Budget.new(category: category).category_text} 예산"
      )
      
      budgets << budget
    end
  end
end

puts "✅ 예산 #{budgets.count}개 생성 완료"

# 지출 생성
puts "💸 지출 데이터 생성 중..."

expenses = []

# 최근 6개월간의 지출 데이터 생성
(0..180).each do |days_ago|
  expense_date = Date.current - days_ago.days
  
  # 하루에 0-3개의 지출 생성
  rand(0..3).times do
    budget = budgets.sample
    
    # 예산 범위 내에서 지출 금액 결정
    max_amount = [budget.remaining_amount, 5_000_000].min
    next if max_amount <= 50_000 # 최소 금액보다 작으면 스킵
    
    amount = rand(50_000..max_amount)
    
    # 지출 제목과 설명 생성
    titles = case budget.category
    when 'personnel'
      ['급여 지급', '상여금 지급', '교육비 지급', '출장비 정산']
    when 'medical_equipment'
      ['CT 스캐너 구매', 'MRI 유지보수', '초음파 장비 임대', '의료기기 소모품']
    when 'it_equipment'
      ['서버 하드웨어 구매', '소프트웨어 라이선스', '네트워크 장비 교체', 'PC 업그레이드']
    when 'facility_management'
      ['건물 보수공사', '청소 용역비', '보안 시설 점검', '엘리베이터 점검']
    when 'supplies'
      ['사무용품 구매', '의료 소모품', '청소용품 구매', '기타 소모품']
    when 'education'
      ['직원 교육 프로그램', '학회 참가비', '온라인 교육 수강료', '도서 구매']
    when 'research'
      ['연구 장비 구매', '연구용 소모품', '학술지 구독료', '연구 외주비']
    when 'maintenance'
      ['장비 점검비', '수리비', '예방 정비', '부품 교체']
    when 'utilities'
      ['전기료', '가스료', '수도료', '통신비']
    when 'marketing'
      ['홍보물 제작', '광고비', '이벤트 비용', '마케팅 대행']
    else
      ['기타 비용', '잡비', '예비비 사용', '기타 운영비']
    end
    
    title = titles.sample
    
    vendors = [
      '삼성전자', 'LG전자', '현대건설', '포스코건설', 'SK텔레콤',
      '메디컬시스템', '한국의료기기', '유니메드', '의료용품상사', '병원물류',
      '오피스디포', '다나와', '컴퓨존', 'IT서비스', '네트워크솔루션',
      '클린서비스', '보안시스템', '교육센터', '연구소', '학회사무국'
    ]
    
    payment_methods = ['card', 'transfer', 'cash', 'check']
    
    # 상태 결정 (날짜에 따라)
    status = if days_ago > 30
      # 30일 이전: 대부분 처리 완료
      ['approved', 'paid', 'paid', 'paid'].sample
    elsif days_ago > 7
      # 7-30일 전: 승인 완료 또는 지급 완료
      ['approved', 'paid', 'paid'].sample
    else
      # 최근 7일: 다양한 상태
      ['pending', 'approved', 'paid', 'rejected'].sample
    end
    
    # 승인자 설정
    approver = if status.in?(['approved', 'paid', 'rejected'])
      [admin_user, manager_user, finance_user].sample
    else
      nil
    end
    
    expense = Expense.create!(
      title: title,
      description: "#{title} - #{budget.department_text} #{budget.category_text}",
      amount: amount,
      expense_date: expense_date,
      category: budget.category,
      department: budget.department,
      vendor: vendors.sample,
      payment_method: payment_methods.sample,
      receipt_number: "R#{rand(100000..999999)}",
      status: status,
      budget: budget,
      requester: staff_users.sample,
      approver: approver,
      # notes 필드는 모델에 없으므로 제거
    )
    
    # 승인된 지출은 예산에 반영
    if expense.status.in?(['approved', 'paid'])
      budget.increment!(:used_amount, amount)
    end
    
    expenses << expense
  end
end

puts "✅ 지출 #{expenses.count}개 생성 완료"

# 청구서 생성
puts "📄 청구서 데이터 생성 중..."

invoices = []

# 최근 3개월간의 청구서 생성
(0..90).each do |days_ago|
  issue_date = Date.current - days_ago.days
  
  # 하루에 0-2개의 청구서 생성
  rand(0..2).times do
    vendors = [
      '삼성메디컬', 'LG헬스케어', '지멘스헬스', 'GE헬스케어', '필립스메디컬',
      '한국전력공사', '서울가스', '한국수자원공사', 'KT', 'SK브로드밴드',
      '현대엘리베이터', '오티스엘리베이터', '한화시스템', '포스코건설',
      '대한의료기기', '메드트로닉', '존슨앤존슨', '바이엘코리아',
      '사무용품마트', '의료소모품', '청소전문업체', '보안업체'
    ]
    
    vendor = vendors.sample
    invoice_number = "INV-#{Date.current.year}-#{rand(1000..9999)}"
    
    # 지급기한은 발행일로부터 15-45일 후
    due_date = issue_date + rand(15..45).days
    
    # 청구서 금액 (50만원 ~ 5천만원)
    total_amount = rand(500_000..50_000_000)
    tax_amount = (total_amount * 0.1).round # 10% 세율
    net_amount = total_amount - tax_amount
    
    # 상태 결정
    status = if days_ago > 60
      # 60일 이전: 대부분 지급 완료
      'paid'
    elsif days_ago > 30
      # 30-60일 전: 승인 완료 또는 지급 완료
      ['approved', 'paid', 'paid'].sample
    elsif due_date < Date.current
      # 지급기한 초과: 연체
      'overdue'
    else
      # 최근: 다양한 상태
      ['received', 'reviewing', 'approved', 'rejected'].sample
    end
    
    # 지급일 설정
    payment_date = if status == 'paid'
      issue_date + rand(10..30).days
    else
      nil
    end
    
    # 처리자 설정
    processor = if status.in?(['reviewing', 'approved', 'paid', 'rejected'])
      [admin_user, manager_user, finance_user].sample
    else
      nil
    end
    
    invoice = Invoice.create!(
      invoice_number: invoice_number,
      vendor: vendor,
      issue_date: issue_date,
      due_date: due_date,
      total_amount: total_amount,
      tax_amount: tax_amount,
      net_amount: net_amount,
      status: status,
      payment_date: payment_date,
      processor: processor,
      notes: case status
      when 'rejected'
        '승인 조건 미충족으로 반려'
      when 'overdue'
        '지급기한 초과 - 긴급 처리 필요'
      else
        "#{vendor} 정기 청구서"
      end
    )
    
    invoices << invoice
  end
end

puts "✅ 청구서 #{invoices.count}개 생성 완료"

# 통계 요약 출력
puts "\n📈 생성된 데이터 요약:"
puts "=" * 50

puts "📊 예산:"
puts "  - 총 예산: #{budgets.count}개"
puts "  - 2024년: #{budgets.count { |b| b.fiscal_year == 2024 }}개"
puts "  - 2025년: #{budgets.count { |b| b.fiscal_year == 2025 }}개"
puts "  - 활성 예산: #{budgets.count { |b| b.status == 'active' }}개"
puts "  - 총 배정 금액: #{budgets.sum(&:allocated_amount).to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}원"

puts "\n💸 지출:"
puts "  - 총 지출: #{expenses.count}개"
puts "  - 승인대기: #{expenses.count { |e| e.status == 'pending' }}개"
puts "  - 승인완료: #{expenses.count { |e| e.status == 'approved' }}개"
puts "  - 지급완료: #{expenses.count { |e| e.status == 'paid' }}개"
puts "  - 반려: #{expenses.count { |e| e.status == 'rejected' }}개"
puts "  - 총 지출 금액: #{expenses.sum(&:amount).to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}원"

puts "\n📄 청구서:"
puts "  - 총 청구서: #{invoices.count}개"
puts "  - 접수완료: #{invoices.count { |i| i.status == 'received' }}개"
puts "  - 검토중: #{invoices.count { |i| i.status == 'reviewing' }}개"
puts "  - 승인완료: #{invoices.count { |i| i.status == 'approved' }}개"
puts "  - 지급완료: #{invoices.count { |i| i.status == 'paid' }}개"
puts "  - 연체: #{invoices.count { |i| i.status == 'overdue' }}개"
puts "  - 총 청구 금액: #{invoices.sum(&:total_amount).to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}원"

puts "\n🏦 예산/재무 시스템 테스트 데이터 생성 완료!"
puts "=" * 50