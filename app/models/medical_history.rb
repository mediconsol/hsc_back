class MedicalHistory < ApplicationRecord
  belongs_to :patient
  
  # 유효성 검사
  validates :disease_name, presence: true
  validates :treatment_status, inclusion: { 
    in: %w[cured treating observing chronic] 
  }
  
  # 스코프
  scope :active, -> { where(treatment_status: %w[treating observing chronic]) }
  scope :by_disease, ->(name) { where('disease_name ILIKE ?', "%#{name}%") if name.present? }
  scope :recent, -> { order(diagnosis_date: :desc) }
  
  # 콜백
  after_initialize :set_defaults
  
  # 치료 상태 텍스트
  def treatment_status_text
    case treatment_status
    when 'cured' then '완치'
    when 'treating' then '치료중'
    when 'observing' then '관찰중'
    when 'chronic' then '만성'
    else treatment_status
    end
  end
  
  # 치료 상태 색상
  def treatment_status_color
    case treatment_status
    when 'cured' then 'bg-green-100 text-green-800'
    when 'treating' then 'bg-yellow-100 text-yellow-800'
    when 'observing' then 'bg-blue-100 text-blue-800'
    when 'chronic' then 'bg-purple-100 text-purple-800'
    else 'bg-gray-100 text-gray-800'
    end
  end
  
  # 치료 기간 (일)
  def treatment_duration
    return nil unless diagnosis_date
    
    if treatment_status == 'cured' && updated_at
      (updated_at.to_date - diagnosis_date).to_i
    else
      (Date.current - diagnosis_date).to_i
    end
  end
  
  # 치료 기간 텍스트
  def treatment_duration_text
    days = treatment_duration
    return nil unless days
    
    if days < 30
      "#{days}일"
    elsif days < 365
      "#{(days / 30).to_i}개월"
    else
      years = days / 365
      months = (days % 365) / 30
      "#{years}년 #{months}개월"
    end
  end
  
  private
  
  def set_defaults
    self.treatment_status ||= 'treating'
    self.diagnosis_date ||= Date.current
  end
end