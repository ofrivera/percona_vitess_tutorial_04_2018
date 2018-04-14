
function feedItem(userName, content, timestamp) {
    var date  = new Date(parseInt(timestamp.toString().slice(0,-3)));
    var template = `
		<div class="message-item" id="m16">
						<div class="message-inner">
							<div class="message-head clearfix">
								<div class="avatar pull-left"><a href="#"><img src="https://ssl.gstatic.com/accounts/ui/avatar_2x.png"></a></div>
								<div class="user-detail">
									<h5 class="handle">${userName}</h5>
									<div class="post-meta">
										<div class="asker-meta">
											<span class="qa-message-what"></span>
											<span class="qa-message-when">
												<span class="qa-message-when-data">${date.toLocaleDateString("en-US", { hour: 'numeric', hour12: true , minute: 'numeric'})}</span>
											</span>
											<span class="qa-message-who">
												<span class="qa-message-who-pad">by </span>
												<span class="qa-message-who-data"><a href="#">${userName}</a></span>
											</span>
										</div>
									</div>
								</div>
							</div>
							<div class="qa-message-content">
								${content}
							</div>
					</div></div>
`;
    return template;
}


function message(feed, user){
	  $('.qa-message-list').prepend(feedItem(user.name, feed.data.payload.text, feed.data.created_at));
}


var getUrlParameter = function getUrlParameter(sParam) {
    var sPageURL = decodeURIComponent(window.location.search.substring(1)),
        sURLVariables = sPageURL.split('&'),
        sParameterName,
        i;

    for (i = 0; i < sURLVariables.length; i++) {
        sParameterName = sURLVariables[i].split('=');

        if (sParameterName[0] === sParam) {
            return sParameterName[1] === undefined ? true : sParameterName[1];
        }
    }
};

$(document).ready(function() {
	  if(!("WebSocket" in window)){
		    alert('Oh no, you need a browser that supports WebSockets.');
	  }else{
	      //The user has WebSockets
        var feedIds= getUrlParameter('feed_ids').split(',');
        var latestItem = 0;
        var feeds = {};
        $.each(feedIds, function(index, feedId) {
            $.get(`http://localhost:3000/feeds/${feedId}`, function(feed) {
                feeds[feedId] = feed.data.user;
            });
        });

        if (feedIds.length == 1) {
            $.get(`http://localhost:3000/activity_feeds/${feedIds[0]}`, function( data ) {
                $.each(data, function(index, feedItem) {
                    if (index == 0) {
                        latestItem = feedItem.data.created_at;
                    }
                    message(feedItem, feeds[feedItem.data.feed_id]);
                });
            });
        }
	      //connect();
    }
});


function connect(){
    try{

	      var socket;
	      var host = "ws://localhost:3000/socket/server/startDaemon.php";
        socket = new WebSocket(host);

        socket.onopen = function(){
            console.log("Socket connection opened.");
        };

        socket.onmessage = function(msg){
        };

        socket.onclose = function(){
            console.log("Socket connection closed.");
        };

    } catch(exception){
   		  console.log(exception);
    }
}
