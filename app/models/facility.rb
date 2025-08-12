class Facility < ApplicationRecord
  belongs_to :manager, class_name: 'User', optional: true
  has_many :assets, dependent: :destroy
  
  validates :name, presence: true, length: { maximum: 200 }
  validates :facility_type, presence: true
  validates :status, presence: true
  validates :capacity, numericality: { greater_than: 0 }, allow_blank: true
  validates :floor, numericality: { greater_than_or_equal_to: -5, less_than_or_equal_to: 50 }, allow_blank: true
  
  enum :facility_type, {
    ward: 'ward',                    # 병실
    operating_room: 'operating_room', # 수술실
    examination_room: 'examination_room', # 검사실
    consultation_room: 'consultation_room', # 진료실
    office: 'office',                # 사무실
    meeting_room: 'meeting_room',    # 회의실
    storage: 'storage',              # 창고
    pharmacy: 'pharmacy',            # 약국
    laboratory: 'laboratory',        # 실험실
    radiology: 'radiology',          # 영상의학과
    emergency: 'emergency',          # 응급실
    icu: 'icu',                     # 중환자실
    cafeteria: 'cafeteria',         # 식당
    parking: 'parking',             # 주차장
    other: 'other'                  # 기타
  }
  
  enum :status, {
    active: 'active',          # 사용중
    inactive: 'inactive',      # 비사용
    maintenance: 'maintenance', # 점검중
    repair: 'repair',          # 수리중
    closed: 'closed'           # 폐쇄
  }
  
  scope :by_type, ->(type) { where(facility_type: type) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_building, ->(building) { where(building: building) }
  scope :by_floor, ->(floor) { where(floor: floor) }
  scope :active, -> { where(status: 'active') }
  scope :recent, -> { order(updated_at: :desc) }
  
  def facility_type_text
    case facility_type
    when 'ward' then '병실'
    when 'operating_room' then '수술실'
    when 'examination_room' then '검사실'
    when 'consultation_room' then '진료실'
    when 'office' then '사무실'
    when 'meeting_room' then '회의실'
    when 'storage' then '창고'
    when 'pharmacy' then '약국'
    when 'laboratory' then '실험실'
    when 'radiology' then '영상의학과'
    when 'emergency' then '응급실'
    when 'icu' then '중환자실'
    when 'cafeteria' then '식당'
    when 'parking' then '주차장'
    when 'other' then '기타'
    end
  end
  
  def status_text
    case status
    when 'active' then '사용중'
    when 'inactive' then '비사용'
    when 'maintenance' then '점검중'
    when 'repair' then '수리중'
    when 'closed' then '폐쇄'
    end
  end
  
  def status_color
    case status
    when 'active' then 'text-green-600 bg-green-100'
    when 'inactive' then 'text-gray-600 bg-gray-100'
    when 'maintenance' then 'text-yellow-600 bg-yellow-100'
    when 'repair' then 'text-orange-600 bg-orange-100'
    when 'closed' then 'text-red-600 bg-red-100'
    end
  end
  
  def full_location
    parts = []
    parts << building if building.present?
    parts << "#{floor}층" if floor.present?
    parts << room_number if room_number.present?
    parts.join(' ')
  end
  
  def can_edit?(user)
    return true if user.admin?
    return true if manager == user
    false
  end
  
  def can_view?(user)
    return true if user.admin?
    return true if manager == user
    true # 기본적으로 모든 사용자가 시설 정보를 볼 수 있음
  end
end
