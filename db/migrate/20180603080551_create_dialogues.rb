class CreateDialogues < ActiveRecord::Migration[5.1]
  def change
    create_table :dialogues do |t|
      t.string  :user_name
      t.string  :mode
      t.integer  :da
      t.string  :context
      t.integer :t
      t.timestamps
    end
  end
end
