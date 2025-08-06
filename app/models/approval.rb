class Approval < ApplicationRecord
  belongs_to :document
  belongs_to :approver, class_name: 'User'
  
  validates :status, presence: true
  validates :order_index, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  enum :status, {
    pending: 'pending',     # 결재대기
    approved: 'approved',   # 승인
    rejected: 'rejected',   # 반려
    skipped: 'skipped'      # 건너뜀 (병렬결재에서)
  }
  
  scope :by_approver, ->(user) { where(approver: user) }
  scope :ordered, -> { order(:order_index) }
  scope :completed, -> { where.not(status: 'pending') }
  
  def status_text
    case status
    when 'pending'
      '결재대기'
    when 'approved'
      '승인'
    when 'rejected'
      '반려'
    when 'skipped'
      '건너뜀'
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
    when 'skipped'
      'text-gray-600 bg-gray-100'
    end
  end
  
  def can_approve?(user)
    approver == user && status == 'pending'
  end
end
