local g = import 'g.libsonnet';
local panels = import './panels.libsonnet';
local datasources = import './datasources.libsonnet';

local lokiQuery = g.query.loki;
local timeSeries = g.panel.timeSeries;
local var = g.dashboard.variable;

// Variable: Service selector
local service = var.query.new(
  name='service',
  query='label_values(compose_service)'
)
+ var.query.withDatasource(type=datasources.loki.pluginId, uid=datasources.loki.uid)
+ var.query.generalOptions.withLabel('Service')
+ var.query.refresh.onLoad()
+ var.query.selectionOptions.withIncludeAll()
+ var.query.selectionOptions.withMulti(true);

// Variable: Container selector (filtered by service)
local container = var.query.new(
  name='container',
  query='label_values({compose_service=~"$service"}, container)'
)
+ var.query.withDatasource(type=datasources.loki.pluginId, uid=datasources.loki.uid)
+ var.query.generalOptions.withLabel('Container')
+ var.query.refresh.onLoad()
+ var.query.selectionOptions.withIncludeAll()
+ var.query.selectionOptions.withMulti(true);

// Variable: Log level filter
local logLevel = var.custom.new(
  name='log_level',
  values=['.*', 'error', 'warn', 'info', 'debug', 'trace']
)
+ var.custom.generalOptions.withLabel('Log level')
+ var.custom.selectionOptions.withMulti(false);

// Variable: Search/filter text
local searchText = var.textbox.new(
  name='search',
  default='.*'
)
+ var.textbox.generalOptions.withLabel('Search')
+ var.textbox.generalOptions.withDescription('Filter logs by text (case-insensitive, use .* for all)');

// Build the log query expression with filters
local buildLogQuery() =
  '{compose_service=~"$service", container=~"$container"} | detected_level=~"$log_level" |~ "(?i)$search"';

g.dashboard.new('Docker services logs')
+ g.dashboard.withDescription('Simple dashboard for viewing Docker container logs')
+ g.dashboard.withTimezone()
+ g.dashboard.withRefresh('10s')
+ g.dashboard.withVariables([service, container, logLevel, searchText])
+ g.dashboard.withPanels([
  // Log volume chart
  timeSeries.new(title='Log Volume')
  + timeSeries.panelOptions.withGridPos(x=0, y=0, w=24, h=6)
  + timeSeries.queryOptions.withTargets([
      lokiQuery.new(
        datasource=datasources.loki.uid,
        expr='sum by (compose_service) (count_over_time(' + buildLogQuery() + ' [1m]))'
      )
      + lokiQuery.withLegendFormat('{{compose_service}}')
  ])
  + timeSeries.fieldConfig.defaults.custom.withDrawStyle('line')
  + timeSeries.fieldConfig.defaults.custom.withFillOpacity(10)
  + timeSeries.fieldConfig.defaults.custom.withLineInterpolation("smooth")
  + timeSeries.fieldConfig.defaults.custom.withShowPoints("never")
  + timeSeries.fieldConfig.defaults.custom.stacking.withMode("normal")
  + timeSeries.standardOptions.withUnit('logs/min')
  + timeSeries.options.legend.withDisplayMode('list')
  + timeSeries.options.legend.withPlacement("bottom"),

  // Main logs panel with all filters applied
  panels.logsPanel(
    title='Logs',
    gridPos={x: 0, y: 6, w: 24, h: 18},
    targets=[
      lokiQuery.new(
        datasource=datasources.loki.uid,
        expr=buildLogQuery()
      )
    ]
  ),
])
