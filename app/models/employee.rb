class Employee < ApplicationRecord
  has_many :attendances, dependent: :destroy
  has_many :payrolls, dependent: :destroy
  has_many :leave_requests, dependent: :destroy
  
  validates :name, presence: true
  validates :department, presence: true
  validates :position, presence: true
  validates :employment_type, presence: true
  validates :hire_date, presence: true
  validates :email, presence: true, uniqueness: true
  validates :salary_type, presence: true
  validates :status, presence: true
  
  enum :employment_type, {
    full_time: 'full_time',       # 정규직
    contract: 'contract',         # 계약직
    part_time: 'part_time',       # 파트타임
    intern: 'intern'              # 인턴
  }
  
  enum :salary_type, {
    monthly: 'monthly',           # 월급
    hourly: 'hourly',            # 시급
    daily: 'daily'               # 일급
  }
  
  enum :status, {
    active: 'active',            # 재직중
    on_leave: 'on_leave',        # 휴직중
    resigned: 'resigned'         # 퇴사
  }
  
  scope :active, -> { where(status: 'active') }
  scope :by_department, ->(dept) { where(department: dept) }
  scope :by_employment_type, ->(type) { where(employment_type: type) }
  
  def employment_type_text
    case employment_type
    when 'full_time'
      '정규직'
    when 'contract'
      '계약직'
    when 'part_time'
      '파트타임'
    when 'intern'
      '인턴'
    end
  end
  
  def salary_type_text
    case salary_type
    when 'monthly'
      '월급'
    when 'hourly'
      '시급'
    when 'daily'
      '일급'
    end
  end
  
  def status_text
    case status
    when 'active'
      '재직중'
    when 'on_leave'
      '휴직중'
    when 'resigned'
      '퇴사'
    end
  end
  
  def years_of_service
    return 0 unless hire_date
    ((Date.current - hire_date) / 365.25).to_i
  end
  
  def current_month_attendance
    attendances.where(work_date: Date.current.beginning_of_month..Date.current.end_of_month)
  end
  
  def annual_leave_balance
    years = years_of_service
    base_days = 15 # 기본 연차
    additional_days = [years - 1, 10].min # 최대 10일 추가
    total_days = base_days + additional_days
    
    used_days = leave_requests.where(
      leave_type: 'annual',
      status: 'approved',
      start_date: Date.current.beginning_of_year..Date.current.end_of_year
    ).sum(:days_requested)
    
    total_days - used_days
  end
end
