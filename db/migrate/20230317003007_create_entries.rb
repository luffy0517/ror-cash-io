# CreateEntries class definition
class CreateEntries < ActiveRecord::Migration[7.0]
  def change
    create_table :entries do |t|
      t.string :name
      t.string :description
      t.date :date
      t.decimal :value
      t.belongs_to :user, foreign_key: true

      t.timestamps
    end
  end
end
