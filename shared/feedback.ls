export class Feedback
  @color = <[green blue red none]>
  @load-json = (json) ->
    fb = new Feedback
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

