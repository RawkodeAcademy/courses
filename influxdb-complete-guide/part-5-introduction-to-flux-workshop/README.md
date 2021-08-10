# Introduction to Flux

You can watch @rawkode run through this workshop by [subscribing to the Rawkode Academy on YouTube](https://rawkode.live/join).

[The session is available here](https://www.youtube.com/watch?v=1jbxhuZ7m0E).

---

Welcome to the introduction to Flux! In-order to work through this workshop, you'll need InfluxDB 2 running and Telegraf collecting some metrics. Here's a sample Telegraf configuration for you to run.

You'll need InfluxDB 2 running, with your organization created as `rawkode-academy` and your bucket called `workshop`. If you have this configured differently, you'll need to tweak the queries as we proceed. You'll also need your InfluxDB 2 token available in your environment as `INFLUX_TOKEN`.

```toml
[agent]
  interval = "2s"
  flush_interval = "6s"

[[inputs.cpu]]
  totalcpu = false

[[inputs.disk]]
[[inputs.diskio]]
[[inputs.mem]]
[[inputs.net]]
[[inputs.processes]]
[[inputs.swap]]
[[inputs.system]]

[[outputs.influxdb_v2]]
  urls = ["http://localhost:8086"]
  token = "$INFLUX_TOKEN"
  organization = "rawkode-academy"
  bucket = "workshop"
```

## Your First Flux Query

There are two functions that are **ALWAYS** required before the Flux engine will execute a query against InfluxDB.

- Data Souce
- Time Window

### DataSource

All Flux queries need to have a data source. For this workshop, we'll be using the InfluxDB 2 data source, which queries InfluxDB 2 buckets.

We use the `from` function to specify which bucket from InfluxDB we want to query.

```flux
from(bucket: "workshop")
```

### Time Window

We use the `range` function to specify which window of time we want to query. InfluxDB does not allow Flux to run unbound queries, as this could be extremely resource intensive and is blocked as a protective measure.

```flux
from(bucket: "workshop")
  |> range(start: -15m)
```

### Pipe Operator

You may have noticed a cheeky little `|>` in our query above and gotten a little confused. In Flux, we call this the pipe operator and it allows us to pass the output of one function (`from`) to another (`range`); often refered to as function chaining. If you've written any F# or Elixir, this should feel pretty familiar.

#### Duration Literals

Flux has primitives for durations and they can be used like so:

- `-15s`
- `-15m`
- `-1h`
- `-1d`
- `-1d`
- `-1mo`
- `-1y`

#### Time Literals

Flux has primitives for time and they can be used like so:

- `2021-01-01`
- `2021-01-01T00:00:00Z`
- `now()`

### Yield

The `yield` function is used to return data from your Flux script. When `yield` is omitted from your Flux script, one is automatically added for you, at the end.

These two scripts are equivalent:

```flux
from(bucket: "workshop")
  |> range(start: -15m)
```

```flux
from(bucket: "workshop")
  |> range(start: -15m)
  |> yield()
```

In-order to yield the data from multiple queries, you need to `yield` with unique names. You can ignore the `filter` functions for the time being, these are covered shortly.

```flux
from(bucket: "workshop")
  |> range(start: -15m)
  |> filter(fn: (r) => r._measurement == "cpu")
  |> yield("cpu")

from(bucket: "workshop")
  |> range(start: -15m)
  |> filter(fn: (r) => r._measurement == "mem")
  |> yield("mem")
```

## Exercises 1

Write Flux queris that will return:

1. All metrics for the last 5 minutes
2. All metrics for the last hour, excluding the last 5 minutes
3. All metrics for last 3 hours, returned as separate data sets, hourly (Use multiple yield)

## Filtering Data

After we've got some data by using `from` and `range`, we typically need to use one, or more, `filter` functions to filter the data to only the data that we need.

The `filter` function can filter data on ANY field in the data set. This means that you need to be particularly careful when adding filters and ensure that you understand when filtering on a tag or a field.

When filtering using tag fields in our data set, we're allowing the Flux engine to work on data before the data is loaded into memory, as it can leverage "push downs" that allow th TSDB to filter the data is reads from disk.

When filtering using fields in our data set, we're requesting all the data from the TSDB and then filtering it in memory.

You can be successful filtering on field values, but it's definitely considered best practice to reduce that data set with tag filters as much as possible first.

The `filter` function takes a parameter called `fn` that is a function that returns a boolean. If the predicate returns `true`, the data will be kept in the data set. Each record in the data set is passed to the predicate function, usually denoted as `r`.

If you're unsure what fields and values you have available in your data, you can use the "Show Data" button in the InfluxDB 2 dashboard to get a better understanding.

```flux
from(bucket: "workshop")
  |> range(start: -15m)
  |> filter(fn: (r) => r._measurement == "cpu")
```

## Tables & Grouping

Flux returns all data from your queries as a set of tables which are grouped by a "group key". This group key, by default, is each series within your data where a series is the unique combination of tag key and values.

This is always the first hurdle for people adopting Flux and InfluxDB 2, so lets break this down by example.

```flux
from(bucket: "workshop")
  |> range(start: -5m)
  |> filter(fn: (r) => r["_measurement"] == "cpu")
  |> filter(fn: (r) => r["_field"] == "usage_system" or r["_field"] == "usage_user" or r["_field"] == "usage_guest")
```

Looking at this query, how many tables do you expect this to return? If you're like most people, including myself, your intuition will probably lead you to say 1 or 4.

<details><summary>Real Answer</summary>
This query returns 48 tables (on my machine).

This is because each CPU available on the machine provides a unique series and we need to multiple the number of CPUs (16) on the machine by 3 - because we also have 3 unique fields that are being queries.
</details>

We can change the group key for our query by using the `group` function, as well as a few others that we'll cover in due course.

I'll cover two applications of `group` now, but be warned: changing the group key is something you need to be careful with, especially when you want to work with fields within the group. You usually wanted to perform an aggreation first and then group to get the tables you need. This is covered in the next section.

### Group by Tag

Let's assume we want the data above, but grouped by metric; ignoring the different CPUs altogether.

```flux
from(bucket: "workshop")
  |> range(start: -5m)
  |> filter(fn: (r) => r["_measurement"] == "cpu")
  |> filter(fn: (r) => r["_field"] == "usage_system" or r["_field"] == "usage_user" or r["_field"] == "usage_guest")
  |> group(columns: ["_measurement", "_field"], mode:"by")
```

When calling `group`, we need to pass the `columns` parameter. This parameter is an array of fields to use as the group key.

**How many tables do you think we'll get back now?**


### No Group

I tend to call this "flatten" as we remove the group key and force Flux to give us a single table. This is especially useful after you've performed whatever aggregations you need to perform and just want some values out the other side. We can call `group()` without any parameters to remove the group key.

```flux
from(bucket: "workshop")
  |> range(start: -5m)
  |> filter(fn: (r) => r["_measurement"] == "cpu")
  |> filter(fn: (r) => r["_field"] == "usage_system" or r["_field"] == "usage_user" or r["_field"] == "usage_guest")
  |> group()
```


## Windows and Aggregations

**Note:** `mo` and `y` durations behave a little differently in `from` than in `window` operations. When windowing data, `mo` and `y` are calendar months and years.

### Windowing

Flux allows us to use the `window` function to change the group key of our data to be time bound. This allows us to perform aggregations on the data in a given time window. This is mostly useful when you're looking at a single metric.

In the following query, we request the last 15 minutes of CPU usage_user metrics and tell Flux to change the group key to a 1 minute window.

**Pop Quiz:** How many tables will this query return?

```flux
from(bucket: "workshop")
  |> range(start: -15m)
  |> filter(fn: (r) => r["_measurement"] == "cpu")
  |> filter(fn: (r) => r["_field"] == "usage_user")
  |> window(every: 1m)
```


<details><summary>Answer</summary>
It depends on how many CPUs you have. My machine has 16 CPUs and this query returns 256 tables.

Why?

We've requested a single metric, `usage_user`, and we have 16 CPUs. Typically, this will return 16 tables. Now because we've requested the data be grouped by 1 minute windows, we actually need to multiple 16 by 16.

We multiply by 16 because our range of `-15m` with `1m` windows returns 16 tables, not 15. We'll get a rounding table for the current minute. You can confirm this by restricting the query to a single CPU and looking at the data.

```flux
from(bucket: "workshop")
  |> range(start: -15m)
  |> filter(fn: (r) => r["_measurement"] == "cpu")
  |> filter(fn: (r) => r["_field"] == "usage_user")
  |> filter(fn: (r) => r["cpu"] == "cpu0")
  |> window(every: 1m)
```
</details>

As we've stated, windowing alone isn't terribly useful; but it becomes extremely powerful when we begin to aggregate across windows.

### Aggregations

Aggregate functions take the values of all rows in a table and use them to perform an aggregate operation. The result is output as a new value in a single-row table.

Since windowed data is split into separate tables, aggregate operations run against each table separately and output new tables containing only the aggregated value.

For this example, use the `mean` function to output the average of each window. The following query requests the last 5 minutes of data for a single CPU's `usage_user` and calculates the `mean` value for each `1m` window.

```flux
from(bucket: "workshop")
  |> range(start: -5m)
  |> filter(fn: (r) => r["_measurement"] == "cpu")
  |> filter(fn: (r) => r["cpu"] == "cpu0")
  |> filter(fn: (r) => r["_field"] == "usage_user")
  |> window(every: 1m)
  |> mean()
```

**Pop Quiz:** How many tables will this query return?

<details><summary>Answer</summary>
The group key of our query was changed when we used the `window` function and we get a table for each time window available. So the answer is 6. This isn't really what most people would want here and it's rather common to then flatten the data to get a single table.

```flux
from(bucket: "workshop")
  |> range(start: -5m)
  |> filter(fn: (r) => r["_measurement"] == "cpu")
  |> filter(fn: (r) => r["cpu"] == "cpu0")
  |> filter(fn: (r) => r["_field"] == "usage_user")
  |> window(every: 1m)
  |> mean()
  |> group()
```
</details>

This type of query is the most common operation on time series data and as such a helper function is available to reduce the code needed to perform it. Hello, `aggregateWindow`.

```flux
from(bucket: "workshop")
  |> range(start: -5m)
  |> filter(fn: (r) => r["_measurement"] == "cpu")
  |> filter(fn: (r) => r["cpu"] == "cpu0")
  |> filter(fn: (r) => r["_field"] == "usage_user")
  |> aggregateWindow(every: 1m, fn: mean)
```

## Exercises 2

Write Flux queries that will return:

1. All cpu metrics for the last 15 minutes
2. All cpu and mem metrics for the last 30 minutes
3. The mean cpu and mem usage for the last 2 hours as single values
4. A single graph showing the min, max, and mean cpu and mem usage for the last 2 hours
5. A single graph showing the max, min, and mean usage of the root file system over the last 2 hours at 30m intervals
6. A single graph showing the total number of bytes received on all network interfaces over the last 15 minutes
