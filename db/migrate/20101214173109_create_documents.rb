class CreateDocuments < ActiveRecord::Migration
  def self.up
    create_table :documents do |t|
      t.string :name
      t.text :html
      t.integer :tag_id
      t.timestamps
    end
  end

  def self.down
    drop_table :documents
  end
end
