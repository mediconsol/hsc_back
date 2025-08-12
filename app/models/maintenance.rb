class Maintenance < ApplicationRecord
  belongs_to :asset
  
  validates :maintenance_type, presence: true
  validates :scheduled_date, presence: true
  validates :status, presence: true
  validates :cost, numericality: { greater_than: 0 }, allow_blank: true
  validate :completed_date_after_scheduled_date
  
  enum :maintenance_type, {
    routine_inspection: 'routine_inspection',       # 정기점검
    preventive: 'preventive',                       # 예방정비
    corrective: 'corrective',                       # 사후정비
    emergency: 'emergency',                         # 응급수리
    calibration: 'calibration',                     # 교정/보정
    cleaning: 'cleaning',                           # 청소/소독
    software_update: 'software_update',             # 소프트웨어 업데이트
    parts_replacement: 'parts_replacement',         # 부품교체
    warranty_service: 'warranty_service',           # 보증서비스
    upgrade: 'upgrade'                              # 업그레이드
  }
  
  enum :status, {
    scheduled: 'scheduled',          # 예정
    in_progress: 'in_progress',      # 진행중
    completed: 'completed',          # 완료
    cancelled: 'cancelled',          # 취소
    postponed: 'postponed'           # 연기
  }
  
  scope :by_type, ->(type) { where(maintenance_type: type) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_asset, ->(asset_id) { where(asset_id: asset_id) }
  scope :scheduled_for_date, ->(date) { where(scheduled_date: date) }
  scope :overdue, -> { where(status: 'scheduled').where('scheduled_date < ?', Date.current) }
  scope :upcoming, ->(days = 7) { where(status: 'scheduled').where('scheduled_date <= ?', Date.current + days.days) }
  scope :recent, -> { order(scheduled_date: :desc) }
  
  def maintenance_type_text
    case maintenance_type
    when 'routine_inspection' then '정기점검'
    when 'preventive' then '예방정비'
    when 'corrective' then '사후정비'
    when 'emergency' then '응급수리'
    when 'calibration' then '교정/보정'
    when 'cleaning' then '청소/소독'
    when 'software_update' then '소프트웨어 업데이트'
    when 'parts_replacement' then '부품교체'
    when 'warranty_service' then '보증서비스'
    when 'upgrade' then '업그레이드'
    end
  end
  
  def status_text
    case status
    when 'scheduled' then '예정'
    when 'in_progress' then '진행중'
    when 'completed' then '완료'
    when 'cancelled' then '취소'
    when 'postponed' then '연기'
    end
  end
  
  def status_color
    case status
    when 'scheduled' then 'text-blue-600 bg-blue-100'
    when 'in_progress' then 'text-yellow-600 bg-yellow-100'
    when 'completed' then 'text-green-600 bg-green-100'
    when 'cancelled' then 'text-gray-600 bg-gray-100'
    when 'postponed' then 'text-orange-600 bg-orange-100'
    end
  end
  
  def duration_days
    return nil if completed_date.blank? || scheduled_date.blank?
    (completed_date - scheduled_date).to_i
  end
  
  def is_overdue?
    status == 'scheduled' && scheduled_date < Date.current
  end
  
  def overdue?
    is_overdue?
  end
  
  def overdue_days
    return 0 unless is_overdue?
    (Date.current - scheduled_date).to_i
  end
  
  def days_until_due
    return nil if status != 'scheduled'
    (scheduled_date - Date.current).to_i
  end
  
  def can_edit?(user)
    return true if user.admin?
    return true if asset.manager == user
    false
  end
  
  def can_view?(user)
    return true if user.admin?
    return true if asset.manager == user
    true # 기본적으로 모든 사용자가 점검 정보를 볼 수 있음
  end
  
  def can_start?(user)
    status == 'scheduled' && (user.admin? || asset.manager == user)
  end
  
  def can_complete?(user)
    status == 'in_progress' && (user.admin? || asset.manager == user)
  end
  
  private
  
  def completed_date_after_scheduled_date
    return unless completed_date.present? && scheduled_date.present?
    
    if completed_date < scheduled_date
      errors.add(:completed_date, '완료일은 예정일보다 이후여야 합니다.')
    end
  end
end
