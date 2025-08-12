class DepartmentPost < ApplicationRecord
  belongs_to :author, class_name: 'User'
  has_many :comments, dependent: :destroy
  
  validates :title, presence: true, length: { maximum: 200 }
  validates :content, presence: true
  validates :department, presence: true
  validates :category, presence: true
  validates :priority, inclusion: { in: %w[important normal reference] }
  
  enum :category, { 
    work_share: 'work_share',      # 업무공유
    qna: 'qna',                    # 질문답변  
    notice: 'notice',              # 부서공지
    suggestion: 'suggestion'       # 건의사항
  }
  
  enum :priority, { important: 1, normal: 2, reference: 3 }
  
  scope :by_department, ->(dept) { where(department: dept) }
  scope :by_category, ->(cat) { where(category: cat) }
  scope :published, -> { where(is_public: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :popular, -> { order(views_count: :desc) }
  
  def category_text
    case category
    when 'work_share'
      '업무공유'
    when 'qna'
      '질문답변'
    when 'notice'
      '부서공지'
    when 'suggestion'
      '건의사항'
    end
  end
  
  def priority_text
    case priority
    when 'important'
      '중요'
    when 'normal'
      '일반'
    when 'reference'
      '참고'
    end
  end
  
  def priority_color
    case priority
    when 'important'
      'text-red-600 bg-red-100'
    when 'normal'
      'text-blue-600 bg-blue-100'
    when 'reference'
      'text-gray-600 bg-gray-100'
    end
  end
  
  def increment_views!
    increment!(:views_count)
  end
end
