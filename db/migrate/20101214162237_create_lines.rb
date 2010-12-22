class CreateLines < ActiveRecord::Migration
  def self.up
    create_table :lines do |t|
      t.text :text
      t.integer :document_id
      t.integer :parent_id
      t.timestamps
    end
  end

  def self.down
    drop_table :lines
  end
end
