class CreateMems < ActiveRecord::Migration
  def self.up
    create_table :mems do |t|
      t.float :strength
      t.integer :line_id
      t.timestamps
    end
  end

  def self.down
    drop_table :mems
  end
end
