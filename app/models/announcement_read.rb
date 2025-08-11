class AnnouncementRead < ApplicationRecord
  belongs_to :announcement
  belongs_to :user
  
  validates :announcement_id, uniqueness: { scope: :user_id }
  validates :read_at, presence: true
  
  # 읽음 상태를 기록하는 클래스 메서드
  def self.mark_as_read(announcement, user)
    find_or_create_by(announcement: announcement, user: user) do |read|
      read.read_at = Time.current
    end
  end
  
  # 특정 사용자의 읽음 상태 확인
  def self.read_by_user?(announcement, user)
    exists?(announcement: announcement, user: user)
  end
end
