class Document < ApplicationRecord
  belongs_to :author, class_name: 'User'
  has_one :approval_workflow, dependent: :destroy
  has_many :approvals, dependent: :destroy
  
  validates :title, presence: true, length: { maximum: 200 }
  validates :content, presence: true
  validates :document_type, presence: true
  validates :department, presence: true
  validates :security_level, inclusion: { in: %w[normal confidential secret top_secret] }
  validates :status, presence: true
  validates :version, presence: true, numericality: { greater_than: 0 }
  
  enum :document_type, {
    leave_request: 'leave_request',         # 휴가신청서
    business_trip: 'business_trip',         # 출장신청서
    purchase_request: 'purchase_request',   # 구매요청서
    work_report: 'work_report',            # 업무보고서
    meeting_minutes: 'meeting_minutes',     # 회의록
    proposal: 'proposal',                  # 제안서
    personnel_order: 'personnel_order',     # 인사발령
    training_request: 'training_request',   # 교육신청
    facility_request: 'facility_request'    # 시설이용신청
  }
  
  enum :status, {
    draft: 'draft',           # 작성중
    pending: 'pending',       # 결재대기
    approved: 'approved',     # 승인완료
    rejected: 'rejected',     # 반려
    cancelled: 'cancelled'    # 취소
  }
  
  enum :security_level, { 
    normal: 1,      # 일반
    confidential: 2, # 대외비
    secret: 3,      # 비밀
    top_secret: 4   # 극비
  }
  
  scope :by_author, ->(user) { where(author: user) }
  scope :by_department, ->(dept) { where(department: dept) }
  scope :by_type, ->(type) { where(document_type: type) }
  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { order(updated_at: :desc) }
  
  def document_type_text
    case document_type
    when 'leave_request'
      '휴가신청서'
    when 'business_trip'
      '출장신청서'
    when 'purchase_request'
      '구매요청서'
    when 'work_report'
      '업무보고서'
    when 'meeting_minutes'
      '회의록'
    when 'proposal'
      '제안서'
    when 'personnel_order'
      '인사발령'
    when 'training_request'
      '교육신청'
    when 'facility_request'
      '시설이용신청'
    end
  end
  
  def status_text
    case status
    when 'draft'
      '작성중'
    when 'pending'
      '결재대기'
    when 'approved'
      '승인완료'
    when 'rejected'
      '반려'
    when 'cancelled'
      '취소'
    end
  end
  
  def status_color
    case status
    when 'draft'
      'text-gray-600 bg-gray-100'
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
  
  def security_level_text
    case security_level
    when 'normal'
      '일반'
    when 'confidential'
      '대외비'
    when 'secret'
      '비밀'
    when 'top_secret'
      '극비'
    end
  end
  
  def can_edit?(user)
    (author == user && status == 'draft') || user.admin?
  end
  
  def can_view?(user)
    return true if user.admin?
    return true if author == user
    return true if approvals.exists?(approver: user)
    false
  end
  
  def current_approver
    return nil unless status == 'pending'
    approvals.where(status: 'pending').order(:order_index).first&.approver
  end
  
  def approval_progress
    return 0 if approvals.empty?
    completed = approvals.where.not(status: 'pending').count
    total = approvals.count
    (completed.to_f / total * 100).round
  end
end
