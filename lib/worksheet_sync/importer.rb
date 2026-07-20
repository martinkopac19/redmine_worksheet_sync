module WorksheetSync
  # Jadro: fetch → parse → (finality pri cron) → mapovanie → dedup → TimeEntry.
  # Vracia report po kategóriách. Beží in-process, píše len do lokálnej DB.
  class Importer
    # PRESNE 5-miestne číslo tasku na začiatku (mriežka # voliteľná: "#55310" aj
    # "55310"). Pred číslom nesmie byť nič iné ("ID 55310" nezmatchne), číslo musí
    # mať presne 5 číslic ("1234" ani "123456" nezmatchne) a byť ukončené medzerou
    # alebo koncom ("55310foo" nezmatchne). Za ním voliteľný komentár.
    TITLE_RE = /\A\s*#?(\d{5})(?:\s+(.*))?\s*\z/m

    # Work types z Worksheetu, ktoré sa nikdy neimportujú (neproduktívne)
    EXCLUDE_WORK_TYPES = [
      '_holiday', '_reciprocal service', 'bonus', 'ldo', 'sick leave',
      'pension/life insurance', 'public holiday'
    ].freeze

    def initialize(settings = nil, client = nil)
      @s = settings || Setting.plugin_redmine_worksheet_sync
      @mapping      = @s['mapping'] || {}
      @client       = client || Client.new(@s['ws_api_key'])
      @service_user = resolve_service_user
      @activity_nm  = @s['activity_name'].presence || 'Development'
    end

    attr_reader :service_user

    # from/to: 'YYYY-MM-DD'; lock_check: true pre cron (len uzamknuté dni);
    # dry_run: true = náhľad (nič nezapíše).
    def run(from:, to:, lock_check: false, today: Date.today, dry_run: false)
      report = Hash.new { |h, k| h[k] = [] }
      @mapping.each do |emp_id, user_id|
        next if user_id.blank?
        user = User.find_by_id(user_id)
        next unless user
        begin
          entries = @client.worksheets(emp_id, from, to)
        rescue => e
          report[:error] << { emp_id: emp_id, user: user.name, error: e.message }
          next
        end
        entries.each { |entry| process(entry, user, report, lock_check, today, dry_run) }
      end
      report
    end

    private

    def process(e, user, report, lock_check, today, dry_run)
      # neproduktívne work typy ignorujeme úplne
      wt = e['workTypeName'].to_s.strip.downcase
      return (report[:excluded_type] << info(e, user)) if EXCLUDE_WORK_TYPES.include?(wt)

      m = TITLE_RE.match(e['title'].to_s)
      return (report[:not_matching] << info(e, user)) unless m

      issue_id = m[1].to_i
      comment  = (m[2] || '').strip
      date     = e['date'].is_a?(String) ? Date.parse(e['date']) : e['date']
      hours    = (e['duration'].to_f / 60.0).round(2)
      base     = info(e, user).merge(issue_id: issue_id, hours: hours, comment: comment)

      return (report[:zero] << base) if hours <= 0
      return (report[:locked] << base) if lock_check && !locked?(date, today)

      issue = Issue.find_by_id(issue_id)
      return (report[:no_issue] << base) unless issue
      return (report[:dup] << base) if WorksheetSyncImport.exists?(ws_entry_id: e['id'])
      unless user.allowed_to?(:log_time, issue.project)
        return (report[:no_perm] << base.merge(project: issue.project.name))
      end

      activity = project_activity(issue.project)
      return (report[:no_activity] << base) unless activity
      fallback = (activity.name != @activity_nm)

      if dry_run
        return report[:imported] << base.merge(preview: true, project: issue.project.name,
                                               activity: activity.name, activity_fallback: fallback)
      end

      create_entry(e, user, issue, activity, hours, date, comment, base, fallback, report)
    end

    # Zápis odolný voči súbehu: najprv "zámok" (riadok v import logu cez unique
    # index), až potom TimeEntry — celé v transakcii. Dva behy naraz => druhý
    # dostane RecordNotUnique a skončí ako dup, nevznikne duplicitný čas.
    def create_entry(e, user, issue, activity, hours, date, comment, base, fallback, report)
      ActiveRecord::Base.transaction do
        log = WorksheetSyncImport.create!(ws_entry_id: e['id'], user_id: user.id, spent_on: date)
        te = TimeEntry.new(
          project: issue.project, issue: issue, user: user,
          author: (@service_user || user), hours: hours, spent_on: date,
          activity: activity, comments: comment
        )
        te.save!
        log.update!(time_entry_id: te.id)
        report[:imported] << base.merge(time_entry_id: te.id, project: issue.project.name,
                                        activity: activity.name, activity_fallback: fallback)
      end
    rescue ActiveRecord::RecordNotUnique
      report[:dup] << base
    rescue ActiveRecord::RecordInvalid => ex
      report[:failed] << base.merge(error: ex.message)
    end

    def info(e, user)
      { ws_id: e['id'], date: e['date'], hours: (e['duration'].to_f / 60.0).round(2),
        title: e['title'], work_type: e['workTypeName'], user: user&.name }
    end

    def locked?(date, today)
      next_working_day(date) < today
    end

    def next_working_day(d)
      n = d + 1
      n += 1 while n.saturday? || n.sunday?
      n
    end

    def project_activity(project)
      acts = project.activities
      acts.detect { |a| a.name == @activity_nm } || acts.first
    end

    def resolve_service_user
      if @s['service_api_key'].present?
        u = User.find_by_api_key(@s['service_api_key'])
        return u if u
      end
      User.find_by_id(@s['service_user_id'])
    end
  end
end
