class CreateDocuments < ActiveRecord::Migration
  def self.up
    create_table :documents do |t|
      t.string :name
      t.text :html
      t.integer :tag_id
      t.integer :user_id
      t.timestamps
    end

    add_index :documents, :tag_id
    add_index :documents, :user_id
  end

  def self.down
    drop_table :documents
  end
end
