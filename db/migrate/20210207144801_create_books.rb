class CreateBooks < ActiveRecord::Migration[6.1]
  def change
    create_table :books do |t|
      t.string :name
      t.string :author
      t.integer :release
      t.integer :volume

      t.timestamps
    end
  end
end
