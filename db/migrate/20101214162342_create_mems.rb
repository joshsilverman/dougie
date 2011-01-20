class CreateMems < ActiveRecord::Migration
  def self.up
    create_table :mems do |t|
      t.float :strength
      t.boolean :status
      t.integer :line_id
      t.integer :user_id
      t.timestamp :review_after
      t.timestamps
    end
    
    add_index :mems, :line_id
    add_index :mems, :user_id
    
  end

  def self.down
    drop_table :mems
    remove_index :mems, :line_id
    remove_index :mems, :user_id
  end
end
