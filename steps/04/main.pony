use "collections"
use "net"

actor Main
  new create(env: Env) =>
    let host = try env.args(1)? else "" end
    let port = try env.args(2)? else "8989" end
    try
      TCPListener(env.root as AmbientAuth,
        recover ChatTCPListenNotify(ChatRoom) end, host, port)
    end

class ChatTCPListenNotify is TCPListenNotify
  let _chat_room: ChatRoom

  new create(chat_room: ChatRoom) =>
    _chat_room = chat_room

  fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ =>
    ChatTCPConnectionNotify(_chat_room)

  fun ref not_listening(listen: TCPListener ref) =>
    None

class ChatTCPConnectionNotify is TCPConnectionNotify
  let _chat_room: ChatRoom
  var _nick: (None | String) = None

  new iso create(chat_room: ChatRoom) =>
    _chat_room = chat_room

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] iso,
    times: USize)
    : Bool
  =>
    match _nick
    | None =>
      let nick: String val = String.from_iso_array(consume data).>strip()
      conn.write("hello, " + nick + "\n")
      _chat_room.add_connection(conn, nick)
      _nick = nick
    | let n: String =>
      let msg: String val = String.from_iso_array(consume data).>strip()
      _chat_room.send_msg(n, msg)
    end
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    None

actor ChatRoom
  let _conn_to_name: MapIs[TCPConnection, String] = _conn_to_name.create()

  be add_connection(conn: TCPConnection, nick: String) =>
    _conn_to_name(conn) = nick

  be send_msg(nick: String, msg: String) =>
    for (c, n) in _conn_to_name.pairs() do
      if nick != n then
        c.write(nick + ": " + msg + "\n")
      end
    end
