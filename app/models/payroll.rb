class Payroll < ApplicationRecord
  belongs_to :employee
  
  # 유효성 검사
  validates :employee_id, presence: true
  validates :pay_period_start, presence: true
  validates :pay_period_end, presence: true
  validates :base_pay, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :overtime_pay, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :night_pay, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :allowances, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :deductions, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :tax, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :net_pay, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  # 급여 상태
  validates :status, inclusion: { in: %w[draft pending approved paid] }
  
  # 인덱스 (중복 방지)
  validates :employee_id, uniqueness: { 
    scope: [:pay_period_start, :pay_period_end], 
    message: "해당 기간에 이미 급여 정보가 존재합니다" 
  }
  
  # 스코프
  scope :by_period, ->(start_date, end_date) { where(pay_period_start: start_date..end_date) }
  scope :by_year, ->(year) { where('EXTRACT(year FROM pay_period_start) = ?', year) }
  scope :by_month, ->(year, month) { where('EXTRACT(year FROM pay_period_start) = ? AND EXTRACT(month FROM pay_period_start) = ?', year, month) }
  scope :current_year, -> { by_year(Date.current.year) }
  scope :current_month, -> { by_month(Date.current.year, Date.current.month) }
  scope :by_status, ->(status) { where(status: status) }
  
  # 콜백
  before_save :calculate_net_pay
  
  # 급여 기간 이름 반환
  def period_name
    return '' unless pay_period_start && pay_period_end
    
    if pay_period_start.year == pay_period_end.year && pay_period_start.month == pay_period_end.month
      "#{pay_period_start.year}년 #{pay_period_start.month}월"
    else
      "#{pay_period_start.strftime('%Y.%m.%d')} ~ #{pay_period_end.strftime('%Y.%m.%d')}"
    end
  end
  
  # 급여 세부 내역
  def salary_breakdown
    {
      base_pay: base_pay || 0,
      overtime_pay: overtime_pay || 0,
      night_pay: night_pay || 0,
      allowances: allowances || 0,
      gross_pay: gross_pay,
      deductions: deductions || 0,
      tax: tax || 0,
      total_deductions: total_deductions,
      net_pay: net_pay || 0
    }
  end
  
  # 총 지급액 (세전)
  def gross_pay
    (base_pay || 0) + (overtime_pay || 0) + (night_pay || 0) + (allowances || 0)
  end
  
  # 총 공제액
  def total_deductions
    (deductions || 0) + (tax || 0)
  end
  
  # 상태 텍스트
  def status_text
    case status
    when 'draft' then '임시저장'
    when 'pending' then '검토중'
    when 'approved' then '승인됨'
    when 'paid' then '지급완료'
    else status
    end
  end
  
  # 상태 색상
  def status_color
    case status
    when 'draft' then 'bg-gray-100 text-gray-800'
    when 'pending' then 'bg-yellow-100 text-yellow-800'
    when 'approved' then 'bg-green-100 text-green-800'
    when 'paid' then 'bg-blue-100 text-blue-800'
    else 'bg-gray-100 text-gray-800'
    end
  end
  
  private
  
  def calculate_net_pay
    self.net_pay = gross_pay - total_deductions
  end
end
