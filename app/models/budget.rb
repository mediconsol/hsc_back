class Budget < ApplicationRecord
  belongs_to :manager, class_name: 'User'
  has_many :expenses, dependent: :restrict_with_error
  
  validates :department, presence: true
  validates :category, presence: true
  validates :fiscal_year, presence: true, 
            numericality: { greater_than: 2020, less_than_or_equal_to: 2030 }
  validates :period_type, presence: true
  validates :allocated_amount, presence: true, 
            numericality: { greater_than: 0 }
  validates :used_amount, presence: true, 
            numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true
  
  validate :used_amount_not_exceed_allocated
  validate :unique_department_category_year
  
  enum :period_type, {
    annual: 'annual',       # 연간
    quarterly: 'quarterly', # 분기별
    monthly: 'monthly'      # 월별
  }
  
  enum :status, {
    active: 'active',       # 활성
    closed: 'closed',       # 마감
    suspended: 'suspended'  # 중단
  }
  
  scope :by_department, ->(dept) { where(department: dept) }
  scope :by_category, ->(cat) { where(category: cat) }
  scope :by_fiscal_year, ->(year) { where(fiscal_year: year) }
  scope :by_status, ->(status) { where(status: status) }
  scope :current_year, -> { where(fiscal_year: Date.current.year) }
  scope :recent, -> { order(fiscal_year: :desc, department: :asc, category: :asc) }
  
  def department_text
    case department
    when 'medical' then '의료진'
    when 'nursing' then '간호부'
    when 'administration' then '행정부'
    when 'it' then 'IT부서'
    when 'facility' then '시설관리'
    when 'finance' then '재무부'
    when 'hr' then '인사부'
    when 'pharmacy' then '약제부'
    when 'laboratory' then '검사실'
    when 'radiology' then '영상의학과'
    else department
    end
  end
  
  def category_text
    case category
    when 'personnel' then '인건비'
    when 'medical_equipment' then '의료장비'
    when 'it_equipment' then 'IT장비'
    when 'facility_management' then '시설관리'
    when 'supplies' then '소모품'
    when 'education' then '교육훈련'
    when 'research' then '연구개발'
    when 'maintenance' then '유지보수'
    when 'utilities' then '공과금'
    when 'marketing' then '마케팅'
    when 'other' then '기타'
    else category
    end
  end
  
  def status_text
    case status
    when 'active' then '활성'
    when 'closed' then '마감'
    when 'suspended' then '중단'
    end
  end
  
  def status_color
    case status
    when 'active' then 'text-green-600 bg-green-100'
    when 'closed' then 'text-gray-600 bg-gray-100'
    when 'suspended' then 'text-red-600 bg-red-100'
    end
  end
  
  def period_type_text
    case period_type
    when 'annual' then '연간'
    when 'quarterly' then '분기별'
    when 'monthly' then '월별'
    end
  end
  
  def remaining_amount
    allocated_amount - used_amount
  end
  
  def usage_percentage
    return 0 if allocated_amount <= 0
    ((used_amount / allocated_amount) * 100).round(2)
  end
  
  def is_over_budget?
    used_amount > allocated_amount
  end
  
  def is_nearly_exhausted?(threshold = 90)
    usage_percentage >= threshold
  end
  
  def can_allocate?(amount)
    remaining_amount >= amount
  end
  
  def add_expense(amount)
    increment!(:used_amount, amount)
  end
  
  def subtract_expense(amount)
    decrement!(:used_amount, amount)
  end
  
  def can_edit?(user)
    return true if user.admin?
    return true if manager == user
    false
  end
  
  def can_view?(user)
    return true if user.admin?
    return true if manager == user
    # 같은 부서 직원도 조회 가능
    return true if user.respond_to?(:department) && user.department == department
    true
  end
  
  private
  
  def used_amount_not_exceed_allocated
    return unless used_amount && allocated_amount
    
    if used_amount < 0
      errors.add(:used_amount, '사용 금액은 0보다 작을 수 없습니다.')
    end
  end
  
  def unique_department_category_year
    existing = Budget.where(
      department: department,
      category: category, 
      fiscal_year: fiscal_year
    ).where.not(id: id)
    
    if existing.exists?
      errors.add(:base, '같은 부서, 카테고리, 회계연도의 예산이 이미 존재합니다.')
    end
  end
end
