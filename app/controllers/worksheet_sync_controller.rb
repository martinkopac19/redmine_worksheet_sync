class WorksheetSyncController < ApplicationController
  before_action :require_admin
  layout 'admin'

  def show
    load_config
    load_employees
    build_suggestions
  end

  def update
    s = current_settings
    # Polia na kľúče sa renderujú vždy prázdne, aby kľúč nebol v HTML zdroji
    # (viď komentár v show.html.erb). Prázdna hodnota preto znamená "nechaj
    # existujúci kľúč", nie "zmaž" — na zmazanie je samostatný checkbox.
    s['ws_api_key']       = merged_key(s['ws_api_key'], :ws_api_key, :ws_api_key_clear)
    s['service_user_id']  = params[:service_user_id].presence
    # Autor záznamov sa vyberá výhradne rozbaľovačkou. Voľba „…alebo API kľúč
    # servisného účtu" bola zrušená, uloženú hodnotu tu preto zahadzujeme.
    s.delete('service_api_key')
    s['activity_name']    = params[:activity_name].presence || 'Development'
    s['cron_enabled']     = params[:cron_enabled] == '1'
    s['cron_window_days'] = params[:cron_window_days].presence&.to_i || 10
    s['mapping']          = parse_mapping(params[:mapping])
    Setting.plugin_redmine_worksheet_sync = s
    flash[:notice] = l(:notice_successful_update)
    redirect_to action: 'show'
  end

  # Prázdne pole = ponechaj uložený kľúč; zaškrtnutý clear = zmaž.
  def merged_key(current, field, clear_field)
    return '' if params[clear_field].to_s == '1'

    submitted = params[field].to_s.strip
    submitted.presence || current.to_s
  end
  private :merged_key

  def run
    from = params[:from].presence || (Date.today - 14).to_s
    to   = params[:to].presence || Date.today.to_s
    dry  = params[:commit_import].blank?
    importer = WorksheetSync::Importer.new
    @report = importer.run(from: from, to: to, dry_run: dry)
    unless dry
      WorksheetSyncRun.record!(source: 'manual', date_from: from, date_to: to, report: @report)
    end
    @ran = dry ? :preview : :import
    @from = from
    @to = to
    load_config
    load_employees
    build_suggestions
    render :show
  end

  def runs_csv
    send_data WorksheetSyncRun.to_csv,
              type: 'text/csv; charset=utf-8',
              filename: "worksheet_sync_runs_#{Date.today}.csv"
  end

  private

  def build_suggestions
    @suggested = {}
    return unless @employees
    utok = @users.map { |u| [u.id, name_tokens("#{u.firstname} #{u.lastname}")] }
    @employees.each do |e|
      et = name_tokens(e['name'])
      next if et.empty?
      best = utok.map { |id, t| [id, (t & et).size] }.max_by { |_, n| n }
      @suggested[e['id'].to_s] = best[0] if best && best[1] >= 2
    end
  end

  def name_tokens(s)
    s.to_s.unicode_normalize(:nfd).gsub(/\p{Mn}/, '').downcase.split(/[^a-z]+/).reject { |t| t.length <= 2 }
  end

  def current_settings
    (Setting.plugin_redmine_worksheet_sync || {}).to_h.dup
  end

  def load_config
    @settings = current_settings
    @users = User.active.where(type: 'User').sorted.to_a
    @activities = TimeEntryActivity.shared.active.to_a
    @from ||= (Date.today - 14).to_s
    @to   ||= Date.today.to_s
    @runs = WorksheetSyncRun.order(created_at: :desc).limit(20).to_a
  end

  def load_employees
    @employees = nil
    @employees_error = nil
    key = @settings['ws_api_key'].to_s
    return if key.blank?
    begin
      @employees = WorksheetSync::Client.new(key).employees.sort_by { |e| e['name'].to_s.downcase }
    rescue => e
      @employees_error = e.message
    end
  end

  def parse_mapping(h)
    h = h.respond_to?(:to_unsafe_h) ? h.to_unsafe_h : (h || {})
    out = {}
    h.each { |emp_id, user_id| out[emp_id.to_s] = user_id if user_id.present? }
    out
  end
end
