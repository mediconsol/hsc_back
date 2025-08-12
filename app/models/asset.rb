class Asset < ApplicationRecord
  belongs_to :facility, optional: true
  belongs_to :manager, class_name: 'User', optional: true
  has_many :maintenances, dependent: :destroy
  
  validates :name, presence: true, length: { maximum: 200 }
  validates :asset_type, presence: true
  validates :serial_number, presence: true, uniqueness: true
  validates :status, presence: true
  validates :purchase_price, numericality: { greater_than: 0 }, allow_blank: true
  
  enum :asset_type, {
    medical_equipment: 'medical_equipment',     # 의료장비
    it_equipment: 'it_equipment',               # IT장비
    furniture: 'furniture',                     # 가구
    vehicle: 'vehicle',                         # 차량
    building_equipment: 'building_equipment',   # 건물설비
    safety_equipment: 'safety_equipment',       # 안전장비
    office_equipment: 'office_equipment',       # 사무용품
    cleaning_equipment: 'cleaning_equipment',   # 청소장비
    kitchen_equipment: 'kitchen_equipment',     # 주방장비
    other: 'other'                             # 기타
  }
  
  enum :category, {
    # 의료장비 세부 카테고리
    diagnostic: 'diagnostic',           # 진단장비
    therapeutic: 'therapeutic',         # 치료장비
    monitoring: 'monitoring',           # 모니터링
    surgical: 'surgical',               # 수술장비
    
    # IT장비 세부 카테고리
    computer: 'computer',               # 컴퓨터
    server: 'server',                   # 서버
    network: 'network',                 # 네트워크
    printer: 'printer',                 # 프린터
    
    # 기타 카테고리
    general: 'general'                  # 일반
  }, suffix: true
  
  enum :status, {
    active: 'active',              # 정상 사용중
    inactive: 'inactive',          # 비사용
    maintenance: 'maintenance',     # 점검중
    repair: 'repair',              # 수리중
    broken: 'broken',              # 고장
    disposed: 'disposed'           # 폐기
  }
  
  scope :by_type, ->(type) { where(asset_type: type) }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_facility, ->(facility_id) { where(facility_id: facility_id) }
  scope :active, -> { where(status: 'active') }
  scope :warranty_expiring, ->(days = 30) { where('warranty_expiry <= ?', Date.current + days.days) }
  scope :recent, -> { order(updated_at: :desc) }
  
  def asset_type_text
    case asset_type
    when 'medical_equipment' then '의료장비'
    when 'it_equipment' then 'IT장비'
    when 'furniture' then '가구'
    when 'vehicle' then '차량'
    when 'building_equipment' then '건물설비'
    when 'safety_equipment' then '안전장비'
    when 'office_equipment' then '사무용품'
    when 'cleaning_equipment' then '청소장비'
    when 'kitchen_equipment' then '주방장비'
    when 'other' then '기타'
    end
  end
  
  def category_text
    case category
    when 'diagnostic' then '진단장비'
    when 'therapeutic' then '치료장비'
    when 'monitoring' then '모니터링'
    when 'surgical' then '수술장비'
    when 'computer' then '컴퓨터'
    when 'server' then '서버'
    when 'network' then '네트워크'
    when 'printer' then '프린터'
    when 'general' then '일반'
    end
  end
  
  def status_text
    case status
    when 'active' then '정상'
    when 'inactive' then '비사용'
    when 'maintenance' then '점검중'
    when 'repair' then '수리중'
    when 'broken' then '고장'
    when 'disposed' then '폐기'
    end
  end
  
  def status_color
    case status
    when 'active' then 'text-green-600 bg-green-100'
    when 'inactive' then 'text-gray-600 bg-gray-100'
    when 'maintenance' then 'text-yellow-600 bg-yellow-100'
    when 'repair' then 'text-orange-600 bg-orange-100'
    when 'broken' then 'text-red-600 bg-red-100'
    when 'disposed' then 'text-gray-800 bg-gray-200'
    end
  end
  
  def warranty_status
    return '보증기간 없음' if warranty_expiry.blank?
    
    days_remaining = (warranty_expiry - Date.current).to_i
    
    if days_remaining < 0
      '보증기간 만료'
    elsif days_remaining <= 30
      "보증기간 #{days_remaining}일 남음"
    else
      "보증기간 유효"
    end
  end
  
  def warranty_color
    return 'text-gray-600 bg-gray-100' if warranty_expiry.blank?
    
    days_remaining = (warranty_expiry - Date.current).to_i
    
    if days_remaining < 0
      'text-red-600 bg-red-100'
    elsif days_remaining <= 30
      'text-yellow-600 bg-yellow-100'
    else
      'text-green-600 bg-green-100'
    end
  end
  
  def depreciation_value(method = 'straight_line', useful_years = 5)
    return 0 if purchase_price.blank? || purchase_date.blank?
    
    case method
    when 'straight_line'
      # 정액법
      years_passed = [(Date.current - purchase_date).to_i / 365.0, useful_years].min
      annual_depreciation = purchase_price / useful_years
      current_value = purchase_price - (annual_depreciation * years_passed)
      [current_value, 0].max.round(2)
    else
      purchase_price
    end
  end
  
  def can_edit?(user)
    return true if user.admin?
    return true if manager == user
    false
  end
  
  def can_view?(user)
    return true if user.admin?
    return true if manager == user
    true # 기본적으로 모든 사용자가 자산 정보를 볼 수 있음
  end
  
  def requires_maintenance?
    last_maintenance = maintenances.where(status: 'completed').order(:completed_date).last
    return true if last_maintenance.blank?
    
    # 마지막 점검으로부터 6개월이 지났으면 점검 필요
    (Date.current - last_maintenance.completed_date).to_i > 180
  end
end
