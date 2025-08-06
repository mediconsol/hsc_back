class Announcement < ApplicationRecord
  belongs_to :author, class_name: 'User'
  
  validates :title, presence: true, length: { maximum: 200 }
  validates :content, presence: true
  validates :priority, inclusion: { in: [1, 2, 3] } # 1: 긴급, 2: 중요, 3: 일반
  validates :department, presence: true
  
  enum :priority, { urgent: 1, important: 2, normal: 3 }
  
  scope :published, -> { where(is_published: true) }
  scope :by_department, ->(dept) { where(department: dept) }
  scope :recent, -> { order(published_at: :desc) }
  
  def priority_text
    case priority
    when 'urgent'
      '긴급'
    when 'important' 
      '중요'
    when 'normal'
      '일반'
    end
  end
  
  def priority_color
    case priority
    when 'urgent'
      'text-red-600 bg-red-100'
    when 'important'
      'text-orange-600 bg-orange-100'
    when 'normal'
      'text-blue-600 bg-blue-100'
    end
  end
end
