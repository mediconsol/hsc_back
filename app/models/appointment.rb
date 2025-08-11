class Appointment < ApplicationRecord
  belongs_to :patient
  belongs_to :employee, optional: true  # 예약 단계에서는 담당의가 없을 수 있음
  
  # 유효성 검사
  validates :appointment_date, presence: true
  validates :appointment_type, presence: true, inclusion: { 
    in: %w[consultation checkup treatment emergency follow_up vaccination procedure] 
  }
  validates :department, presence: true, inclusion: { 
    in: %w[의료진 간호부 행정부 시설관리] 
  }
  validates :status, inclusion: { 
    in: %w[pending confirmed arrived in_progress completed cancelled no_show] 
  }
  validates :chief_complaint, presence: true, length: { minimum: 5, maximum: 500 }
  
  # 과거 예약은 생성할 수 없음 (응급상황 제외)
  validate :appointment_date_not_in_past, on: :create
  
  # 같은 시간대 중복 예약 방지
  validate :no_duplicate_appointment_time
  
  # 스코프
  scope :pending, -> { where(status: 'pending') }
  scope :confirmed, -> { where(status: 'confirmed') }
  scope :today, -> { where(appointment_date: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :upcoming, -> { where('appointment_date > ?', Time.current) }
  scope :by_department, ->(dept) { where(department: dept) if dept.present? }
  scope :by_date, ->(date) { where(appointment_date: date.beginning_of_day..date.end_of_day) if date.present? }
  scope :by_patient, ->(patient_id) { where(patient_id: patient_id) if patient_id.present? }
  scope :online_requests, -> { where(created_by_patient: true) }
  
  # 정렬
  scope :by_date_asc, -> { order(:appointment_date) }
  scope :by_date_desc, -> { order(appointment_date: :desc) }
  
  # 콜백
  after_initialize :set_defaults
  
  # 예약 유형 텍스트
  def appointment_type_text
    case appointment_type
    when 'consultation' then '진료 상담'
    when 'checkup' then '건강검진'
    when 'treatment' then '치료'
    when 'emergency' then '응급진료'
    when 'follow_up' then '재진'
    when 'vaccination' then '예방접종'
    when 'procedure' then '처치'
    else appointment_type
    end
  end
  
  # 상태 텍스트
  def status_text
    case status
    when 'pending' then '예약 대기'
    when 'confirmed' then '예약 확정'
    when 'arrived' then '내원 완료'
    when 'in_progress' then '진료 중'
    when 'completed' then '진료 완료'
    when 'cancelled' then '예약 취소'
    when 'no_show' then '무단 불참'
    else status
    end
  end
  
  # 상태 색상
  def status_color
    case status
    when 'pending' then 'bg-yellow-100 text-yellow-800'
    when 'confirmed' then 'bg-blue-100 text-blue-800'
    when 'arrived' then 'bg-purple-100 text-purple-800'
    when 'in_progress' then 'bg-indigo-100 text-indigo-800'
    when 'completed' then 'bg-green-100 text-green-800'
    when 'cancelled' then 'bg-gray-100 text-gray-800'
    when 'no_show' then 'bg-red-100 text-red-800'
    else 'bg-gray-100 text-gray-800'
    end
  end
  
  # 예약 날짜/시간 포맷팅
  def formatted_appointment_date
    appointment_date.strftime('%Y년 %m월 %d일 %H:%M')
  end
  
  def formatted_appointment_time
    appointment_date.strftime('%H:%M')
  end
  
  def formatted_appointment_date_short
    appointment_date.strftime('%m/%d %H:%M')
  end
  
  # 예약 상태 체크
  def pending?
    status == 'pending'
  end
  
  def confirmed?
    status == 'confirmed'
  end
  
  def can_cancel?
    %w[pending confirmed].include?(status) && appointment_date > Time.current
  end
  
  def can_confirm?
    status == 'pending'
  end
  
  def can_arrive?
    status == 'confirmed' && appointment_date.to_date == Date.current
  end
  
  # 온라인 예약 여부
  def online_request?
    created_by_patient == true
  end
  
  # 예약까지 남은 시간
  def time_until_appointment
    return nil if appointment_date <= Time.current
    
    diff = appointment_date - Time.current
    days = (diff / 1.day).to_i
    hours = ((diff % 1.day) / 1.hour).to_i
    minutes = ((diff % 1.hour) / 1.minute).to_i
    
    if days > 0
      "#{days}일 #{hours}시간"
    elsif hours > 0
      "#{hours}시간 #{minutes}분"
    else
      "#{minutes}분"
    end
  end
  
  # 예약 요약 정보
  def appointment_summary
    {
      id: id,
      patient_name: patient.name,
      patient_phone: patient.phone,
      appointment_date: formatted_appointment_date,
      appointment_type_text: appointment_type_text,
      department: department,
      status_text: status_text,
      status_color: status_color,
      chief_complaint: chief_complaint,
      doctor_name: employee&.name,
      created_by_patient: online_request?,
      can_confirm: can_confirm?,
      can_cancel: can_cancel?
    }
  end
  
  private
  
  def set_defaults
    self.status ||= 'pending'
    self.created_by_patient ||= false
  end
  
  def appointment_date_not_in_past
    return unless appointment_date.present?
    
    if appointment_date < Time.current && appointment_type != 'emergency'
      errors.add(:appointment_date, '예약 시간은 현재 시간보다 이후여야 합니다')
    end
  end
  
  def no_duplicate_appointment_time
    return unless appointment_date.present? && employee.present?
    
    # 같은 의사, 같은 시간대에 이미 예약이 있는지 확인 (30분 간격)
    time_start = appointment_date - 15.minutes
    time_end = appointment_date + 15.minutes
    
    existing = Appointment.where(employee: employee)
                         .where(appointment_date: time_start..time_end)
                         .where.not(id: id)
                         .where.not(status: %w[cancelled no_show])
    
    if existing.exists?
      errors.add(:appointment_date, '해당 시간대에 이미 예약이 있습니다')
    end
  end
end
