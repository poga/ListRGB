require! async

export class UserFeedback
  @dist = (feedbacks, total) ->
    dist = {}
    for c in UserFeedback.color
      dist[c] = 0
    return dist if Object.keys feedbacks .length == 0
      
    for eid, color of feedbacks
      dist[color]++
    dist[\none] += total - dist[\green] - dist[\blue] - dist[\red] - dist[\none]
    for c in UserFeedback.color
      dist[c] = dist[c] / total * 100
    return dist

  @redis-set = (redis, doc-id, user-id, entry-id, color, cb) ->
    err, old-color <- redis.hget "doc:#doc-id:feedbackers:#user-id", entry-id
    err, v <- redis.hset "doc:#doc-id:feedbackers:#user-id", entry-id, color
    err, v <- redis.sadd "doc:#doc-id:feedbackers", user-id
    cb old-color, color

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
    err, eids <- redis.lrange "doc:#doc-id:entries", 0, -1
    throw err if err
    err, fb <- redis.hgetall "doc:#doc-id:feedbackers:#user-id"
    throw err if err
    if fb
      ufb = new UserFeedback user-id
      for eid in eids
        ufb.set eid, fb[eid]
      cb ufb
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

  dist: (total) ->
    UserFeedback.dist @feedbacks, total
