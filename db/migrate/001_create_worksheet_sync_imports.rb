class CreateWorksheetSyncImports < ActiveRecord::Migration[6.1]
  def change
    create_table :worksheet_sync_imports do |t|
      t.bigint  :ws_entry_id,   null: false
      t.integer :time_entry_id
      t.integer :user_id
      t.date    :spent_on
      t.timestamps
    end
    add_index :worksheet_sync_imports, :ws_entry_id, unique: true
  end
end
