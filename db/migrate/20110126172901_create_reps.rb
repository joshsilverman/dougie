class CreateReps < ActiveRecord::Migration
  def self.up
    create_table :reps do |t|
      t.integer :user_id
      t.integer :mem_id
      t.float :strength
      t.float :confidence

      t.timestamps
    end
  end

  def self.down
    drop_table :reps
  end
end
