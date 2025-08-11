class CreateAnnouncementReads < ActiveRecord::Migration[8.0]
  def change
    create_table :announcement_reads do |t|
      t.references :announcement, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :read_at

      t.timestamps
    end
    
    # 동일한 사용자가 같은 공지사항을 중복 읽음 처리하지 않도록 유니크 제약
    add_index :announcement_reads, [:announcement_id, :user_id], unique: true
  end
end
