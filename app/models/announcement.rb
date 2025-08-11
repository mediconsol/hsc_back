class Announcement < ApplicationRecord
  belongs_to :author, class_name: 'User'
  has_many :announcement_reads, dependent: :destroy
  has_many :read_by_users, through: :announcement_reads, source: :user
  
  validates :title, presence: true, length: { maximum: 200 }
  validates :content, presence: true
  validates :priority, inclusion: { in: [1, 2, 3] } # 1: 긴급, 2: 중요, 3: 일반
  validates :department, presence: true
  validates :view_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :is_pinned, inclusion: { in: [true, false] }
  
  enum :priority, { urgent: 1, important: 2, normal: 3 }
  
  # 기존 scopes
  scope :published, -> { where(is_published: true) }
  scope :by_department, ->(dept) { where(department: dept) }
  scope :recent, -> { order(published_at: :desc) }
  
  # 새로운 검색 및 필터링 scopes
  scope :search, ->(keyword) {
    return all if keyword.blank?
    where("title ILIKE ? OR content ILIKE ?", "%#{keyword}%", "%#{keyword}%")
  }
  
  scope :by_author, ->(author_name) {
    return all if author_name.blank?
    joins(:author).where("users.name ILIKE ?", "%#{author_name}%")
  }
  
  scope :by_date_range, ->(start_date, end_date) {
    return all if start_date.blank? || end_date.blank?
    where(created_at: Date.parse(start_date).beginning_of_day..Date.parse(end_date).end_of_day)
  }
  
  scope :by_priority, ->(priority_level) {
    return all if priority_level.blank?
    where(priority: priority_level)
  }
  
  # 정렬 scopes
  scope :by_priority_order, -> { order(:priority, published_at: :desc) }
  scope :by_view_count, -> { order(view_count: :desc, published_at: :desc) }
  scope :by_latest, -> { order(published_at: :desc) }
  
  # 새로운 scopes (읽음 상태 및 고정 관련)
  scope :pinned, -> { where(is_pinned: true).order(pinned_at: :desc) }
  scope :unpinned, -> { where(is_pinned: false) }
  scope :read_by_user, ->(user) {
    joins(:announcement_reads).where(announcement_reads: { user: user })
  }
  scope :unread_by_user, ->(user) {
    where.not(id: read_by_user(user).select(:id))
  }
  
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
  
  # 조회수 증가 메서드 (읽음 상태도 함께 처리)
  def increment_view_count!(user = nil)
    increment!(:view_count)
    # 사용자가 주어지면 읽음 상태도 기록
    if user
      AnnouncementRead.mark_as_read(self, user)
    end
  end
  
  # 상대적 작성 시간 표시
  def time_ago_text
    time_diff = Time.current - created_at
    
    if time_diff < 1.hour
      "#{(time_diff / 1.minute).to_i}분 전"
    elsif time_diff < 1.day
      "#{(time_diff / 1.hour).to_i}시간 전"
    elsif time_diff < 1.week
      "#{(time_diff / 1.day).to_i}일 전"
    else
      created_at.strftime('%Y-%m-%d')
    end
  end
  
  # 읽음 상태 확인
  def read_by?(user)
    return false unless user
    AnnouncementRead.read_by_user?(self, user)
  end
  
  # 고정 상태 토글
  def toggle_pin!
    if is_pinned?
      update!(is_pinned: false, pinned_at: nil)
    else
      update!(is_pinned: true, pinned_at: Time.current)
    end
  end
  
  # 읽음률 계산 (관리자용)
  def read_percentage
    total_users = User.count
    return 0 if total_users == 0
    
    read_count = announcement_reads.count
    (read_count.to_f / total_users * 100).round(1)
  end
  
  # 읽지 않은 사용자 수
  def unread_count
    User.count - announcement_reads.count
  end
end
