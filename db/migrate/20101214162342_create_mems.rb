class CreateMems < ActiveRecord::Migration
  def self.up
    create_table :mems do |t|
      t.float :strength
      t.boolean :status
      t.integer :line_id
      t.timestamp :review_after
      t.timestamps
    end
  end

  def self.down
    drop_table :mems
  end
end
