defmodule Chat.ProtocolTest do
  use ExUnit.Case, async: true

  alias Chat.Message.{Broadcast, Register}

  describe "decode_message/1" do
    test "can decode register messages" do
      binary = <<0x01, 0x00, 0x03, "meg", "rest">>

      assert {:ok, message, rest} = Chat.Protocol.decode_message(binary)

      assert %Register{username: "meg"} == message

      assert "rest" == rest
    end

    test "can decode broadcast messages" do
      binary = <<0x02, 3::16, "meg", 2::16, "hi", "rest">>

      assert {:ok, message, rest} = Chat.Protocol.decode_message(binary)

      assert %Broadcast{from_username: "meg", contents: "hi"} == message

      assert "rest" == rest
    end

    test "returns :incomplete when message is incomplete" do
      assert :incomplete == Chat.Protocol.decode_message(<<0x01, 0x00>>)
    end

    # test "returns :incomplete for empty data" do
    #   assert :incomplete == Chat.Protocol.decode_message("")
    # end

    test "returns :error for unknown message types" do
      assert :error == Chat.Protocol.decode_message(<<0x03, "rest">>)
    end
  end
end
