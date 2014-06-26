require 'node-uuid'
CS  = require 'changesets' .Changeset

export class Edit
  (cs, @parent-id, @uuid, @createdAt) ->
    @cs = CS.unpack cs
    @createdAt = Date.now! unless @createdAt
  reparent: (new-parent) ->
    @cs = @cs.transformAgainst new-parent.cs
    @parent-id = new-parent.uuid
  toJSON: ->
    cs: @cs.pack!, parent-id: @parent-id, uuid: @uuid, createdAt: @createdAt

  apply: (text) ->
    @cs.apply text
