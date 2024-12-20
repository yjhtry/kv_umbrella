defmodule KVServer.KVServerTest do
  use ExUnit.Case

  setup do
    Application.stop(:kv)

    :ok = Application.start(:kv)
  end

  setup do
    {:ok, socket} =
      :gen_tcp.connect(~c"localhost", 4040, [:binary, packet: :line, active: false])

    %{socket: socket}
  end

  test "server interaction", %{socket: socket} do
    assert send_and_recv(socket, "UNKNOWN shopping\r\n") ==
             "UNKNOWN COMMAND\r\n"

    assert send_and_recv(socket, "GET shopping eggs\r\n") ==
             "NOT FOUND\r\n"

    assert send_and_recv(socket, "CREATE shopping\r\n") ==
             "OK\r\n"

    assert send_and_recv(socket, "PUT shopping eggs 3\r\n") ==
             "OK\r\n"

    # GET returns two lines
    assert send_and_recv(socket, "GET shopping eggs\r\n") == "3\r\n"
    assert send_and_recv(socket, "") == "OK\r\n"

    assert send_and_recv(socket, "DELETE shopping eggs\r\n") ==
             "OK\r\n"

    # GET returns two lines
    assert send_and_recv(socket, "GET shopping eggs\r\n") == "\r\n"
    assert send_and_recv(socket, "") == "OK\r\n"
  end

  defp send_and_recv(socket, data) do
    :ok = :gen_tcp.send(socket, data)
    {:ok, data} = :gen_tcp.recv(socket, 0, 1000)

    data
  end
end
