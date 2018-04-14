
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


function getUrlParameter(sParam) {
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

var feeds = {};
var latestItem = 0;
var feedIds= getUrlParameter('feed_ids').split(',');

$(document).ready(function() {
	  if(!("WebSocket" in window)){
		    alert('Oh no, you need a browser that supports WebSockets.');
	  }else{
	      //The user has WebSockets
        var feedsCalls = [];
        $.each(feedIds, function(index, feedId) {
            feedsCalls.push(
                $.get(`http://localhost:3000/feeds/${feedId}`, function(feed) {
                    feeds[feedId] = feed.data.user;})
            );
        });
        $.when.apply(undefined, feedsCalls).done(function (feedsCallDone){
            if (feedIds.length == 1) {
                getSingleFeed();
            } else {
                followFeeds();
            }
	          connect();
        });
    }
});


function getSingleFeed() {
    $.get(`http://localhost:3000/activity_feeds/${feedIds[0]}?&since=${latestItem}`, function( data ) {
        $.each(data, function(index, feedItem) {
            if (index == 0) {
                latestItem = feedItem.data.created_at;
            }
            message(feedItem, feeds[feedItem.data.feed_id]);
        });
    }).fail(function() {
        var feedItem = {
            data: {
                payload: {
                    text: "Error loading feed..."
                },
                created_at: "0"}
        };
        var user = {name: "Invalid user"};
        message(feedItem, user);
    });
}

function followFeeds() {
    $.get(`http://localhost:3000/activity_feeds/follow?feed_ids=${feedIds}&since=${latestItem}`, function( data ) {
        $.each(data, function(index, feedItem) {
            if (index == 0) {
                latestItem = feedItem.data.created_at;
            }
            message(feedItem, feeds[feedItem.data.feed_id]);
        });
    }).fail(function() {
        var feedItem = {
            data: {
                payload: {
                    text: "Error loading feed..."
                },
                created_at: "0"}
        };
        var user = {name: "Invalid user"};
        message(feedItem, user);
    });
}

function connect(){
    try{

	      var socket;
	      var host = `ws://localhost:3000/subscribe/activity_feeds?feed_ids=${feedIds}`;
        socket = new window.WebSocket(host);

        socket.onopen = function(){
            console.log("Socket connection opened.");
        };

        socket.onmessage = function(msg){
            if (feedIds.length == 1) {
                getSingleFeed();
            } else {
                followFeeds();
            }
        };

        socket.onclose = function(){
            console.log("Socket connection closed.");
        };

    } catch(exception){
   		  console.log(exception);
    }
}
