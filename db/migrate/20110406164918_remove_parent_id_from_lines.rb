class RemoveParentIdFromLines < ActiveRecord::Migration
  def self.up
    remove_column :lines, :parent_id
  end

  def self.down
    add_column :lines, :parent_id, :int
  end
end
