class Expense < ApplicationRecord
  belongs_to :budget, optional: true
  belongs_to :requester, class_name: 'User'
  belongs_to :approver, class_name: 'User', optional: true
  
  validates :title, presence: true, length: { maximum: 255 }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :expense_date, presence: true
  validates :category, presence: true
  validates :department, presence: true
  validates :payment_method, presence: true
  validates :status, presence: true
  
  validate :expense_date_not_future
  validate :budget_allocation_check
  validate :amount_within_budget
  
  enum :payment_method, {
    card: 'card',           # 카드결제
    cash: 'cash',           # 현금결제
    transfer: 'transfer',   # 계좌이체
    check: 'check',         # 수표
    other: 'other'          # 기타
  }
  
  enum :status, {
    pending: 'pending',     # 승인대기
    approved: 'approved',   # 승인완료
    rejected: 'rejected',   # 반려
    paid: 'paid',          # 지급완료
    cancelled: 'cancelled'  # 취소
  }
  
  scope :by_department, ->(dept) { where(department: dept) }
  scope :by_category, ->(cat) { where(category: cat) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_requester, ->(user_id) { where(requester_id: user_id) }
  scope :by_date_range, ->(start_date, end_date) { where(expense_date: start_date..end_date) }
  scope :current_month, -> { where(expense_date: Date.current.beginning_of_month..Date.current.end_of_month) }
  scope :recent, -> { order(expense_date: :desc, created_at: :desc) }
  scope :approved, -> { where(status: [:approved, :paid]) }
  scope :pending_approval, -> { where(status: :pending) }
  
  after_update :update_budget_amount, if: :saved_change_to_status?
  
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
  
  def payment_method_text
    case payment_method
    when 'card' then '카드결제'
    when 'cash' then '현금결제'
    when 'transfer' then '계좌이체'
    when 'check' then '수표'
    when 'other' then '기타'
    end
  end
  
  def status_text
    case status
    when 'pending' then '승인대기'
    when 'approved' then '승인완료'
    when 'rejected' then '반려'
    when 'paid' then '지급완료'
    when 'cancelled' then '취소'
    end
  end
  
  def status_color
    case status
    when 'pending' then 'text-yellow-600 bg-yellow-100'
    when 'approved' then 'text-green-600 bg-green-100'
    when 'rejected' then 'text-red-600 bg-red-100'
    when 'paid' then 'text-blue-600 bg-blue-100'
    when 'cancelled' then 'text-gray-600 bg-gray-100'
    end
  end
  
  def can_approve?(user)
    return false unless pending?
    return true if user.admin?
    return true if user.manager? && requester != user
    false
  end
  
  def can_edit?(user)
    return false if paid?
    return true if user.admin?
    return true if requester == user && pending?
    false
  end
  
  def can_view?(user)
    return true if user.admin?
    return true if requester == user
    return true if approver == user
    # 같은 부서 관리자도 조회 가능
    return true if user.manager? && user.respond_to?(:department) && user.department == department
    false
  end
  
  def approve!(approver_user)
    return false unless can_approve?(approver_user)
    
    transaction do
      update!(status: :approved, approver: approver_user)
      budget&.add_expense(amount) if budget
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end
  
  def reject!(approver_user, reason = nil)
    return false unless can_approve?(approver_user)
    
    self.status = :rejected
    self.approver = approver_user
    self.notes = [notes, "반려사유: #{reason}"].compact.join("\n") if reason.present?
    save!
    true
  rescue ActiveRecord::RecordInvalid
    false
  end
  
  def mark_as_paid!
    return false unless approved?
    update!(status: :paid)
  end
  
  def cancel!
    return false if paid?
    
    transaction do
      if approved? && budget
        budget.subtract_expense(amount)
      end
      update!(status: :cancelled)
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end
  
  def is_urgent?
    return false unless pending?
    expense_date <= Date.current + 3.days
  end
  
  def days_since_request
    (Date.current - created_at.to_date).to_i
  end
  
  def formatted_amount
    "₩#{amount.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end
  
  private
  
  def expense_date_not_future
    return unless expense_date
    
    if expense_date > Date.current
      errors.add(:expense_date, '지출 일자는 미래 날짜일 수 없습니다.')
    end
  end
  
  def budget_allocation_check
    return unless budget_id && category && department
    
    if budget && (budget.category != category || budget.department != department)
      errors.add(:budget, '예산의 부서와 카테고리가 지출 내역과 일치하지 않습니다.')
    end
  end
  
  def amount_within_budget
    return unless budget && amount && pending?
    
    unless budget.can_allocate?(amount)
      errors.add(:amount, '예산 잔액이 부족합니다.')
    end
  end
  
  def update_budget_amount
    return unless budget
    
    case status
    when 'approved'
      if status_previously_was == 'pending'
        budget.add_expense(amount)
      end
    when 'rejected', 'cancelled'
      if ['approved', 'paid'].include?(status_previously_was)
        budget.subtract_expense(amount)
      end
    end
  end
end
