class WorksheetSyncImport < ActiveRecord::Base
  validates :ws_entry_id, presence: true, uniqueness: true
end
