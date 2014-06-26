uuid = require 'node-uuid'
export class Snapshot
  (@text, @entry-uuid) ->
    @uuid = uuid.v1!
