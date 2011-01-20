class CreateLines < ActiveRecord::Migration
  def self.up
    create_table :lines do |t|
      t.text :text
      t.string :domid
      t.integer :document_id
      t.integer :parent_id
      t.timestamps
    end
    
    add_index :lines, :document_id
    add_index :lines, :parent_id
    
  end

  def self.down
    drop_table :lines
    remove_index :lines, :document_id
    remove_index :lines, :parent_id
  end
end
