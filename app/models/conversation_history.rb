class ConversationHistory < ApplicationRecord
  belongs_to :user
  
  # 메시지 타입 validation
  validates :message_type, inclusion: { in: %w[user ai], message: "must be 'user' or 'ai'" }
  validates :content, presence: true
  validates :persona, presence: true
  validates :timestamp, presence: true
  
  # 페르소나 타입 validation
  validates :persona, inclusion: { 
    in: %w[default doctor nurse manager tech], 
    message: "must be a valid persona" 
  }
  
  # 스코프
  scope :recent, -> { order(timestamp: :desc) }
  scope :by_persona, ->(persona) { where(persona: persona) }
  scope :by_session, ->(session_id) { where(session_id: session_id) }
  scope :user_messages, -> { where(message_type: 'user') }
  scope :ai_messages, -> { where(message_type: 'ai') }
  
  # 사용자별 최근 대화 기록 가져오기 (컨텍스트용)
  def self.recent_context_for_user(user_id, persona = 'default', limit = 10)
    where(user_id: user_id, persona: persona)
      .order(:timestamp)
      .last(limit)
  end
  
  # 세션별 대화 기록
  def self.session_messages(session_id)
    where(session_id: session_id).order(:timestamp)
  end
  
  # 사용자별 통계
  def self.user_stats(user_id)
    where(user_id: user_id).group(:persona).count
  end
end
