class FamilyHistory < ApplicationRecord
  belongs_to :patient
  
  # 유효성 검사
  validates :relationship, presence: true, inclusion: { 
    in: %w[father mother brother sister grandfather grandmother uncle aunt cousin other] 
  }
  validates :disease_name, presence: true
  
  # 스코프
  scope :by_relationship, ->(rel) { where(relationship: rel) if rel.present? }
  scope :by_disease, ->(name) { where('disease_name ILIKE ?', "%#{name}%") if name.present? }
  
  # 관계 텍스트
  def relationship_text
    case relationship
    when 'father' then '부'
    when 'mother' then '모'
    when 'brother' then '형제'
    when 'sister' then '자매'
    when 'grandfather' then '조부'
    when 'grandmother' then '조모'
    when 'uncle' then '삼촌/외삼촌'
    when 'aunt' then '고모/이모'
    when 'cousin' then '사촌'
    when 'other' then '기타'
    else relationship
    end
  end
  
  # 가족력 요약
  def summary
    "#{relationship_text}: #{disease_name}"
  end
end