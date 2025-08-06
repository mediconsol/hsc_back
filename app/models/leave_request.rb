class LeaveRequest < ApplicationRecord
  belongs_to :employee
  belongs_to :approver, class_name: 'User', optional: true
  
  validates :leave_type, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :days_requested, presence: true, numericality: { greater_than: 0 }
  validates :reason, presence: true
  validates :status, presence: true
  
  validate :end_date_after_start_date
  validate :sufficient_leave_balance, if: :annual_leave?
  
  enum :leave_type, {
    annual: 'annual',            # 연차
    sick: 'sick',               # 병가
    personal: 'personal',        # 개인사유
    maternity: 'maternity',      # 출산휴가
    paternity: 'paternity',      # 육아휴가
    bereavement: 'bereavement',  # 경조사
    special: 'special'           # 특별휴가
  }
  
  enum :status, {
    pending: 'pending',          # 승인대기
    approved: 'approved',        # 승인
    rejected: 'rejected',        # 반려
    cancelled: 'cancelled'       # 취소
  }
  
  scope :by_employee, ->(employee) { where(employee: employee) }
  scope :by_status, ->(status) { where(status: status) }
  scope :current_year, -> { where(start_date: Date.current.beginning_of_year..Date.current.end_of_year) }
  scope :pending_approval, -> { where(status: 'pending') }
  
  def leave_type_text
    case leave_type
    when 'annual'
      '연차'
    when 'sick'
      '병가'
    when 'personal'
      '개인사유'
    when 'maternity'
      '출산휴가'
    when 'paternity'
      '육아휴가'
    when 'bereavement'
      '경조사'
    when 'special'
      '특별휴가'
    end
  end
  
  def status_text
    case status
    when 'pending'
      '승인대기'
    when 'approved'
      '승인'
    when 'rejected'
      '반려'
    when 'cancelled'
      '취소'
    end
  end
  
  def status_color
    case status
    when 'pending'
      'text-yellow-600 bg-yellow-100'
    when 'approved'
      'text-green-600 bg-green-100'
    when 'rejected'
      'text-red-600 bg-red-100'
    when 'cancelled'
      'text-gray-600 bg-gray-100'
    end
  end
  
  def annual_leave?
    leave_type == 'annual'
  end
  
  def can_cancel?
    pending? && start_date > Date.current
  end
  
  def can_approve?(user)
    pending? && (approver == user || user.admin?)
  end
  
  private
  
  def end_date_after_start_date
    return unless start_date && end_date
    errors.add(:end_date, '종료일은 시작일보다 늦어야 합니다') if end_date < start_date
  end
  
  def sufficient_leave_balance
    return unless annual_leave? && employee
    balance = employee.annual_leave_balance
    errors.add(:days_requested, "잔여 연차가 부족합니다 (잔여: #{balance}일)") if days_requested > balance
  end
end
