class Patient < ApplicationRecord
  has_many :appointments, dependent: :destroy
  has_many :health_checkups, dependent: :destroy
  has_many :medical_histories, dependent: :destroy
  has_many :family_histories, dependent: :destroy
  
  # 유효성 검사
  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :birth_date, presence: true
  validates :gender, presence: true, inclusion: { in: %w[male female] }
  validates :phone, presence: true, format: { with: /\A[\d\-\s\+\(\)]+\z/, message: "올바른 전화번호 형식이 아닙니다" }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :insurance_type, inclusion: { in: %w[national employee medical_aid private none] }
  validates :status, inclusion: { in: %w[active inactive blocked] }
  validates :patient_number, uniqueness: true, allow_blank: true
  validates :blood_type, inclusion: { in: %w[A+ A- B+ B- O+ O- AB+ AB-] }, allow_blank: true
  validates :smoking_status, inclusion: { in: %w[never former current] }, allow_blank: true
  validates :drinking_status, inclusion: { in: %w[never occasional regular] }, allow_blank: true
  validates :exercise_status, inclusion: { in: %w[none light moderate regular] }, allow_blank: true
  validates :checkup_cycle, numericality: { in: 1..5 }, allow_blank: true
  
  # 스코프
  scope :active, -> { where(status: 'active') }
  scope :by_name, ->(name) { where('name ILIKE ?', "%#{name}%") if name.present? }
  scope :by_phone, ->(phone) { where('phone LIKE ?', "%#{phone}%") if phone.present? }
  scope :by_patient_number, ->(number) { where('patient_number ILIKE ?', "%#{number}%") if number.present? }
  scope :needs_checkup, -> { where('last_checkup_date < ?', 1.year.ago).or(where(last_checkup_date: nil)) }
  scope :recent_patients, ->(days = 30) { where('created_at > ?', days.days.ago) }
  
  # 콜백
  before_save :normalize_phone
  after_initialize :set_defaults
  before_create :generate_patient_number
  
  # 나이 계산
  def age
    return nil unless birth_date
    
    today = Date.current
    age = today.year - birth_date.year
    age -= 1 if today < birth_date + age.years
    age
  end
  
  # 성별 텍스트
  def gender_text
    case gender
    when 'male' then '남성'
    when 'female' then '여성'
    else gender
    end
  end
  
  # 보험 유형 텍스트
  def insurance_type_text
    case insurance_type
    when 'national' then '건강보험'
    when 'employee' then '직장보험'
    when 'medical_aid' then '의료급여'
    when 'private' then '실손보험'
    when 'none' then '무보험'
    else insurance_type
    end
  end
  
  # 상태 텍스트
  def status_text
    case status
    when 'active' then '활성'
    when 'inactive' then '비활성'
    when 'blocked' then '차단'
    else status
    end
  end
  
  # 상태 색상
  def status_color
    case status
    when 'active' then 'bg-green-100 text-green-800'
    when 'inactive' then 'bg-gray-100 text-gray-800'
    when 'blocked' then 'bg-red-100 text-red-800'
    else 'bg-gray-100 text-gray-800'
    end
  end
  
  # 최근 예약 정보
  def recent_appointments(limit: 5)
    appointments.includes(:employee)
               .order(appointment_date: :desc)
               .limit(limit)
  end
  
  # 다음 예약 정보
  def next_appointment
    appointments.where('appointment_date > ?', Time.current)
               .order(:appointment_date)
               .first
  end
  
  # 환자 정보 요약
  def patient_summary
    {
      id: id,
      patient_number: patient_number,
      name: name,
      age: age,
      gender_text: gender_text,
      phone: phone,
      insurance_type_text: insurance_type_text,
      status_text: status_text,
      last_checkup_date: last_checkup_date,
      next_appointment: next_appointment&.appointment_date,
      needs_checkup: needs_checkup?
    }
  end
  
  # BMI 계산
  def bmi
    return nil unless height && weight && height > 0
    (weight / (height / 100) ** 2).round(1)
  end
  
  # BMI 상태
  def bmi_status
    return nil unless bmi
    case bmi
    when 0..18.4 then '저체중'
    when 18.5..22.9 then '정상'
    when 23..24.9 then '과체중'
    when 25..29.9 then '비만'
    else '고도비만'
    end
  end
  
  # 검진 필요 여부
  def needs_checkup?
    return true if last_checkup_date.nil?
    
    months_since_last = ((Date.current - last_checkup_date) / 30).to_i
    cycle_months = (checkup_cycle || 1) * 12
    
    months_since_last >= cycle_months
  end
  
  # 최근 검진 정보
  def last_checkup
    health_checkups.order(checkup_date: :desc).first
  end
  
  # 흡연 상태 텍스트
  def smoking_status_text
    case smoking_status
    when 'never' then '비흡연'
    when 'former' then '과거흡연'
    when 'current' then '현재흡연'
    else smoking_status
    end
  end
  
  # 음주 상태 텍스트
  def drinking_status_text
    case drinking_status
    when 'never' then '비음주'
    when 'occasional' then '가끔'
    when 'regular' then '자주'
    else drinking_status
    end
  end
  
  # 운동 상태 텍스트
  def exercise_status_text
    case exercise_status
    when 'none' then '안함'
    when 'light' then '가벼운 운동'
    when 'moderate' then '보통'
    when 'regular' then '규칙적'
    else exercise_status
    end
  end
  
  private
  
  def set_defaults
    self.status ||= 'active'
    self.insurance_type ||= 'national'
    self.checkup_cycle ||= 1
  end
  
  def generate_patient_number
    return if patient_number.present?
    
    # P + 연도(2자리) + 월(2자리) + 일련번호(4자리)
    # 예: P2411001
    date_prefix = "P#{Date.current.strftime('%y%m')}"
    last_number = Patient.where('patient_number LIKE ?', "#{date_prefix}%")
                         .order('patient_number DESC')
                         .first&.patient_number
    
    if last_number
      sequence = last_number.last(4).to_i + 1
    else
      sequence = 1
    end
    
    self.patient_number = "#{date_prefix}#{sequence.to_s.rjust(4, '0')}"
  end
  
  def normalize_phone
    return unless phone.present?
    
    # 전화번호 정규화 (숫자만 남기고 하이픈 추가)
    clean_phone = phone.gsub(/[^\d]/, '')
    
    case clean_phone.length
    when 10
      self.phone = "#{clean_phone[0..2]}-#{clean_phone[3..5]}-#{clean_phone[6..9]}"
    when 11
      if clean_phone.start_with?('010')
        self.phone = "#{clean_phone[0..2]}-#{clean_phone[3..6]}-#{clean_phone[7..10]}"
      else
        self.phone = "#{clean_phone[0..2]}-#{clean_phone[3..5]}-#{clean_phone[6..10]}"
      end
    else
      # 정규화할 수 없는 경우 원본 유지
    end
  end
end
