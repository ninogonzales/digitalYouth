class CreateReferenceRedirections < ActiveRecord::Migration
  def change
    create_table :reference_redirections do |t|
      t.string  :reference_url

      t.references :user
      t.timestamps null: false
    end
    add_index :reference_redirections, :reference_url, unique: true
  end
end
