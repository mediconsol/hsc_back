class Attendance < ApplicationRecord
  belongs_to :employee
  
  validates :work_date, presence: true, uniqueness: { scope: :employee_id }
  validates :status, presence: true
  
  enum :status, {
    present: 'present',          # 출근
    absent: 'absent',            # 결근
    late: 'late',               # 지각
    early_leave: 'early_leave',  # 조퇴
    holiday: 'holiday',          # 휴일
    leave: 'leave'              # 휴가
  }
  
  scope :this_month, -> { where(work_date: Date.current.beginning_of_month..Date.current.end_of_month) }
  scope :by_status, ->(status) { where(status: status) }
  scope :worked_days, -> { where.not(status: ['absent', 'holiday', 'leave']) }
  
  def status_text
    case status
    when 'present'
      '출근'
    when 'absent'
      '결근'
    when 'late'
      '지각'
    when 'early_leave'
      '조퇴'
    when 'holiday'
      '휴일'
    when 'leave'
      '휴가'
    end
  end
  
  def status_color
    case status
    when 'present'
      'text-green-600 bg-green-100'
    when 'absent'
      'text-red-600 bg-red-100'
    when 'late'
      'text-yellow-600 bg-yellow-100'
    when 'early_leave'
      'text-orange-600 bg-orange-100'
    when 'holiday'
      'text-blue-600 bg-blue-100'
    when 'leave'
      'text-purple-600 bg-purple-100'
    end
  end
  
  def total_hours
    return 0 unless check_in && check_out
    (check_out - check_in) / 1.hour
  end
  
  def calculate_hours!
    return unless check_in && check_out
    
    total = total_hours
    self.regular_hours = [total, 8].min
    self.overtime_hours = [total - 8, 0].max
    
    # 야간 근무 시간 계산 (22:00 - 06:00)
    night_start = check_in.beginning_of_day + 22.hours
    night_end = check_in.beginning_of_day + 30.hours # 다음날 06:00
    
    night_work_start = [check_in, night_start].max
    night_work_end = [check_out, night_end].min
    
    if night_work_start < night_work_end
      self.night_hours = (night_work_end - night_work_start) / 1.hour
    else
      self.night_hours = 0
    end
    
    save!
  end
  
  def is_late?
    return false unless check_in
    standard_time = work_date.beginning_of_day + 9.hours # 09:00 기준
    check_in > standard_time
  end
  
  def is_early_leave?
    return false unless check_out
    standard_time = work_date.beginning_of_day + 18.hours # 18:00 기준
    check_out < standard_time
  end
end
