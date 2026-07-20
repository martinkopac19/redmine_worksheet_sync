class CreateWorksheetSyncRuns < ActiveRecord::Migration[6.1]
  def change
    create_table :worksheet_sync_runs do |t|
      t.string  :source              # 'manual' | 'cron'
      t.date    :date_from
      t.date    :date_to
      t.integer :imported,     default: 0
      t.integer :duplicates,   default: 0   # 'dup' je rezervované AR
      t.integer :no_issue,     default: 0
      t.integer :no_perm,      default: 0
      t.integer :locked,       default: 0
      t.integer :not_matching, default: 0
      t.integer :excluded,     default: 0
      t.integer :failed,       default: 0
      t.integer :error_count,  default: 0   # 'errors' je rezervované AR
      t.timestamps
    end
    add_index :worksheet_sync_runs, :created_at
  end
end
