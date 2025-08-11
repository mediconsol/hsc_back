class Employee < ApplicationRecord
  has_many :attendances, dependent: :destroy
  has_many :payrolls, dependent: :destroy
  has_many :leave_requests, dependent: :destroy
  
  validates :name, presence: true, 
            length: { minimum: 2, maximum: 50 },
            format: { with: /\A[가-힣a-zA-Z\s]+\z/, message: "한글, 영문, 공백만 입력 가능합니다" }
  
  validates :department, presence: true, 
            inclusion: { in: %w[의료진 간호부 행정부 시설관리], message: "올바른 부서를 선택하세요" }
  
  validates :position, presence: true, 
            length: { minimum: 2, maximum: 30 }
  
  validates :employment_type, presence: true
  
  validates :hire_date, presence: true
  validate :hire_date_not_future
  
  validates :email, presence: true, 
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "올바른 이메일 형식이 아닙니다" }
  
  validate :debug_email_uniqueness
  
  validates :phone, format: { with: /\A[0-9\-\s()]+\z/, message: "올바른 전화번호 형식이 아닙니다" }, 
            allow_blank: true
  
  validates :salary_type, presence: true
  
  validates :base_salary, numericality: { greater_than: 0, less_than: 100_000_000 }, 
            allow_nil: true
  
  validates :hourly_rate, numericality: { greater_than: 0, less_than: 100_000 }, 
            allow_nil: true
  
  validates :status, presence: true
  
  # 급여 타입에 따른 필수 필드 검증
  validate :salary_fields_consistency
  
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
  
  # 성능 최적화된 스코프들
  scope :active, -> { where(status: 'active') }
  scope :by_department, ->(dept) { where(department: dept) }
  scope :by_employment_type, ->(type) { where(employment_type: type) }
  scope :recent, -> { order(created_at: :desc) }
  scope :with_associations, -> { includes(:attendances, :leave_requests, :payrolls) }
  
  # 통계용 스코프들 (쿼리 최적화)
  scope :active_count, -> { where(status: 'active').count }
  scope :by_department_count, ->(dept) { where(department: dept).count }
  scope :on_leave_count, -> { where(status: 'on_leave').count }
  
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
    Rails.cache.fetch("employee_#{id}_annual_leave_balance_#{Date.current.year}", expires_in: 1.day) do
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
  
  # 통계 데이터 캐싱
  def self.dashboard_stats
    Rails.cache.fetch("employee_dashboard_stats", expires_in: 5.minutes) do
      {
        total: count,
        active: active_count,
        on_leave: on_leave_count,
        by_department: %w[의료진 간호부 행정부 시설관리].map { |dept|
          [dept, by_department_count(dept)]
        }.to_h
      }
    end
  end
  
  # 캐시 무효화
  def clear_cache
    Rails.cache.delete("employee_#{id}_annual_leave_balance_#{Date.current.year}")
    Rails.cache.delete("employee_dashboard_stats")
  end
  
  # 콜백으로 캐시 무효화
  after_save :clear_cache
  after_destroy :clear_cache
  
  private
  
  def debug_email_uniqueness
    return unless email.present?
    
    Rails.logger.info "=== Email Uniqueness Debug ==="
    Rails.logger.info "Current email: #{email}"
    Rails.logger.info "Existing employees with this email: #{Employee.where(email: email).where.not(id: id).count}"
    Rails.logger.info "All emails in DB: #{Employee.pluck(:email)}"
    
    existing = Employee.where('LOWER(email) = LOWER(?)', email).where.not(id: id)
    Rails.logger.info "Case-insensitive match count: #{existing.count}"
    Rails.logger.info "Existing emails (case-insensitive): #{existing.pluck(:email)}"
  end
  
  def hire_date_not_future
    return unless hire_date.present?
    
    if hire_date > Date.current
      errors.add(:hire_date, "미래 날짜는 입력할 수 없습니다")
    end
  end
  
  def salary_fields_consistency
    case salary_type
    when 'monthly'
      if base_salary.blank?
        errors.add(:base_salary, "월급 유형에는 기본급이 필수입니다")
      end
    when 'hourly'
      if hourly_rate.blank?
        errors.add(:hourly_rate, "시급 유형에는 시급이 필수입니다")
      end
    when 'daily'
      if base_salary.blank?
        errors.add(:base_salary, "일급 유형에는 기본급이 필수입니다")
      end
    end
  end
end
