class WorksheetSyncRun < ActiveRecord::Base
  # Zapíše jeden beh importu (manuál/cron) z reportu importéra.
  def self.record!(source:, date_from:, date_to:, report:)
    create!(
      source:       source.to_s,
      date_from:    date_from,
      date_to:      date_to,
      imported:     report[:imported].size,
      duplicates:   report[:dup].size,
      no_issue:     report[:no_issue].size,
      no_perm:      report[:no_perm].size,
      locked:       report[:locked].size,
      not_matching: report[:not_matching].size,
      excluded:     report[:excluded_type].size,
      failed:       report[:failed].size,
      error_count:  report[:error].size
    )
  end

  CSV_COLUMNS = %w[created_at source date_from date_to imported duplicates no_issue
                   no_perm locked not_matching excluded failed error_count].freeze

  def self.to_csv
    require 'csv'
    CSV.generate(headers: true) do |csv|
      csv << CSV_COLUMNS
      order(created_at: :desc).each do |r|
        csv << CSV_COLUMNS.map { |c| r.public_send(c) }
      end
    end
  end
end
