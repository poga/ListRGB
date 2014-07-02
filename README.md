![screenshot](https://dl.dropboxusercontent.com/u/125794/listrgb-screenshot.png)

# ListRGB

Collaboration with Color.

## Installation

requirements:

 * [node.js](https://nodejs.org) (tested on 0.10.28 and 0.10.29)
 * [npm](https://www.npmjs.org) (tested on 1.4.10 and 1.4.14)
 * [redis](https://redis.io) (tested on 2.8.12)

### Development

```
$ bower i
$ npm i
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

### GET /_/:list/stats

return the statistic of list.

### GET /_/fb/:list/:user-id

return the feedback(colors) of user on the list
