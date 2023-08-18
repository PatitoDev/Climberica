extends Node

signal OnSucess;
signal OnMessage(chatMessage: ChatMessage);
signal OnFailure(reason: String);

@export var CLIENT_ID = SETTINGS.CLIENT_ID;
@export var PORT = SETTINGS.PORT;
@export var SCOPE = 'moderator%3Amanage%3Abanned_users%20chat%3Aread%20chat%3Aedit%20channel%3Amanage%3Avips';

var TWITCH_CHAT_WS_URL = 'wss://irc-ws.chat.twitch.tv:443';
var RESPONSE_TYPE = 'token';
var REDIRECT_URL = 'http://localhost:' + str(PORT) + '/6bca6405-9bba-4b59-b1d2-7a3ef373e86f6bca6405-9bba-4b59-b1d2-7a3ef373e86f6bca6405-9bba-4b59-b1d2-7a3ef373e86f6bca6405-9bba-4b59-b1d2-7a3ef373e86f6bca6405-9bba-4b59-b1d2-7a3ef373e86f6bca6405-9bba-4b59-b1d2-7a3ef373e86f6bca6405-9bba-4b59-b1d2-7a3ef373e86f6bca6405-9bba-4b59-b1d2-7a3ef373e86f6bca6405-9bba-4b59-b1d2-7a3ef373e86f';
var URL = 'https://id.twitch.tv/oauth2/authorize?response_type=' + RESPONSE_TYPE + '&client_id=' + CLIENT_ID + '&redirect_uri=' + REDIRECT_URL + '&scope=' + SCOPE + '&state=c3ab8aa609ea11e793ae92361f002671'
var TWITCH_BAN_API_URL = 'https://api.twitch.tv/helix/moderation/bans';
var TWITCH_VALIDATION_URL = 'https://id.twitch.tv/oauth2/validate';
var TWITCH_VIP_URL = 'https://api.twitch.tv/helix/channels/vips';

@onready var authServer: Node = $AuthServer;

var _chatClient: WebSocketPeer;
var _hasConnected = false;
var _user: TwitchChannel;

func _process(delta: float):
	if !_chatClient:
		return;

	_chatClient.poll()
	var state = _chatClient.get_ready_state()
	match state:
		WebSocketPeer.STATE_OPEN:
			if (!_hasConnected):
				onChatConnected();
			while _chatClient.get_available_packet_count():
				onReceivedData(_chatClient.get_packet());
		WebSocketPeer.STATE_CLOSED:
			if _hasConnected:
				_hasConnected = false;
				var code = _chatClient.get_close_code()
				var reason = _chatClient.get_close_reason()
				print('Disconnected from twitch chat');
				print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
				print("Reconnecting");
				startChatClient();

func startChatClient():
	_chatClient = WebSocketPeer.new();
	_chatClient.connect_to_url(TWITCH_CHAT_WS_URL);

func onChatConnected():
	if !_user:
		return;
	# connected but not auth, does not confirm we can receive messages yet
	_hasConnected = true;
	_chatClient.send_text('CAP REQ :twitch.tv/membership twitch.tv/tags twitch.tv/commands');
	_chatClient.send_text('PASS oauth:' + _user.token);
	_chatClient.send_text('NICK ' + _user.login);
	_chatClient.send_text('JOIN ' + '#' + _user.login);
	OnSucess.emit();

func onReceivedData(payload: PackedByteArray):
	var message = payload.get_string_from_utf8();
	# parse irc message here;
	var data = {}
	var dataPairs = message.split(";");
	for pair in dataPairs:
		var d = pair.split("=");
		if d.size() == 2:
			data[d[0]]=d[1]

	var regex = RegEx.new()
	regex.compile("(?:(([a-zA-Z0-9_]*?)!([a-zA-Z0-9_]*?)@[a-zA-Z0-9_]*?.tmi.twitch.tv)|tmi.twitch.tv)\\s([A-Z]*?)?\\s#([^\\s]*)\\s{0,}:?(.*?)?$")
	var result = regex.search(message)
	if result:
		data["username"] = result.get_string(2)
		data["cmd"] = result.get_string(4)
		data["channel"] = result.get_string(5)
		data["msg"] = result.get_string(6).strip_edges(false);

	var msgStripped = message.strip_edges(false);
	if(msgStripped == 'PING :tmi.twitch.tv'):
		_chatClient.send_text("PONG");
		return;

	if (!data.has("cmd")):
		return

	if (data.cmd == "PRIVMSG"):
		var msgParsed = ChatMessage.new();
		msgParsed.cmd = data["cmd"];
		msgParsed.displayName = data["display-name"]
		msgParsed.userId = data["user-id"];
		msgParsed.color = data["color"];
		msgParsed.mod = data["mod"] == '1';
		msgParsed.id = data["id"];
		msgParsed.message = data["msg"];
		OnMessage.emit(msgParsed);

func timeoutUser(userToBanId: String, duration: int = 1, reason: String = ''):
	if !_user:
		return;

	var timeoutDuration = max(duration, 1);
	var url = TWITCH_BAN_API_URL + '?broadcaster_id=' +  _user.id + '&moderator_id=' + _user.id;
	var body = {
		data = {
			user_id = userToBanId,
			duration = timeoutDuration,
			reason = reason
		},
	};
	return await sendAPIRequest(url, HTTPClient.METHOD_POST, body);

func addVip(userId: String):
	if !_user:
		return;

	print('adding vip to user ', userId);
	var url = TWITCH_VIP_URL + '?broadcaster_id=' +  _user.id + '&user_id=' + userId;
	return await sendAPIRequest(url, HTTPClient.METHOD_POST);

func removeVip(userId: String):
	if !_user:
		return;

	print('removing vip to user ', userId);
	var url = TWITCH_VIP_URL + '?broadcaster_id=' +  _user.id + '&user_id=' + userId;
	return await sendAPIRequest(url, HTTPClient.METHOD_DELETE);

func sendAPIRequest(url: String, method: HTTPClient.Method,  body: Dictionary = {}):
	var client = HTTPRequest.new();
	var bodyEncoded = JSON.stringify(body);
	add_child(client);
	client.request(url, [
		'Client-Id: ' + CLIENT_ID,
		'Authorization: Bearer ' + _user.token,
		'Content-Type: application/json'
	], method, bodyEncoded);
	var result = await client.request_completed;
	var status = result[1];
	if status == 401 or status == 403:
		authenticate();
		return

	if status != 200:
		var data = (result[3] as PackedByteArray).get_string_from_utf8();
		print(data);
		return false;
	client.queue_free();
	return true;

## Authentication and Validation
func authenticate():
	authServer.stopServer();
	authServer.startServer();
	OS.shell_open(URL);

func _on_auth_server_on_token_received(token) -> void:
	authServer.stopServer();
	var validatedUser = await validateTokenAndGetUserId(token);
	if !(validatedUser):
		print('Invalid token');
		_user = null;
		return;
	_user = validatedUser;
	startChatClient();

func validateTokenAndGetUserId(token: String):
	var client = HTTPRequest.new();
	add_child(client);
	client.request(TWITCH_VALIDATION_URL, [
		'Authorization: OAuth ' + token
	]);
	var result = await client.request_completed;
	var status = result[1];
	if status != 200:
		return null;
	var data = (result[3] as PackedByteArray).get_string_from_utf8();
	var dataParsed = JSON.parse_string(data);
	var user = TwitchChannel.new();
	user.id = dataParsed['user_id'];
	user.login = dataParsed['login'];
	user.token = token;
	client.queue_free();
	return user;
