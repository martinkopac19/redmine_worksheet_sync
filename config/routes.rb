get  'worksheet_sync',          to: 'worksheet_sync#show'
post 'worksheet_sync',          to: 'worksheet_sync#update'
post 'worksheet_sync/run',      to: 'worksheet_sync#run'
get  'worksheet_sync/runs.csv', to: 'worksheet_sync#runs_csv', defaults: { format: 'csv' }
