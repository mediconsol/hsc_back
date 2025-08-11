class CheckupResult < ApplicationRecord
  belongs_to :health_checkup
  
  # 유효성 검사
  validates :test_category, presence: true
  validates :test_name, presence: true
  validates :result_status, inclusion: { in: %w[normal warning abnormal pending] }
  
  # 스코프
  scope :by_category, ->(category) { where(test_category: category) if category.present? }
  scope :abnormal, -> { where(result_status: 'abnormal') }
  scope :warning, -> { where(result_status: 'warning') }
  scope :needs_attention, -> { where(result_status: %w[abnormal warning]) }
  
  # 콜백
  after_initialize :set_defaults
  
  # 결과 상태 텍스트
  def result_status_text
    case result_status
    when 'normal' then '정상'
    when 'warning' then '주의'
    when 'abnormal' then '이상'
    when 'pending' then '대기'
    else result_status
    end
  end
  
  # 결과 상태 색상
  def result_status_color
    case result_status
    when 'normal' then 'text-green-600'
    when 'warning' then 'text-yellow-600'
    when 'abnormal' then 'text-red-600'
    when 'pending' then 'text-gray-600'
    else 'text-gray-600'
    end
  end
  
  # 검사 카테고리 텍스트
  def test_category_text
    case test_category
    when 'blood' then '혈액검사'
    when 'urine' then '소변검사'
    when 'imaging' then '영상검사'
    when 'physical' then '신체계측'
    when 'vital' then '생체신호'
    when 'vision' then '시력검사'
    when 'hearing' then '청력검사'
    when 'dental' then '구강검사'
    else test_category
    end
  end
  
  # 범위 초과 여부
  def out_of_range?
    return false unless reference_range.present? && result_value.present?
    
    # 참고치 파싱 (예: "60-100", "<140", ">90")
    if reference_range.include?('-')
      min, max = reference_range.split('-').map(&:to_f)
      value = result_value.to_f
      value < min || value > max
    elsif reference_range.start_with?('<')
      max = reference_range.gsub('<', '').to_f
      result_value.to_f >= max
    elsif reference_range.start_with?('>')
      min = reference_range.gsub('>', '').to_f
      result_value.to_f <= min
    else
      false
    end
  rescue
    false
  end
  
  private
  
  def set_defaults
    self.result_status ||= 'pending'
  end
end