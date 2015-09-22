Parse.Cloud.beforeSave(Parse.User, function(request, response) {
  if (request.object.get("name")) {
    request.object.set("lowercaseName", request.object.get("name").toLowerCase())
  }
  response.success();  
});