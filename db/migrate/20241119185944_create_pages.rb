class CreatePages < ActiveRecord::Migration[7.0]
  def change
    create_table :pages do |t|
      t.string :name
      t.json :content
      t.references :website, null: false, foreign_key: true

      t.timestamps
    end
  end
end
