class Comment < ApplicationRecord
  belongs_to :author, class_name: 'User'
  belongs_to :department_post
  belongs_to :parent, class_name: 'Comment', optional: true
  
  has_many :replies, class_name: 'Comment', foreign_key: 'parent_id', dependent: :destroy
  
  validates :content, presence: true, length: { maximum: 1000 }
  
  scope :top_level, -> { where(parent_id: nil) }
  scope :recent, -> { order(created_at: :desc) }
  
  def is_reply?
    parent_id.present?
  end
end
