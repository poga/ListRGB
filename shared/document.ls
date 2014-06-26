export class Doc
  @colors = <[green blue red]>

  (raw) ->
    @{alias, objects, history, uuid} = raw
    @parse-tags!
    @calculate-all-percentage!
  
  parse-tags: ->
    @tags = []
    regex = /\s#(\S+)\s*?/g
    for x, i in @objects
      if x.snapshot.match regex
        for tag in x.snapshot.match(regex)
          @tags.push tag unless @tags.indexOf(tag) != -1

  calculate-all-percentage: ->
    @percentage = {}
    for color in <[green red blue]>
      @percentage[color] = @calculate-percentage color
    @percentage[\grey] = 100 - @percentage.green - @percentage.red - @percentage.blue

  calculate-percentage: (color) ->
    return 0 if @objects.length == 0
    @objects.filter((o) -> o.status == color).length * 100.0 / @objects.length

  add-object: (snapshot, alias) ->
    new-obj = snapshot: snapshot, createdAt: Date.now!, uuid: uuid.v1!
    @objects.unshift new-obj
    if alias
      @alias.push name: alias, object_id: new-obj.uuid
    SocketIo.emit \op op: 'add object', item: new-obj, doc: @uuid

  remove-object: (object) ->
    @objects.splice @objects.indexOf(item), 1
    SocketIo.emit \op op: 'remove object', target: object.uuid, doc: @uuid

