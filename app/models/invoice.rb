class Invoice < ApplicationRecord
  belongs_to :processor, class_name: 'User', optional: true
  
  validates :invoice_number, presence: true, uniqueness: true
  validates :vendor, presence: true, length: { maximum: 255 }
  validates :issue_date, presence: true
  validates :due_date, presence: true
  validates :total_amount, presence: true, numericality: { greater_than: 0 }
  validates :tax_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :net_amount, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true
  
  validate :due_date_after_issue_date
  validate :amounts_consistency
  validate :payment_date_validation
  
  enum :status, {
    received: 'received',     # 접수완료
    reviewing: 'reviewing',   # 검토중
    approved: 'approved',     # 승인완료
    paid: 'paid',            # 지급완료
    rejected: 'rejected',     # 반려
    overdue: 'overdue',      # 연체
    cancelled: 'cancelled'    # 취소
  }
  
  scope :by_vendor, ->(vendor) { where(vendor: vendor) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_date_range, ->(start_date, end_date) { where(issue_date: start_date..end_date) }
  scope :due_soon, ->(days = 7) { where(due_date: Date.current..(Date.current + days.days)) }
  scope :overdue_bills, -> { where('due_date < ? AND status NOT IN (?)', Date.current, ['paid', 'cancelled']) }
  scope :current_month, -> { where(issue_date: Date.current.beginning_of_month..Date.current.end_of_month) }
  scope :recent, -> { order(issue_date: :desc, created_at: :desc) }
  scope :pending_payment, -> { where(status: [:received, :reviewing, :approved]) }
  
  before_save :calculate_net_amount
  after_update :update_overdue_status
  
  def status_text
    case status
    when 'received' then '접수완료'
    when 'reviewing' then '검토중'
    when 'approved' then '승인완료'
    when 'paid' then '지급완료'
    when 'rejected' then '반려'
    when 'overdue' then '연체'
    when 'cancelled' then '취소'
    end
  end
  
  def status_color
    case status
    when 'received' then 'text-blue-600 bg-blue-100'
    when 'reviewing' then 'text-yellow-600 bg-yellow-100'
    when 'approved' then 'text-green-600 bg-green-100'
    when 'paid' then 'text-purple-600 bg-purple-100'
    when 'rejected' then 'text-red-600 bg-red-100'
    when 'overdue' then 'text-red-600 bg-red-200'
    when 'cancelled' then 'text-gray-600 bg-gray-100'
    end
  end
  
  def is_overdue?
    return false if ['paid', 'cancelled'].include?(status)
    due_date < Date.current
  end
  
  def days_until_due
    (due_date - Date.current).to_i
  end
  
  def days_overdue
    return 0 unless is_overdue?
    (Date.current - due_date).to_i
  end
  
  def can_process?(user)
    return true if user.admin?
    return true if user.manager? && ['received', 'reviewing'].include?(status)
    false
  end
  
  def can_edit?(user)
    return false if ['paid', 'cancelled'].include?(status)
    return true if user.admin?
    return true if processor == user && ['received', 'reviewing'].include?(status)
    false
  end
  
  def can_view?(user)
    return true if user.admin?
    return true if processor == user
    return true if user.manager?
    false
  end
  
  def approve!(processor_user)
    return false unless can_process?(processor_user)
    return false unless ['received', 'reviewing'].include?(status)
    
    update!(status: :approved, processor: processor_user)
    true
  rescue ActiveRecord::RecordInvalid
    false
  end
  
  def reject!(processor_user, reason = nil)
    return false unless can_process?(processor_user)
    return false unless ['received', 'reviewing', 'approved'].include?(status)
    
    self.status = :rejected
    self.processor = processor_user
    self.notes = [notes, "반려사유: #{reason}"].compact.join("\n") if reason.present?
    save!
    true
  rescue ActiveRecord::RecordInvalid
    false
  end
  
  def mark_as_paid!(payment_date = Date.current)
    return false unless approved?
    
    update!(status: :paid, payment_date: payment_date)
    true
  rescue ActiveRecord::RecordInvalid
    false
  end
  
  def cancel!
    return false if paid?
    
    update!(status: :cancelled)
    true
  rescue ActiveRecord::RecordInvalid
    false
  end
  
  def start_review!(processor_user)
    return false unless received?
    return false unless can_process?(processor_user)
    
    update!(status: :reviewing, processor: processor_user)
    true
  rescue ActiveRecord::RecordInvalid
    false
  end
  
  def formatted_total_amount
    "₩#{total_amount.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end
  
  def formatted_tax_amount
    "₩#{tax_amount.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end
  
  def formatted_net_amount
    "₩#{net_amount.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end
  
  def tax_rate
    return 0 if total_amount <= 0
    ((tax_amount / total_amount) * 100).round(2)
  end
  
  def is_urgent?
    return false if ['paid', 'cancelled'].include?(status)
    days_until_due <= 3
  end
  
  def processing_days
    return 0 unless processor
    (Date.current - created_at.to_date).to_i
  end
  
  private
  
  def due_date_after_issue_date
    return unless issue_date && due_date
    
    if due_date <= issue_date
      errors.add(:due_date, '지급 기한은 발행일 이후여야 합니다.')
    end
  end
  
  def amounts_consistency
    return unless total_amount && tax_amount && net_amount
    
    expected_net = total_amount - tax_amount
    
    if (net_amount - expected_net).abs > 0.01
      errors.add(:net_amount, '순액이 총액에서 세액을 뺀 값과 일치하지 않습니다.')
    end
  end
  
  def payment_date_validation
    return unless payment_date
    
    if payment_date < issue_date
      errors.add(:payment_date, '지급일은 발행일 이후여야 합니다.')
    end
    
    unless paid?
      errors.add(:payment_date, '지급 완료 상태가 아닌 경우 지급일을 설정할 수 없습니다.')
    end
  end
  
  def calculate_net_amount
    return unless total_amount && tax_amount
    self.net_amount = total_amount - tax_amount
  end
  
  def update_overdue_status
    return if ['paid', 'cancelled'].include?(status)
    
    if is_overdue? && status != 'overdue'
      update_column(:status, 'overdue')
    end
  end
end
