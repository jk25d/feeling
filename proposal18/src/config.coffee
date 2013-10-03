module.exports =
  port: 3333
  secret: 'deadbeef'
  session_expire_time: 30 * 60 * 1000

  feeling_share_dur: 12 * 60 * 60 * 1000
  feeling_dispatchable_dur: 6 * 60 * 60 * 1000

  user_receive_wait_time: 0
  schedule_interval: 5000
  feeling_container_size: 10000

  auto_feeling_interval: 10 * 1000