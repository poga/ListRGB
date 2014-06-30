require! async

export class UserFeedback
  @redis-set = (redis, doc-id, user-id, entry-id, color, cb) ->
    err, v <- redis.hset "doc:#doc-id:feedbackers:#user-id", entry-id, color
    err, v <- redis.sadd "doc:#doc-id:feedbackers", user-id
    cb v

  @load-all-redis = (redis, doc-id, cb) ->
    err, uids <- redis.smembers "doc:#doc-id:feedbackers"
    throw err if err
    async.map uids, (uid, cb) ->
      err, fb <- redis.hgetall "doc:#doc-id:feedbackers:#uid"
      throw err if err
      if fb
        cb null, UserFeedback.load user-id: uid, feedbacks: fb
      else
        cb null, new UserFeedback uid
    , (err, result) ->
      cb result

  @load-doc-user-redis = (redis, doc-id, user-id, cb) ->
    err, fb <- redis.hgetall "doc:#doc-id:feedbackers:#user-id"
    throw err if err
    if fb
      cb UserFeedback.load user-id: user-id, feedbacks: fb
    else
      cb new UserFeedback user-id

  @color = <[green blue red none]>

  @load = (json) ->
    fb = new UserFeedback
    fb.user-id = json.user-id
    fb.feedbacks = json.feedbacks
    return fb

  (@user-id) ->
    @feedbacks = {}

  set: (entry-id, color) ->
    if @@color.indexOf color != -1
      @feedbacks[entry-id] = color

  toJSON: ->
    user-id: @user-id, feedbacks: @feedbacks

  calculate-percentage: (total) ->
    percentage = {}
    for c in @@color
      percentage[c] = 0
    for eid, color of @feedbacks
      percentage[color]++
    percentage[\none] += total - percentage[\green] - percentage[\blue] - percentage[\red] - percentage[\none]

    for c in @@color
      percentage[c] = percentage[c] / total * 100
    return percentage
