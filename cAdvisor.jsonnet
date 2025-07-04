// Add https://grafana.github.io/grizzly/
local g = import 'g.libsonnet';
local panels = import './panels.libsonnet';
local datasources = import './datasources.libsonnet';

local prometheusQuery = g.query.prometheus;
local row = g.panel.row;
local table = g.panel.table;
local timeSeries = g.panel.timeSeries;
local util = g.util;
local var = g.dashboard.variable;

local host = var.query.new(
  name='host',
  query='label_values({__name__=~"container.*"}, instance)'
)
+ var.query.withDatasource(type=datasources.prometheus.type, uid=datasources.prometheus.pluginId)
+ var.query.generalOptions.withLabel('Host')
+ var.query.refresh.onLoad()
+ var.query.selectionOptions.withIncludeAll();

local container = var.query.new(
  name='container',
  query='label_values({__name__=~\"container.*\", instance=~\"$host\"},name)'
)
+ var.query.withDatasource(type=datasources.prometheus.type, uid=datasources.prometheus.pluginId)
+ var.query.generalOptions.withLabel('Container')
+ var.query.refresh.onLoad()
+ var.query.selectionOptions.withIncludeAll();

g.dashboard.new('cAdvisor Dashboard')
+ g.dashboard.withTimezone()
+ g.dashboard.withVariables([host, container])
+ g.dashboard.withPanels([
  // ======================
  // CPU
  // ======================

  row.new('CPU')
  + row.withGridPos(0),

  // CPU Usage
  panels.timeSeriesPanel(
    unit='percent',
    title='CPU Usage',
    gridPos={x: 0, y: 1, w: 24, h: 8},
    targets=[
      prometheusQuery.new(
        datasource=datasources.prometheus.pluginId,
        expr='sum(rate(container_cpu_usage_seconds_total{instance=~"$host",name=~"$container",name=~".+"}[5m])) by (name) *100'
      )
      + prometheusQuery.withLegendFormat('{{name}}')
    ]
  ),

  // ======================
  // Memory
  // ======================
  row.new('Memory')
  + row.withGridPos(8),

  // Memory Usage
  panels.timeSeriesPanel(
    unit='bytes',
    title='Memory Usage',
    gridPos={x: 0, y: 9, w: 12, h: 8},
    targets=[
      prometheusQuery.new(
        datasource=datasources.prometheus.pluginId,
        expr='sum(container_memory_rss{instance=~"$host",name=~"$container",name=~".+"}) by (name)'
      )
      + prometheusQuery.withLegendFormat('{{name}}')
    ]
  ),

  // Memory Cached
  panels.timeSeriesPanel(
    unit='bytes',
    title='Memory Cached',
    gridPos={x: 12, y: 9, w: 12, h: 8},
    targets=[
      prometheusQuery.new(
        datasource=datasources.prometheus.pluginId,
        expr='sum(container_memory_cache{instance=~"$host",name=~"$container",name=~".+"}) by (name)'
      )
      + prometheusQuery.withLegendFormat('{{name}}')
    ]
  ),

  // ======================
  // Network
  // ======================

  row.new('Network')
  + row.withGridPos(17),

  // Received Network Traffic
  panels.timeSeriesPanel(
    unit='Bps',
    title='Received Network Traffic',
    gridPos={x: 0, y: 18, w: 12, h: 8},
    targets=[
      prometheusQuery.new(
        datasource=datasources.prometheus.pluginId,
        expr='sum(rate(container_network_receive_bytes_total{instance=~"$host",name=~"$container",name=~".+"}[5m])) by (name)'
      )
      + prometheusQuery.withLegendFormat('{{name}}')
    ]
  ),

  // Sent Network Traffic
  panels.timeSeriesPanel(
    unit='Bps',
    title='Sent Network Traffic',
    gridPos={x: 12, y: 18, w: 12, h: 8},
    targets=[
      prometheusQuery.new(
        datasource=datasources.prometheus.pluginId,
        expr='sum(rate(container_network_transmit_bytes_total{instance=~"$host",name=~"$container",name=~".+"}[5m])) by (name)'
      )
      + prometheusQuery.withLegendFormat('{{name}}')
    ]
  ),

  // ======================
  // Misc
  // ======================

  row.new('Misc')
  + row.withGridPos(26),

  // Containers Info
  table.new(title='Containers Info')
  + table.panelOptions.withGridPos(x=0, y=27, w=24, h=8)
  + table.queryOptions.withTargets([
      prometheusQuery.new(
        datasource=datasources.prometheus.pluginId,
        expr='(time() - container_start_time_seconds{instance=~"$host",name=~"$container",name=~".+"})/86400',
      )
      + prometheusQuery.withFormat("table")
      + prometheusQuery.withInstant()
  ])
  + table.queryOptions.withTransformations([
    {
      "id": "filterFieldsByName",
      "options": {
        "include": {
          "names": [
            "container_label_com_docker_compose_project_working_dir",
            "container_label_com_docker_compose_project",
            "container_label_com_docker_compose_service",
            "image",
            "instance",
            "name",
            "Value",
          ]
        },
      }
    },
    {
      "id": "organize",
      "options": {
        "renameByName": {
          "container_label_com_docker_compose_project_working_dir": "Working dir",
          "container_label_com_docker_compose_project": "Label",
          "container_label_com_docker_compose_service": "Service",
          "image": "Registry Image",
          "instance": "Instance",
          "name": "Name",
          "Value": "Running",
        }
      }
    },
  ])
  + table.options.withShowHeader()
  + table.standardOptions.withOverrides([
    {
      "matcher": {
        "id": "byName",
        "options": "Running"
      },
      "properties": [
        {
          "id": "unit",
          "value": "d"
        },
        {
          "id": "decimals",
          "value": 1
        },
        {
          "id": "custom.cellOptions",
          "value": {
            "type": "color-text"
          }
        },
        {
          "id": "color",
          "value": {
            "fixedColor": "dark-green",
            "mode": "fixed"
          }
        }
      ]
    }
  ])
])
