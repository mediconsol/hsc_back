class HealthCheckup < ApplicationRecord
  belongs_to :patient
  belongs_to :appointment, optional: true
  belongs_to :assigned_doctor, class_name: 'Employee', optional: true
  has_many :checkup_results, dependent: :destroy
  
  # 유효성 검사
  validates :checkup_date, presence: true
  validates :checkup_type, presence: true, inclusion: { 
    in: %w[basic comprehensive special employment student] 
  }
  validates :status, inclusion: { 
    in: %w[scheduled in_progress completed result_ready delivered cancelled] 
  }
  validates :total_cost, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  
  # 스코프
  scope :recent, -> { order(checkup_date: :desc) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_type, ->(type) { where(checkup_type: type) if type.present? }
  scope :pending_results, -> { where(status: %w[in_progress completed]) }
  scope :today, -> { where(checkup_date: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :this_month, -> { where(checkup_date: Date.current.beginning_of_month..Date.current.end_of_month) }
  
  # 콜백
  after_initialize :set_defaults
  after_update :update_patient_last_checkup_date, if: :saved_change_to_status?
  
  # 검진 유형 텍스트
  def checkup_type_text
    case checkup_type
    when 'basic' then '일반검진'
    when 'comprehensive' then '종합검진'
    when 'special' then '특수검진'
    when 'employment' then '채용검진'
    when 'student' then '학생검진'
    else checkup_type
    end
  end
  
  # 상태 텍스트
  def status_text
    case status
    when 'scheduled' then '예정'
    when 'in_progress' then '진행중'
    when 'completed' then '완료'
    when 'result_ready' then '결과준비'
    when 'delivered' then '결과전달'
    when 'cancelled' then '취소'
    else status
    end
  end
  
  # 상태 색상
  def status_color
    case status
    when 'scheduled' then 'bg-blue-100 text-blue-800'
    when 'in_progress' then 'bg-yellow-100 text-yellow-800'
    when 'completed' then 'bg-green-100 text-green-800'
    when 'result_ready' then 'bg-purple-100 text-purple-800'
    when 'delivered' then 'bg-gray-100 text-gray-800'
    when 'cancelled' then 'bg-red-100 text-red-800'
    else 'bg-gray-100 text-gray-800'
    end
  end
  
  # 이상 소견 개수
  def abnormal_count
    checkup_results.where(result_status: 'abnormal').count
  end
  
  # 주의 소견 개수
  def warning_count
    checkup_results.where(result_status: 'warning').count
  end
  
  # 정상 소견 개수
  def normal_count
    checkup_results.where(result_status: 'normal').count
  end
  
  # 결과 요약
  def result_summary
    {
      total: checkup_results.count,
      normal: normal_count,
      warning: warning_count,
      abnormal: abnormal_count,
      status: overall_status
    }
  end
  
  # 전체 상태 판정
  def overall_status
    return 'abnormal' if abnormal_count > 0
    return 'warning' if warning_count > 0
    return 'normal' if normal_count > 0
    'pending'
  end
  
  # 검진 정보 요약
  def checkup_summary
    {
      id: id,
      patient_name: patient.name,
      patient_number: patient.patient_number,
      checkup_date: checkup_date,
      checkup_type_text: checkup_type_text,
      package_name: package_name,
      status_text: status_text,
      status_color: status_color,
      doctor_name: assigned_doctor&.name,
      result_summary: result_summary,
      total_cost: total_cost,
      insurance_covered: insurance_covered
    }
  end
  
  private
  
  def set_defaults
    self.status ||= 'scheduled'
    self.insurance_covered ||= false
    self.checkup_date ||= Date.current
  end
  
  def update_patient_last_checkup_date
    if status == 'completed' || status == 'result_ready' || status == 'delivered'
      patient.update(last_checkup_date: checkup_date)
    end
  end
end