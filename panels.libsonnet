local g = import 'g.libsonnet';

local prometheusQuery = g.query.prometheus;
local lokiQuery = g.query.loki;
local row = g.panel.row;
local table = g.panel.table;
local timeSeries = g.panel.timeSeries;
local logs = g.panel.logs;

local timeSeriesPanel(
    unit,
    title = 'New time series panel',
    targets = [],
    gridPos = {x: 0, y: 0, w: 24, h: 8}
) =
  timeSeries.new(title=title)
  + timeSeries.panelOptions.withGridPos(x=gridPos.x, y=gridPos.y, w=gridPos.w, h=gridPos.h)
  + timeSeries.queryOptions.withTargets(targets)
  + timeSeries.fieldConfig.defaults.custom.scaleDistribution.withType("linear")
  + timeSeries.fieldConfig.defaults.custom.stacking.withGroup("A")
  + timeSeries.fieldConfig.defaults.custom.stacking.withMode("normal")
  + timeSeries.fieldConfig.defaults.custom.withDrawStyle('line')
  + timeSeries.fieldConfig.defaults.custom.withFillOpacity(10)
  + timeSeries.fieldConfig.defaults.custom.withLineInterpolation("linear")
  + timeSeries.options.legend.withCalcs(["mean", "max"])
  + timeSeries.options.legend.withDisplayMode('table')
  + timeSeries.options.legend.withPlacement("right")
  + timeSeries.options.legend.withShowLegend()
  + timeSeries.options.tooltip.withMode("multi")
  + timeSeries.standardOptions.thresholds.withMode('absolute')
  + timeSeries.standardOptions.thresholds.withSteps([
      {
        "color": "green"
      },
      {
        "color": "red",
        "value": 80
      }
    ])
  + timeSeries.standardOptions.withUnit(unit);

local logsPanel(
    title = 'Logs',
    targets = [],
    gridPos = {x: 0, y: 0, w: 24, h: 12}
) =
  logs.new(title=title)
  + logs.panelOptions.withGridPos(x=gridPos.x, y=gridPos.y, w=gridPos.w, h=gridPos.h)
  + logs.queryOptions.withTargets(targets)
  + logs.options.withShowTime(true)
  + logs.options.withShowLabels(true)
  + logs.options.withShowCommonLabels(false)
  + logs.options.withWrapLogMessage(true)
  + logs.options.withPrettifyLogMessage(true)
  + logs.options.withEnableLogDetails(true)
  + logs.options.withDedupStrategy('none')
  + logs.options.withSortOrder('Descending');

{
    timeSeriesPanel: timeSeriesPanel,
    logsPanel: logsPanel,
}
