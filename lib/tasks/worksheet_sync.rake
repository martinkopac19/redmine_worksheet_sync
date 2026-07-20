namespace :redmine do
  desc 'Import time from Worksheet (ws.previo.cz) for locked days (cron)'
  task worksheet_sync: :environment do
    s = Setting.plugin_redmine_worksheet_sync
    unless s['cron_enabled']
      puts 'worksheet_sync: cron disabled in plugin settings'
      next
    end
    window = (s['cron_window_days'] || 10).to_i
    to = Date.today
    from = to - window
    rep = WorksheetSync::Importer.new(s).run(from: from.to_s, to: to.to_s, lock_check: true)
    WorksheetSyncRun.record!(source: 'cron', date_from: from, date_to: to, report: rep)
    puts "worksheet_sync #{from}..#{to}: " \
         "imported=#{rep[:imported].size} dup=#{rep[:dup].size} " \
         "locked_skipped=#{rep[:locked].size} no_issue=#{rep[:no_issue].size} " \
         "no_perm=#{rep[:no_perm].size} excluded=#{rep[:excluded_type].size} " \
         "not_matching=#{rep[:not_matching].size} failed=#{rep[:failed].size} " \
         "errors=#{rep[:error].size}"
  end
end
