duration_stddev = 
  from(bucket: "Jenkins")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "jenkins_job")
  |> group()
  |> stddev(column: "_value", mode: "sample")
  |> keep(columns: ["_value", "name", "_time"])

 
mean = 
  from(bucket: "Jenkins")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "jenkins_job")
  |> filter(fn: (r) => r._field == "duration")
  |> group()
  |> mean(column: "_value")
  |> keep(columns: ["_value", "name", "_time"])

  

duration = 
  from(bucket: "Jenkins")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "jenkins_job")
  |> filter(fn: (r) => r._field == "duration")
  |> toFloat()
  |> keep(columns: ["_value", "name", "_time"])
  |> set(key: "mykey", value: "myvalue")
 
normal = 
  join(tables: {duration_stddev: duration_stddev , mean: mean}, on: ["name"])
  |> map(fn: (r) => ({r with _limit:(r._value_duration_stddev*2.0 + r._value_mean)}))
  |> keep(columns: ["_limit", "mykey"])
  |> set(key: "mykey", value: "myvalue")


anomaly = 
  join(tables: {duration: duration , normal: normal}, on: ["mykey"])
  |> map(fn: (r) => ({r with _anomaly:(r._value - r._limit)}))
  |> filter(fn: (r) => r._anomaly > 0)
  |> keep(columns: ["_anomaly", "name", "_time"])
  |>yield()



