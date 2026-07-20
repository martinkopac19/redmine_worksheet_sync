# Redmine Worksheet Sync (Previo)
# Importuje odpracovaný čas z ws.previo.cz do Redmine, keď worksheet záznam
# začína "#<číslo tasku>". Centrálne, admin-driven. Píše in-process (žiadny
# zásah do jadra). Previo-špecifické (Worksheet API).

require_relative 'lib/worksheet_sync/client'
require_relative 'lib/worksheet_sync/importer'

Redmine::Plugin.register :redmine_worksheet_sync do
  name 'Redmine Worksheet Sync (Previo)'
  author 'Martin Kopáč'
  description 'Imports logged time from ws.previo.cz into Redmine when a worksheet entry starts with #<issue id>. Central, admin-driven.'
  version '0.2.3'
  url 'https://github.com/martinkopac19/redmine_worksheet_sync'
  requires_redmine version_or_higher: '5.0'

  settings default: {
    'ws_api_key'       => '',
    'service_user_id'  => nil,
    'service_api_key'  => '',
    'activity_name'    => 'Development',
    'cron_enabled'     => false,
    'cron_window_days' => 10,
    'mapping'          => {}
  }

  menu :admin_menu, :worksheet_sync,
       { controller: 'worksheet_sync', action: 'show' },
       caption: :label_worksheet_sync,
       html: { class: 'icon icon-time-add' }
end
