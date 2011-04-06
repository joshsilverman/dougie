class RemoveTextFromLines < ActiveRecord::Migration
  def self.up
    remove_column :lines, :text
  end

  def self.down
    add_column :lines, :text, :text
  end
end
