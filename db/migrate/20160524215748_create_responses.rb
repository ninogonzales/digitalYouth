class CreateResponses < ActiveRecord::Migration
  def change
    create_table :responses do |t|
      t.integer :score

      t.references :user
      t.references :question
      t.timestamps null: false
    end
  end
end