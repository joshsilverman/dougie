class CreateLines < ActiveRecord::Migration
  def self.up
    create_table :lines do |t|
      t.text :text
      t.string :domid
      t.integer :document_id
      t.integer :parent_id
      t.integer :user_id
      t.timestamps
    end

    add_index :lines, :document_id
    add_index :lines, :parent_id
    
    # @note currently there are no queries where user_id would be the only foreign key => not indexed
    #add_index :lines, :user_id
  end

  def self.down
    drop_table :lines
  end
end
