var Mailgun = require('mailgun');
Mailgun.initialize('sandbox259dcac5ce094ffcbce8542ba22fda37.mailgun.org', 'key-612b759d61c51fcb92c4cdbe10b36d2e');

/**
 * After a ReportPhoto object is saved,
 * Send an email to Austin to let him know there's a photo waiting for review.
 */
Parse.Cloud.afterSave('ReportPhoto', function(request) {

	Mailgun.sendEmail({
	  to: "austinbarnard@triptrunkapp.com",
	  from: "support@triptrunkapp.com",
	  subject: "A TripTrunk Photo Was Flagged",
	  text: "A photo was reported for: " + request.object.get("reason") 
	}, {
	  success: function(httpResponse) {
	    console.log(httpResponse);
	  },
	  error: function(httpResponse) {
	    console.error(httpResponse);
	  }
	});

});