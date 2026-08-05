require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class WorksheetSyncImporterTest < ActiveSupport::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles, :trackers,
           :issue_statuses, :issues, :enumerations, :time_entries,
           :enabled_modules, :projects_trackers

  # Fake klient — nahrádza sieťové volanie na ws.previo.cz
  class FakeClient
    def initialize(entries) = (@entries = entries)
    def worksheets(_emp, _from, _to) = @entries
  end

  ISSUE_ID = 55310  # 5-miestne ID kvôli parseru; issue vytvoríme v setupe

  def setup
    unless Issue.exists?(ISSUE_ID)
      i = Issue.new(project_id: 1, tracker_id: 1, status_id: 1,
                    subject: 'WS target', author_id: 1)
      i.id = ISSUE_ID
      i.save!(validate: false)
    end
  end

  def settings(overrides = {})
    {
      'ws_api_key' => 'x', 'service_user_id' => 1,
      'activity_name' => 'Development', 'cron_enabled' => false,
      'cron_window_days' => 10, 'mapping' => { '99' => 2 }
    }.merge(overrides)
  end

  def entry(id:, title:, duration: 60, date: '2026-06-23', work_type: 'Development')
    { 'id' => id, 'date' => date, 'duration' => duration, 'title' => title,
      'note' => nil, 'employee' => { 'id' => 99 }, 'workTypeName' => work_type }
  end

  def import(entries, **opts)
    WorksheetSync::Importer.new(settings, FakeClient.new(entries))
                           .run(from: '2026-06-01', to: '2026-06-30', **opts)
  end

  def test_imports_tag_with_comment
    rep = nil
    assert_difference 'TimeEntry.count', 1 do
      rep = import([entry(id: 1001, title: "##{ISSUE_ID} Fix login")])
    end
    assert_equal 1, rep[:imported].size
    te = TimeEntry.order(:id).last
    assert_equal ISSUE_ID, te.issue_id
    assert_equal 2, te.user_id
    assert_equal 'Fix login', te.comments
    assert_equal 1.0, te.hours.to_f
    assert_equal 'Development', te.activity.name
  end

  def test_imports_bare_tag_with_empty_comment
    assert_difference 'TimeEntry.count', 1 do
      import([entry(id: 1002, title: "##{ISSUE_ID}")])
    end
    assert_equal '', TimeEntry.order(:id).last.comments.to_s
  end

  def test_is_idempotent
    import([entry(id: 1003, title: "##{ISSUE_ID} once")])
    assert_no_difference 'TimeEntry.count' do
      rep = import([entry(id: 1003, title: "##{ISSUE_ID} once")])
      assert_equal 0, rep[:imported].size
      assert_equal 1, rep[:dup].size
    end
  end

  def test_skips_without_tag
    assert_no_difference 'TimeEntry.count' do
      rep = import([entry(id: 1004, title: 'no tag')])
      assert_equal 1, rep[:not_matching].size
    end
  end

  def test_skips_excluded_work_type
    assert_no_difference 'TimeEntry.count' do
      rep = import([entry(id: 1005, title: "##{ISSUE_ID} x", work_type: 'Sick Leave')])
      assert_equal 1, rep[:excluded_type].size
    end
  end

  def test_skips_missing_issue
    assert_no_difference 'TimeEntry.count' do
      rep = import([entry(id: 1006, title: '#99999 ghost')]) # 5-miestne, neexistujúce
      assert_equal 1, rep[:no_issue].size
    end
  end

  def test_dry_run_writes_nothing
    assert_no_difference 'TimeEntry.count' do
      rep = import([entry(id: 1007, title: "##{ISSUE_ID} preview")], dry_run: true)
      assert_equal 1, rep[:imported].size
    end
  end

  def test_cron_lock_check_skips_unlocked_days
    # dnešný záznam nie je uzamknutý => locked
    today = Date.today
    assert_no_difference 'TimeEntry.count' do
      rep = WorksheetSync::Importer.new(settings, FakeClient.new([entry(id: 1008, title: "##{ISSUE_ID} x", date: today.to_s)]))
                                   .run(from: '2026-06-01', to: today.to_s, lock_check: true, today: today)
      assert_equal 1, rep[:locked].size
    end
  end
end
