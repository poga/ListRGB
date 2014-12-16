![screenshot](https://dl.dropboxusercontent.com/u/125794/listrgb-screenshot.png)

# ListRGB

Collaboration with Color.

## Installation

requirements:

 * [node.js](https://nodejs.org) (tested on 0.10.28 and 0.10.29)
 * [npm](https://www.npmjs.org) (tested on 1.4.10 and 1.4.14)
 * [redis](https://redis.io) (tested on 2.8.12)
 * [bower](https://bower.io)

### Download & Build

```
$ git clone git@github.com:poga/ListRGB.git
$ bower i
$ npm i
```

### Development

```
$ npm run dev
```

### Production

[pm2](https://github.com/unitech/pm2) is recommanded for production server.

```
$ pm2 start process.json
```

## REST API

### GET /_/:list

return the list.

### POST /_/:list/entries, body: { "text" : "foo" }, content-type: "application/json"

add entry "foo" to the list.

### PUT /_/:list/title,  body: { "text" : "foo" }, content-type: "application/json"

set the title of the list to "foo"

### PUT /_/:list/desc,  body: { "text" : "foo" }, content-type: "application/json"

set the description of the list to "foo"

### PUT /_/:list/entries/:eid,  body: { "text" : "foo" }, content-type: "application/json"

update the text of specified entry to "foo"

### DELETE /_/:list/entries/:eid

delete the entry

### GET /_/:list/stats

return the statistic of list.

### GET /_/:list/feedbacks/:user-id

return the feedback(colors) from the user on the list

### POST /_/:list/feedbacks/:user-id, body: { "entryId" : id, "color": green/red/blue/none }, content-type: "application/json"

set the color from the user one the entry to color

## License

MIT

Logo designed by @shulusama 
