window.mem0r1es = {} if not window.mem0r1es?
window.indexedDB = window.indexedDB or window.webkitIndexedDB or window.mozIndexedDB or window.msIndexedDB
window.IDBTransaction = window.IDBTransaction or window.webkitIDBTransaction or window.mozIDBTransaction or window.msIDBTransaction

class window.mem0r1es.StorageExecutor  
  
  setDb: (@db) ->
    console.log "Storage executor ready"
    
  onerror : () ->
    console.log "ERROR"
  
  clearDatabase: (sendResponse)->
    try
      @clearStore "temporary"
      @clearStore "parameters"
      @clearStore "labels"
      @clearStore "userStudySessions"
      @clearStore "screenshots"
      @clearStore "userActions"
      sendResponse {message:{title:"message from networkManager", content:"Database cleared", level:"success"}}
    catch error
      console.log error.message
      sendResponse {message:{title:"message from networkManager", content:"Database NOT cleared", level:"error"}}
    return
  
  #Clears all the data from a specific store and send an ack to the popup
  #Argument: the methode used to respond to the popup
  clearStore: (storeName) ->
    if not @isReady
      return false
      
    trans = @db.transaction [storeName], "readwrite"
    store = trans.objectStore storeName
    
    if store?
      clearReq = store.clear()
      
      clearReq.onsuccess = (event) ->
        console.log "#{storeName} cleared"
        return
        
      clearReq.onerror = (event) ->
        console.log "error while clearing #{storeName}"
        return
        
      return
  
  #Stores an object corresponding to a page browsing in the datastore
  # callback is optional and is here to notify the caller that the object has been successfully inserted
  store : (storeName, value, callback)->
    try
      if value._children?
        count = 0
        for child in value._children
          count = count + value[child.name].length
        for child in value._children
          do(child) =>
            for childElement in value[child.name]
              @store child.objectStore, childElement, () =>
                if count == 1
                  for child in value._children
                    delete value[child.name]
                  delete value._children
                  trans = @db.transaction [storeName], "readwrite"
                  store = trans.objectStore storeName
                  request = store.put value
                  request.onsuccess = (event) ->
                    if callback?
                      try
                        callback event.target.result
                      catch error
                    return
                  
                  request.onerror = @onerror
                else
                  count--
                return
            return
      else
        trans = @db.transaction [storeName], "readwrite"
        store = trans.objectStore storeName
        request = store.put value
        request.onsuccess = (event) ->
          if callback?
            try
              callback event.target.result
            catch error
          return
        
        request.onerror = @onerror
    
    catch error
      console.log error.message
      console.log "Error while storing #{JSON.stringify(value)} in store #{storeName}"
      if callback?
        callback {}
    return
    
  get : (query, callback) ->
    n=0
    try
      results = new Array
      trans = @db.transaction [query.storeName], "readonly"
      store = trans.objectStore query.storeName
      try
        index = store.index query.key
      catch error
      if not index?
        index = store
      if query.keyRange
        request = index.openCursor(query.keyRange)
      else
        request = index.openCursor()
      request.onsuccess = (event) =>
        cursor = event.target.result
        if cursor? and n<query.limitMax
          n++
          if query.limitMin-1<n
            if query.accept cursor.value
              results.push cursor.value
            else
              n--
          cursor.continue()
        else
          if query.children? and query.children.length isnt 0 and results.length isnt 0
            count = results.length * query.children.length
            for result in results
              do(result) =>
                result._children = query.children
                for child in query.children
                  do(child) =>
                    @get new mem0r1es.Query().from(child.objectStore).where("_#{store.keyPath}", "equals", result[store.keyPath]), (subResults) =>
                      result[child.name] = subResults
                      if count is 1
                        callback results
                      else
                        count--
                      return
                    return
          else        
            callback results
    catch error
      console.log error.message
      console.log "Error while getting #{query.toString()}"
      callback {}
    return
  
  count : (query, callback) ->
    try  
      trans = @db.transaction [query.storeName], "readonly"
      store = trans.objectStore query.storeName
      try
        index = store.index query.key
      catch error
      if not index?
        index = store
      if query.keyRange
        request = index.count query.keyRange
      else
        request = index.count()
      request.onsuccess = (event) ->
        callback event.target.result
    catch error
      console.log error.message
      console.log "Error while counting #{query.storeName}"
      callback {}
      
  delete : (storeName, id, callback) ->
    try
      console.log "deleting object with PK #{id} from #{storeName}"
      trans = @db.transaction [storeName], "readwrite"
      store = trans.objectStore storeName
      request = store.delete id
      request.onsuccess = (event) ->
        callback {id : id, status: "deleted"}
    catch error
      console.log error.message
      console.log "Error while deleting #{id} from #{storeName}"
      callback {}
    return
      
  deleteDB : () ->
    try
      @db.close()
      request = indexedDB.deleteDatabase @dbName
      request.onsuccess = () =>
        console.log "database #{@dbName} deleted"
        return
    catch error
      console.log error.message
      console.log "error while deleting the whole database"
      callback {}
    return

